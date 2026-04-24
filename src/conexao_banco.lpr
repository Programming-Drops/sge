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
 idFuncionario: Int64;
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
  else begin
     idFuncionario := funcionario^.Id;
     WriteLn('Funcionario ', idFuncionario , ' inserido sem erros');
     Freemem(funcionario);
     funcionario := FuncionarioLoadById(idFuncionario);
     if (funcionario = nil) then
       WriteLn('Não foi possível carregar o funcinário');
  end;


end.

