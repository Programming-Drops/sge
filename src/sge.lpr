program sge;

{$mode objfpc}{$H+}
{$codepage utf8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes,
  sqldb,
  sqlite3conn,
  SysUtils,

  SGE.Database,
  SGE.Log,
  SGE.Models.Cargo, SGE.Models.Usuario;


procedure InsertTestLogs(conexao : TSQLite3Connection);
const
  LOG_COUNT = 50 * 1000;
var
  i : integer;
  x : real;
  t : TSQLTransaction;
begin
  WriteLn('Inserindo ', LOG_COUNT,' logs...');
  LogInfo('Log de teste');
  LogError('Erro fake');

  t :=  StartTransaction(conexao, bhRollback);
  for i:= 1 to LOG_COUNT do
  begin
    LogInfo(t, 'Log de teste ' + Inttostr(i));
    if i mod 50 = 0 then
    begin
      x := (i / LOG_COUNT) * 100;
      WriteLn(x:5:2, '% concluído.');
    end;
  end;
  t.Commit;

  WriteLn('100% concluído.');
end;


var
  conexao : TSQLite3Connection;
  error    : TScriptError;
begin
  conexao := CrateNewDataBase('teste-log.db');
  SetDefaultConnection(conexao);

  if (ExecuteScipt('..\db\estrutura incial.sql', conexao, error) = esrScriptError) then
  begin
    WriteLn('Erro ao exectuar o script');
    WriteLn('Comando:', error.Command);
    WriteLn('Erro   :', error.Message);
    Halt(1);
  end;

  //InsertCargos;
  InsertTestLogs(conexao);
end.

