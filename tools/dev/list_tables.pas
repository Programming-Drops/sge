program sqlite_list_tables;

uses
  Classes, SQLDB, SysUtils, SQLite3Conn;

const
  TAB = #9;
  ARROW = '→ ';

procedure ListAllTables(const ADatabase: string);
var
  table: string;
  tableNames: TStringList;
  connection: TSQLite3Connection;
  transaction: TSQLTransaction;
begin
  connection  := TSQLite3Connection.Create(nil);
  transaction := TSQLTransaction.Create(nil);
  tableNames  := TStringList.Create;
  try
    connection.DatabaseName := ADatabase;
    connection.Transaction := transaction;
    transaction.DataBase := connection;

    connection.Open;

    if connection.Connected then
      WriteLn('Conectado no banco ' + connection.DatabaseName);

    connection.GetTableNames(tableNames);
    if tableNames.Count  = 0 then
      WriteLn('Nenhuma tabela encontrada no banco de dados ' + ADatabase)
    else
      begin
        WriteLn(IntToStr(tableNames.Count) + ' tabelas encontradas: ');
        for table in tableNames do
          WriteLn(ARROW + table);
      end;
  finally
    tableNames.Free;
    connection.Free;
    transaction.Free;
  end;
end;

begin
  ListAllTables('ecommerce.sqlite3' );
end.

