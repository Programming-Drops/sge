unit SGE.Api.DataBase;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

const
  SERVER_DB = 'sge.db';

procedure InitializeDatabase;

implementation


uses
  sqlite3conn, SQLDB,
  SGE.DataBase;

procedure InitializeDatabase;
var
  conexao : TSQLite3Connection;
  error   : TScriptError;
begin
   WriteLn('Initializing database...');

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

end.

