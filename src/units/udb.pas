unit udb;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  sqlite3conn, sqldb;

const
  DEFAULT_DB_NAME  = 'database.sqlite3';

type
  TExecuteSciptResult = (
    esrScriptNotFound
  );



function GetConnection(
  const ADatabaseName: string = DEFAULT_DB_NAME;
  ADefaultTransaction: boolean = true ): TSQLite3Connection;

(* Cria um banco de dados novo e retorna um objeto de conexão para ele *)
function CrateNewDataBase(const ADatabaseName: string) : TSQLite3Connection;

function GetQuery(const ASql: string) : TSQLQuery;

function ParseScript(const AScriptFileName: string): TStringList;
function ExecuteScipt(
  const AScriptFileName: string;
  const AConnection: TSQLite3Connection) : TExecuteSciptResult;



implementation

uses
  SysUtils;

var
  lConnection: TSQLite3Connection;


function GetConnection(
  const ADatabaseName: string;
  ADefaultTransaction: boolean = true ): TSQLite3Connection;
begin
  Result := nil;
  if lConnection = nil then
  begin
    lConnection := TSQLite3Connection.Create(nil);
    lConnection.DatabaseName:= ADatabaseName;
    if ADefaultTransaction then
       lConnection.Transaction := TSQLTransaction.Create(Result);
    lConnection.Open;
  end;
  Result := lConnection;
end;

function GetQuery(const ASql: string) : TSQLQuery;
var
  cnn : TSQLite3Connection;
begin
  cnn := GetConnection;
  result := TSQLQuery.Create(cnn);
  result.SQLConnection := cnn;
  result.SQL.Add(ASql);
end;


function ExecuteScipt(
  const AScriptFileName: string;
  const AConnection: TSQLite3Connection) : TExecuteSciptResult;
var
  i: integer;
  commandList: TStringList;
  transaction: TSQLTransaction;
begin
  Assert(AConnection <> nil);

  if not(FileExists(AScriptFileName)) then
     Exit(esrScriptNotFound);

  commandList := nil;
  commandList := ParseScript( AScriptFileName );
  transaction := TSQLTransaction.Create( AConnection );
  AConnection.Transaction := transaction;
  transaction.StartTransaction;
  try
    for i:= 0 to commandList.Count - 1 do
    begin
      AConnection.ExecuteDirect(commandList[i]);
    end;
    transaction.Commit;
  except
    transaction.Rollback;
  end;
end;

function ParseScript(const AScriptFileName: string): TStringList;
var
  buffer, command: string;
  scriptFile : TextFile;
begin
  Result := TStringList.Create;

  AssignFile(scriptFile, AScriptFileName);
  Reset(scriptFile);
  while not EOF(scriptFile) do
  begin
     ReadLn(scriptFile, buffer);
     command := command + buffer;
     if Pos(';', buffer) > 0 then
     begin
       Result.Add(command);
       command := '';
     end;
  end;
  Close(scriptFile);
end;



function CrateNewDataBase(const ADatabaseName: string) : TSQLite3Connection;
begin
  if FileExists(ADatabaseName) then
     DeleteFile(ADatabaseName);

  Result := TSQLite3Connection.Create(nil);
  Result.DatabaseName:= ADatabaseName;
  Result.CreateDB;
  Result.Open;

  Assert(Result.Connected);
end;

end.




