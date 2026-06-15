unit SGE.Api.Cargos;

{$mode ObjFPC}{$H+}

interface

uses
  SGE.Api,
  HTTPRoute, HTTPDefs, Classes, SysUtils;


procedure Register;


implementation

uses
  fpjson,
  sqlite3conn,SQLDB,
  SGE.Models.Cargo;



procedure GetCargoList(ARequest: TRequest; AResponse: TResponse);
var
  i : integer;
  cargos: TCargoArray;
  jsonArray : TJSONArray;
  jsonObj   : TJSONObject;
begin
  WriteLn(' > ', ARequest.Method, ' ', ARequest.URI);

  cargos := CargoLoad;
  jsonArray := TJSONArray.Create;
  try
    for i := Low(cargos) to High(Cargos) do
    begin
      jsonObj := TJSONObject.Create;
      jsonObj.Add('id', cargos[i].Id);
      jsonObj.Add('nome', cargos[i].Nome);
      jsonArray.Add(jsonObj);
    end;
    AResponse.Code:= 200;
    AResponse.Content:= jsonArray.AsJSON;
    AResponse.ContentType:= 'application/json' ;
    AResponse.SendContent;
  finally
    jsonArray.Free;
  end;
end;

procedure DeleteCargo(ARequest: TRequest; AResponse: TResponse);
var
  id : integer;
begin
  WriteLn(' > ', ARequest.Method, ' ', ARequest.URI);

  id := StrToInt(ARequest.RouteParams['id']);
  try
    if CargoDelete(id) then
      SendOk(AResponse)
    else
      SendInternalServerError(AResponse);
  except
     on e:ESQLDatabaseError do begin
       if Pos('FOREIGN KEY constraint failed', e.Message) >= 0 then
       begin
         SendConfict(AResponse);
       end;
       raise;
     end;
     on e: Exception do begin
       WriteLn('ERR: DeleteCargo : ', e.Message);
       SendInternalServerError(AResponse);
     end;
  end;
end;

procedure UpdateCargo(ARequest: TRequest; AResponse: TResponse);
var
  payload: TJSONData;
  id     : integer;
  nome   : string;
  validation : TRequestValidadorResult;
begin
  WriteLn(' > ', ARequest.Method, ' ', ARequest.URI);

  validation := TRequestValidador.RequiredJson(ARequest);
  case validation.Code of
    rvJsonMimeTypeRequired: SendBadRequest(AResponse, validation.Message);
    rvJsonEmptyBody       : SendBadRequest(AResponse, validation.Message);
  end;

  if validation.Code = rvOk then
  begin
    payload := GetJSON(ARequest.Content);
    if (TJSONObject(payload).Find('nome') = nil) then
    begin
      SendBadRequest(AResponse, 'The "nome" property was not found on payload ');
      Exit;
    end;

    id := StrToInt(ARequest.RouteParams['id']);
    nome := TJSONObject(payload).Get('nome');

    if CargoUpdate(id, nome) then
      SendOk(AResponse, 'Cargo updated')
    else
      SendInternalServerError(AResponse);
  end;
end;

procedure PostCargo(ARequest: TRequest; AResponse: TResponse);
var
  payload: TJSONData;
  nome, location: string;
  p : PCargo;
  validation : TRequestValidadorResult;
begin
  WriteLn(' > ', ARequest.Method, ' ', ARequest.URI);

  validation := TRequestValidador.RequiredJson(ARequest);
  case validation.Code of
    rvJsonMimeTypeRequired: SendBadRequest(AResponse, validation.Message);
    rvJsonEmptyBody       : SendBadRequest(AResponse, validation.Message);
  end;
  if validation.Code = rvOk then
  begin
    payload := GetJSON(ARequest.Content);
    if (TJSONObject(payload).Find('nome') = nil) then
    begin
      SendBadRequest(AResponse, 'The "nome" property was not found on payload ');
      Exit;
     end;

    nome := TJSONObject(payload).Get('nome');
    try
      p := CargoInsert(nome);
      if p=nil then
        SendBadRequest(AResponse, 'Could not create the new "cargo"')
      else
      begin
        location := Format('/cargo/%d', [p^.Id]);
        SendCreated(AResponse, location, location);
       end;
     finally
       Dispose(p);
     end;
  end;
end;

procedure GetCargo(ARequest: TRequest; AResponse: TResponse);
var
  id: integer;
  p : PCargo;
  json : TJSONObject;
begin
  WriteLn(' > ', ARequest.Method, ' ', ARequest.URI);
  if ARequest.RouteParams['id'] = '' then
  begin
    SendNotFound(AResponse);
    Exit;
  end;

  if not TryStrToInt(ARequest.RouteParams['id'], id) then
  begin
    SendNotFound(AResponse);
    Exit;
  end;

  p := CargoLoadById(id);
  if p = nil then
    SendNotFound(AResponse)
  else begin
    json := TJSONObject.Create;
    try
      json.Add('id',   p^.Id);
      json.Add('nome', p^.Nome);
      SendOk(AResponse, json.AsJSON, true);
    finally
      json.Free;
    end;
  end;
end;


procedure Register;
begin
  ApiServer.ProtectedRoute('/cargo',       rmPost,   @PostCargo);
  ApiServer.ProtectedRoute('/cargo/:id',   rmGet,    @GetCargo);
  ApiServer.ProtectedRoute('/cargo/:id/',  rmPost,   @UpdateCargo);
  ApiServer.ProtectedRoute('/cargo/:id/',  rmDelete, @DeleteCargo);
  ApiServer.ProtectedRoute('/cargos',      rmGet,    @GetCargoList);

  WriteLn('    - [ok] SGE.Api.Cargos' );
end;



end.

