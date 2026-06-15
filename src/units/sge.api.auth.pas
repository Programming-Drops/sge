unit SGE.Api.Auth;

{$mode ObjFPC}{$H+}

interface

uses
  HTTPRoute, HTTPDefs, Classes, SysUtils;


const
   JWT_SECRET = 'voce-deve-trocar-este-secret-em-producao';
   JWT_ISSUER = 'sge.server';
   JWT_AUDIENCE = 'sge server api';
   JWT_EXPIRES_IN_SECONDS = 3600;


procedure Register;
function ValidateBearerToken(ARequest: TRequest; out ASubject: string): boolean;


implementation

uses
  fpjson, jsonparser,
  DateUtils, LazJWT, StrUtils,
  SGE.Api,
  SGE.Models.Usuario;



function GetJwt(const AUser:string): string;
var
  exp: Int64;
  tokenId : TGuid;

begin
  exp := DateTimeToUnix(IncSecond(Now, JWT_EXPIRES_IN_SECONDS), False);
  CreateGUID(tokenId);

  Result := TLazJWT.New
               .SecretJWT(JWT_SECRET)
               .Alg('HS256')
               .Iss(JWT_ISSUER)         //Issuer
               .Sub(AUser)              // subject
               .Aud(JWT_AUDIENCE)
               .Exp(exp)
               .Iat(DateTimeToUnix(Now, False))
               .JTI(GUIDToString(tokenId))               // jwt id
               {.AddClaim('Validated', True)
               .AddClaim('Name', 'Andre')
               .AddClaim('Level', 10)
               .AddClaim('Limit', 100.00)}
               .Token;
end;

function ValidateJwt(const AToken: string; out ASubject: string): boolean;
var
  jwt: ILazJWT;
begin
  Result := false;
  ASubject := '';
  try
    jwt := TLazJWT
      .New(TLazJWTConfig
        .New
        .IsRequiredSubject(True)
        .IsRequiredIssuedAt(True)
        .IsRequiredExpirationTime(True)
        .IsRequireAudience(True)
        .ExpectedAudience([JWT_AUDIENCE]))
      .UseCustomPayLoad(False)
      .Token(AToken)
      .SecretJWT(JWT_SECRET);

    jwt.ValidateToken;

    if not SameText(jwt.Alg, 'HS256') then
      Exit;

    if jwt.Iss <> JWT_ISSUER then
      Exit;

    if jwt.Sub = '' then
      Exit;

    ASubject := jwt.Sub;
    Result := true;
  except
    on e: Exception do
      WriteLn('ERR: ValidateJwt: ', e.Message);
  end;
end;

function ValidateBearerToken(ARequest: TRequest; out ASubject: string): boolean;
const
  BEARER_PREFIX = 'Bearer ';
var
  authorization, token: string;
begin
  Result := false;
  ASubject := '';

  authorization := Trim(ARequest.Authorization);
  if authorization = '' then
  begin
    WriteLn('ERR: Missing Authorization header');
    Exit;
  end;

  if not AnsiStartsText(BEARER_PREFIX, authorization) then
  begin
    WriteLn('ERR: Invalid Authorization scheme');
    Exit;
  end;

  token := Trim(Copy(authorization, Length(BEARER_PREFIX) + 1, MaxInt));
  if token = '' then
  begin
    WriteLn('ERR: Empty bearer token');
    Exit;
  end;

  Result := ValidateJwt(token, ASubject);
end;



// { user : "" , pwd : "" }
procedure PostLogin(ARequest: TRequest; AResponse: TResponse);
var
  usr, pwd : string;
  payload: TJSONData;
  responseJson: TJSONObject;
  token: string;
begin
  WriteLn(' > ', ARequest.Method, ' ', ARequest.URI);

  if (ARequest.ContentType <> 'application/json') then
  begin
    SendBadRequest(AResponse);
    Exit;
  end
  else
  if ARequest.ContentLength = 0 then
  begin
     SendBadRequest(AResponse, 'Content cannot be empty');
     Exit;
  end;

  // { usr: '', pwd: ''  }
  payload := GetJSON(ARequest.Content);
  if (TJSONObject(payload).Find('usr') = nil) then
  begin
    SendBadRequest(AResponse, 'The "nome" property was not found on payload ');
    Exit;
  end;

  if (TJSONObject(payload).Find('pwd') = nil) then
  begin
    SendBadRequest(AResponse, 'The "pwd" property was not found on payload ');
    Exit;
  end;

  usr := TJSONObject(payload).Get('usr');
  pwd := TJSONObject(payload).Get('pwd');

  if not UsuarioAuthenticate(usr, pwd) then
  begin
    SendText(AResponse, 401, 'Unauthorized');
    Exit;
  end;

  token := GetJwt(usr);
  responseJson := TJSONObject.Create;
  try
    responseJson.Add('access_token', token);
    responseJson.Add('token_type', 'Bearer');
    responseJson.Add('expires_in', JWT_EXPIRES_IN_SECONDS);
    SendJson(AResponse, 200, responseJson.AsJSON);
  finally
    responseJson.Free;
  end;
end;


procedure Register;
begin
  BearerTokenValidator := @ValidateBearerToken;
  ApiServer.PublicRoute('/auth/login', rmPost,   @PostLogin);

  WriteLn('    - [ok] SGE.Api.Auth' );
end;

end.

