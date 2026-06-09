unit SGE.DataBase;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  sqlite3conn, sqldb;

const
  DEFAULT_DB_NAME  = 'database.sqlite3';

type
  TExecuteSciptResult = (
    esrSuccess,
    esrScriptNotFound,
    esrScriptError
  );

  PScriptError = ^TScriptError;
  TScriptError = record
    Command : string;
    Message: string;
  end;


  TransactionBehaviour = (
     bhCommit,
     bhRollback
  );


procedure SetDefaultConnection(AConnection: TSQLite3Connection);
function GetDefaultConnection: TSQLite3Connection;

function GetConnection(const ADatabaseName: string = DEFAULT_DB_NAME; ADefaultTransaction: boolean = true ): TSQLite3Connection;

(* Cria um banco de dados novo e retorna um objeto de conexão para ele *)
function CrateNewDataBase(const ADatabaseName: string) : TSQLite3Connection;
function GetQuery(const ASql: string; AAutoOpen: boolean = false; ATransaction: TSQLTransaction = nil) : TSQLQuery;
function ParseScript(const AScriptFileName: string): TStringList;

(* Funções gerenciamento de transçõs *)
function StartTransaction(AConnection: TSQLite3Connection; ABehaviour : TransactionBehaviour) : TSQLTransaction;

// Executes a SQL script file against the given connection.
// Function caller is responsible for free its mememory.
function ExecuteScipt(
  const AScriptFileName: string;
  const AConnection: TSQLite3Connection;
  out AError: TScriptError) : TExecuteSciptResult;



implementation

uses
  SysUtils;

var
  lConnection: TSQLite3Connection;

{ helper functions... }
procedure DeleteDatabaseFile(const ADatabaseName: string);
var
  ErrorCode: Integer;
begin
  if FileExists(ADatabaseName) then
  begin
    if not DeleteFile(ADatabaseName) then
    begin
      ErrorCode := GetLastOSError;

      raise Exception.CreateFmt(
        'Não foi possível apagar o arquivo "%s". Erro %d: %s',
        [ADatabaseName, ErrorCode, SysErrorMessage(ErrorCode)]
      );
    end;
  end;
end;

{implementations}

procedure SetDefaultConnection(AConnection: TSQLite3Connection);
begin
  if (lConnection <> nil) then
  begin
    lConnection.Close;
    lConnection.Free;
  end;
  lConnection := AConnection;
end;

function GetDefaultConnection: TSQLite3Connection;
begin
  Result := lConnection;
end;

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
    lConnection.Params.Add('foreign_keys=ON');
    lConnection.Open;
  end;
  Result := lConnection;
end;

function GetQuery(
  const ASql: string; AAutoOpen: boolean;
  ATransaction: TSQLTransaction) : TSQLQuery;
var
  cnn : TSQLite3Connection;
begin
  cnn := GetConnection;
  result := TSQLQuery.Create(cnn);
  result.SQLConnection := cnn;
  result.SQL.Add(ASql);
  result.PacketRecords:= -1;

  if ATransaction <> nil then
    Result.Transaction := ATransaction;

  if AAutoOpen then
    result.Open;
end;

function ExecuteScipt(
  const AScriptFileName: string;
  const AConnection: TSQLite3Connection;
  out AError: TScriptError): TExecuteSciptResult;
var
  i: integer;
  command: string;
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
      command:= commandList[i];
      AConnection.ExecuteDirect(command);
    end;
    transaction.Commit;
    Result := esrSuccess;
  except on e: Exception do
    begin
      transaction.Rollback;
      Result:= esrScriptError;
      AError.Command:= command;
      AError.Message:= e.Message ;
    end;
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
     DeleteDatabaseFile(ADatabaseName);

  Result := TSQLite3Connection.Create(nil);
  Result.DatabaseName:= ADatabaseName;
  Result.CreateDB;
  Result.Params.Add('foreign_keys=ON');
  Result.Open;

  Assert(Result.Connected);
end;

function StartTransaction(
  AConnection: TSQLite3Connection;
  ABehaviour : TransactionBehaviour) : TSQLTransaction;
begin
  Assert(AConnection <> nil);
  Assert(AConnection.Connected = True);

  Result := nil;
  if (AConnection.Transaction = nil) then
  begin
    AConnection.Transaction := TSQLTransaction.Create(AConnection);
  end else
  if (AConnection.Transaction <> nil) then
  begin
    case ABehaviour of
      bhCommit   : AConnection.Transaction.Commit;
      bhRollback : AConnection.Transaction.Rollback;
    end;
  end;

  AConnection.Transaction.StartTransaction;
  Result := AConnection.Transaction;
end;



initialization
  lConnection := nil;


end.





