unit udb;

{$mode ObjFPC}{$H+}

interface

uses
  sqlite3conn;

function GetConnection(
  const ADatabaseName: string;
  ADefaultTransaction: boolean = true ): TSQLite3Connection;


implementation


function GetConnection(
  const ADatabaseName: string;
  ADefaultTransaction: boolean = true ): TSQLite3Connection;
begin
  Result := TSQLite3Connection.Create(nil);
  Result.DatabaseName:= ADatabaseName;
  if ADefaultTransaction then
    Result.Transaction := TSQLTransaction.Create(Result);
end;

end.

