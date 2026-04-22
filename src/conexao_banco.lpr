program conexao_banco;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes,
  sqldb,
  sqlite3conn,
  SysUtils,

  uCargos, uDb;


var
 id : integer;
 conexao : TSQLite3Connection;
 cargo   : PCargo;
 error   : TScriptError;
begin

  conexao := CrateNewDataBase('teste.db');
  if (ExecuteScipt('..\db\estrutura incial.sql', conexao, error) = esrScriptError) then
  begin
    WriteLn('Erro ao exectuar o script');
    WriteLn('Comando:', error.Command);
    WriteLn('Erro   :', error.Message);

  end;

end.

