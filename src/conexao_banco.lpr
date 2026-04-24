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

  uCargos, uDb, uFuncionario, uConstantes;


var
 id : integer;
 conexao : TSQLite3Connection;
 cargo   : PCargo;
 error   : TScriptError;
 funcionario : PFuncionario;
begin

  conexao := CrateNewDataBase('teste.db');
  if (ExecuteScipt('..\db\estrutura incial.sql', conexao, error) = esrScriptError) then
  begin
    WriteLn('Erro ao exectuar o script');
    WriteLn('Comando:', error.Command);
    WriteLn('Erro   :', error.Message);
    Halt(1);
  end;

  funcionario:= FuncionarioInsert('Fabiano Xavier', 1, NULL_ID, true);
  if (funcionario = nil) then
     WriteLn('Erro ao inserir o funcionario')
  else
     WriteLn('Funcionario ', funcionario^.Id , ' inserido sem erros');


end.

