program sge.server;


uses
  fpjson, jsonparser,
  fphttpapp, HTTPRoute, HTTPDefs,
  sqlite3conn, SQLDB,
  SysUtils, DateUtils,
  LazJWT,
  SGE.DataBase,
  SGE.Models.Cargo;

const
  SERVER_DB = 'sge.db';
  JTW_SECRET = 'voce-deve-trocar-este-secret-em-producao';


type

  { TApiApplication }

  TApiApplication = class(THTTPApplication)
  end;



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
    if (TJSONObject(payload).Find('usr') = nil) then
    begin
      AResponse.Code     := 400;
      AResponse.Content  := 'The "nome" property was not found on payload ';
      AResponse.SendContent;
      Exit;
    end;

    if (TJSONObject(payload).Find('pwd') = nil) then
    begin
      AResponse.Code     := 400;
      AResponse.Content  := 'The "pwd" property was not found on payload ';
      AResponse.SendContent;
      Exit;
    end;

    usr := TJSONObject(payload).Get('usr');
    pwd := TJSONObject(payload).Get('pwd');

    // todo: valiar usuário e senha no banco de dados
    if (usr <> pwd) then
    begin
      AResponse.Code     := 401;
      AResponse.Content  := 'Unauthorized';
      AResponse.SendContent;
      Exit;
    end;


    AResponse.Code:= 200;
    AResponse.Content:=  GetJwt(usr);
    AResponse.SendContent;
end;

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

procedure GetHealth(ARequest: TRequest; AResponse: TResponse);
begin
  AResponse.Code      := 200;
  AResponse.Content   := 'Healty';
  AResponse.SendContent;
end;


procedure InitializeDatabase;
var
  conexao : TSQLite3Connection;
  error   : TScriptError;
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


var
  ApiServer : TApiApplication;

begin
  WriteLn('SGE server.');
  InitializeDatabase;

  WriteLn(' -> Setting up server...');

  ApiServer := TApiApplication.Create(nil);
  ApiServer.Port := 8085;
  ApiServer.Threaded:= False;

  { public }
  HTTPRouter.RegisterRoute('/health', rmGet, @GetHealth);


  HTTPRouter.RegisterRoute('/auth/login', rmPost,   @PostLogin);

  { auth }
  HTTPRouter.RegisterRoute('/cargo',       rmPost,   @PostCargo);
  HTTPRouter.RegisterRoute('/cargo/:id',   rmGet,    @GetCargo);
  HTTPRouter.RegisterRoute('/cargo/:id/',  rmPost,   @UpdateCargo);
  HTTPRouter.RegisterRoute('/cargo/:id/',  rmDelete, @DeleteCargo);
  HTTPRouter.RegisterRoute('/cargos',      rmGet,    @GetCargoList);


  ApiServer.Initialize;
  WriteLn(' -> Server is running on localhost:', ApiServer.Port);
  try
    ApiServer.Run;
  except
     on e:Exception do
     begin
        WriteLn('Houve um erro ao processar a requisição');
        WriteLn(e.Message);
     end;
  end;
end.

