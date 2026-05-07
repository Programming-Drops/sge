unit SGE.Log;

{$mode ObjFPC}{$H+}

interface

uses
  SQLDB;

type

  TLogType = (
    ltError        = 'E',
    ltInformation  = 'I'
  );

  TLogEntry = record
    Id   : Int64;
    Data : TDateTime;
    Tipo : TLogType;
    Text : string;
  end;


  //Fire nad forget -> un único uso isolado
  //--------------------------------------------------------
  function Log(ATipo: TLogType; const AText: string) : Int64;
  function LogInfo(const AText: string): Int64;
  function LogError(const AText: string): Int64;

  // batch version
  //--------------------------------------------------------

  function Log(ATransaction: TSQLTransaction; ATipo: TLogType; const AText: string) : Int64;
  function LogInfo(ATransaction: TSQLTransaction; const AText: string): Int64;
  function LogError(ATransaction: TSQLTransaction; const AText: string): Int64;




implementation

uses
  udb, sqlite3conn, SysUtils;

function Log(ATipo: TLogType; const AText: string) : Int64;
const
  SQL_INSERT = 'insert into log(tipo, text) values (:tipo, :text)';
var
  Query: TSQLQuery;
  cnn  : TSQLite3Connection;
  sql:  string;
begin
  try
     Query := GetQuery(SQL_INSERT);
     Query.Params.ParamByName('tipo').AsString := Char(ATipo);
     Query.Params.ParamByName('text').AsString := AText;
     Query.ExecSQL;
     Query.SQLConnection.Transaction.Commit;
     Result := TSQLite3Connection(query.SQLConnection).GetInsertID;
  finally
    Query.Free;
  end;
end;

function LogInfo(const AText: string): Int64;
begin
  Result := Log(ltInformation, AText);
end;

function LogError(const AText: string): Int64;
begin
  Result := Log(ltError, AText);
end;


function Log(ATransaction: TSQLTransaction; ATipo: TLogType; const AText: string) : Int64;
const
  SQL_INSERT = 'insert into log(tipo, text) values (:tipo, :text)';
var
  Query: TSQLQuery;
begin
  try
     Query := GetQuery(SQL_INSERT, false, ATransaction);
     Query.Params.ParamByName('tipo').AsString := Char(ATipo);
     Query.Params.ParamByName('text').AsString := AText;
     Query.ExecSQL;
     Result := TSQLite3Connection(query.SQLConnection).GetInsertID;
  finally
    Query.Free;
  end;
end;

function LogInfo(ATransaction: TSQLTransaction; const AText: string): Int64;
begin
  Result := Log(ATransaction, ltInformation, AText);
end;

function LogError(ATransaction: TSQLTransaction; const AText: string): Int64;
begin
  Result := Log(ATransaction, ltError, AText);
end;

end.

