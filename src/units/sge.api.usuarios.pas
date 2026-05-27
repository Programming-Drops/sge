unit SGE.Api.Usuarios;

{$mode ObjFPC}{$H+}

interface

uses
  SGE.Api,
  HTTPRoute, HTTPDefs;

procedure Register;


implementation



uses
  fpjson,
  sqlite3conn,SQLDB,
  Classes, SysUtils,
  SGE.Models.Usuario;



// { user:  string ,  pwd: string }
procedure PostUsuario(ARequest: TRequest; AResponse: TResponse);
var
  payload: TJSONData;
  usr, pwd, location: string;
  p : PUsuario;
begin
  WriteLn(' > ', ARequest.Method, ' ', ARequest.URI);

  if (ARequest.ContentType <> 'application/json') then
   begin
     SendBadRequest(AResponse);
     Exit;
   end;

  if ARequest.ContentLength = 0 then
  begin
    SendBadRequest(AResponse, 'Content cannot be empty');
    Exit;
  end;

  payload := GetJSON(ARequest.Content);
  if (TJSONObject(payload).Find('user') = nil) then
  begin
    SendBadRequest(AResponse, 'The "user" property was not found on payload');
    Exit;
   end;

  if (TJSONObject(payload).Find('pwd') = nil) then
  begin
    SendBadRequest(AResponse, 'The "pwd" property was not found on payload ');
    Exit;
   end;

  usr := TJSONObject(payload).Get('user');
  pwd := TJSONObject(payload).Get('pwd');

  if (Length(pwd) < 6) then
  begin
    SendBadRequest(AResponse, 'The password must have at least 6 characters');
    Exit;
  end;

  try
    try
       p := UsuarioInsert(usr, pwd);
       if p=nil then
         SendBadRequest(AResponse, 'Could not create the new "user')
      else
      begin
        location:=  Format('/usuario/%d', [p^.Id]);
        SendCreated(AResponse, location, location);
       end;
    except on e:EUserAlreadyExists do
      SendConfict(AResponse, e.Message);
    end;
   finally
     if Assigned(p) then
        Dispose(p);
   end;
end;


procedure Register;
begin
  ApiServer.RegisterPublicRoute('/usuario', rmPost, @PostUsuario);

  WriteLn('    - [ok] SGE.Api.Usuarios' );
end;

end.

