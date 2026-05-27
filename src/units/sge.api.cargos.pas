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
      AResponse.Code:= 200
    else begin
      AResponse.Code:= 500;
      AResponse.Content:= 'Internal server error';
    end;
    AResponse.SendContent;
  except
     on e:ESQLDatabaseError do begin
       if Pos('FOREIGN KEY constraint failed', e.Message) >= 0 then
       begin
         AResponse.Code:= 409;
         AResponse.Content:= 'Conflict';
         AResponse.SendContent;
       end;
       raise;
     end;
     on e: Exception do begin
       WriteLn('ERR: DeleteCargo : ', e.Message);
       AResponse.Code:= 500;
       AResponse.Content:= 'Internal server error';
       AResponse.SendContent;
     end;
  end;
end;

procedure UpdateCargo(ARequest: TRequest; AResponse: TResponse);
var
  payload: TJSONData;
  id     : integer;
  json   : TJSONObject;
  nome   : string;
begin
  WriteLn(' > ', ARequest.Method, ' ', ARequest.URI);

  if (ARequest.ContentType <> 'application/json') then
   begin
     AResponse.Code       := 400;
     AResponse.SendContent;
     Exit;
   end;

  if ARequest.ContentLength = 0 then
     begin
     AResponse.Code     := 400;
     AResponse.Content  := 'Content cannot be empty';
     AResponse.SendContent;
     Exit;
   end;

   payload := GetJSON(ARequest.Content);
   if (TJSONObject(payload).Find('nome') = nil) then
   begin
     AResponse.Code     := 400;
     AResponse.Content  := 'The "nome" property was not found on payload ';
     AResponse.SendContent;
     Exit;
   end;

   id := StrToInt(ARequest.RouteParams['id']);
   nome := TJSONObject(payload).Get('nome');

   if CargoUpdate(id, nome) then
   begin
     AResponse.Code:= 200;
     AResponse.Content:= 'Cargo updated';
   end else
   begin
     AResponse.Code:= 500;
     AResponse.Content:= 'Internal server error';
   end;
   AResponse.SendContent;
end;

procedure PostCargo(ARequest: TRequest; AResponse: TResponse);
var
  payload: TJSONData;
  json   : TJSONObject;
  nome: string;
  p : PCargo;
begin
  WriteLn(' > ', ARequest.Method, ' ', ARequest.URI);

  if (ARequest.ContentType <> 'application/json') then
   begin
     AResponse.Code       := 400;
     AResponse.SendContent;
     Exit;
   end;

  if ARequest.ContentLength = 0 then
     begin
     AResponse.Code     := 400;
     AResponse.Content  := 'Content cannot be empty';
     AResponse.SendContent;
     Exit;
   end;

   payload := GetJSON(ARequest.Content);
   if (TJSONObject(payload).Find('nome') = nil) then
   begin
     AResponse.Code     := 400;
     AResponse.Content  := 'The "name" property was not found on payload ';
     AResponse.SendContent;
     Exit;
   end;

   nome := TJSONObject(payload).Get('nome');
   try
     p := CargoInsert(nome);
     if p=nil then
     begin
       AResponse.Code     := 500;
       AResponse.Content  := 'Could not create the new "cargo"';
       AResponse.SendContent;
       Exit;
     end;

    AResponse.Code:= 201;
    AResponse.SetCustomHeader('Location', Format('/cargo/%d', [p^.Id]));
    AResponse.Content := Format('/cargo/%d', [p^.Id]);
   finally
     Dispose(p);
   end;

  AResponse.SendContent;
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
    AResponse.Code     := 404;
    AResponse.SendContent;
    Exit;
  end;

  if not TryStrToInt(ARequest.RouteParams['id'], id) then
  begin
    AResponse.Code     := 404;
    AResponse.SendContent;
    Exit;
  end;

  p := CargoLoadById(id);
  if p = nil then
  begin
     AResponse.Code     := 404;
     AResponse.SendContent;
     Exit;
  end;

  json := TJSONObject.Create;
  try

    json.Add('id',   p^.Id);
    json.Add('nome', p^.Nome);

    AResponse.Code:= 200;
    AResponse.ContentType:= 'application/json';
    AResponse.Content := json.AsJSON;
    AResponse.SendContent;
  finally
    json.Free;
  end;
end;


procedure Register;
begin
  ApiServer.RegisterPublicRoute('/cargo',       rmPost,   @PostCargo);
  ApiServer.RegisterPublicRoute('/cargo/:id',   rmGet,    @GetCargo);
  ApiServer.RegisterPublicRoute('/cargo/:id/',  rmPost,   @UpdateCargo);
  ApiServer.RegisterPublicRoute('/cargo/:id/',  rmDelete, @DeleteCargo);
  ApiServer.RegisterPublicRoute('/cargos',      rmGet,    @GetCargoList);

  WriteLn('    - [ok] SGE.Api.Cargos' );
end;



end.

