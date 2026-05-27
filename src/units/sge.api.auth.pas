unit SGE.Api.Auth;

{$mode ObjFPC}{$H+}

interface

uses
  HTTPRoute, HTTPDefs, Classes, SysUtils;


const
   JTW_SECRET = 'voce-deve-trocar-este-secret-em-producao';


procedure Register;


implementation

uses
  fpjson,
  DateUtils, LazJWT,

  SGE.Api;
  //jsonparser;


function GetJwt(const AUser:string): string;
var
  exp: Int64;
  tokenId : TGuid;

begin
  exp := DateTimeToUnix(IncHour(Now));
  CreateGUID(tokenId);

   Result := TLazJWT.New
               .SecretJWT(JTW_SECRET)
               .Iss('sge.server')       //Issuer
               .Sub(AUser)              // subject
               .Aud('sge server api')
               .Exp(exp)
               .Iat(DateTimeToUnix(now))
               .JTI(GUIDToString(tokenId))               // jwt id
               {.AddClaim('Validated', True)
               .AddClaim('Name', 'Andre')
               .AddClaim('Level', 10)
               .AddClaim('Limit', 100.00)}
               .Token;
end;





// { user : "" , pwd : "" }
procedure PostLogin(ARequest: TRequest; AResponse: TResponse);
var
  usr, pwd : string;
  payload: TJSONData;
begin
  WriteLn(' > ', ARequest.Method, ' ', ARequest.URI);

  if (ARequest.ContentType <> 'application/json') then
      SendBadRequest(AResponse)
  else
  if ARequest.ContentLength = 0 then
     SendBadRequest(AResponse, 'Content cannot be empty');

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

  // todo: valiar usuário e senha no banco de dados
  if (usr <> pwd) then
  begin
    SendText(AResponse, 401, 'Unauthorized');
    Exit;
  end;

  SendText(AResponse, 200, GetJwt(usr));
end;


procedure Register;
begin
  ApiServer.RegisterPublicRoute('/auth/login', rmPost,   @PostLogin);

  WriteLn('    - [ok] SGE.Api.Auth' );
end;

end.

