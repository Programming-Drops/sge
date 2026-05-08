program sge.server;


uses
  fpjson, jsonparser,
  fphttpapp, HTTPRoute, HTTPDefs,
  sqlite3conn, SQLDB,
  SysUtils,

  SGE.DataBase,
  SGE.Models.Cargo;

const
  SERVER_DB = 'sge.db';


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

procedure GetHealth(ARequest: TRequest; AResponse: TResponse);
begin
  AResponse.Content := 'Healty';
  AResponse.SendContent;
end;



procedure InitializeDatabase;
var
  conexao : TSQLite3Connection;
  error    : TScriptError;
begin
  WriteLn('Initializind database...');

  if FileExists(SERVER_DB) then
  begin
    conexao := GetConnection(SERVER_DB);
    //SetDefaultConnection(conexao);
  end
  else begin
    conexao := CrateNewDataBase(SERVER_DB);
    SetDefaultConnection(conexao);
    if (ExecuteScipt('..\db\estrutura incial.sql', conexao, error) = esrScriptError) then
    begin
      WriteLn('Erro ao exectuar o script');
      WriteLn('Comando:', error.Command);
      WriteLn('Erro   :', error.Message);
      Halt(1);
    end;
  end;

  WriteLn(' -> Database found (', SERVER_DB,')');
end;

begin
  WriteLn('SGE server.');
  InitializeDatabase;

  WriteLn(' -> Setting up server...');
  Application.Port := 8085;
  Application.Threaded:= True;

  HTTPRouter.RegisterRoute('/health', rmGet, @GetHealth);


  HTTPRouter.RegisterRoute('/cargo', rmPost, @PostCargo);
  HTTPRouter.RegisterRoute('/cargo/:id', rmGet, @GetCargo);


  Application.Initialize;
  WriteLn(' -> Server is running on localhost:', Application.Port);
  Application.Run;
end.

