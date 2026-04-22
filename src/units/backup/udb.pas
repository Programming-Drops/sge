unit udb;

{$mode ObjFPC}{$H+}

interface

uses
  sqlite3conn, sqldb;

const
  DEFAULT_DB_NAME  = 'database.sqlite3';


function GetConnection(
  const ADatabaseName: string = DEFAULT_DB_NAME;
  ADefaultTransaction: boolean = true ): TSQLite3Connection;


function GetQuery(const ASql: string) : TSQLQuery;


implementation

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

end.

