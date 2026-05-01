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

  uCargos, uDb, uFuncionario, uConstantes, uStrings, ulog;


procedure InsertTestLogs;
var
  i : integer;
  x : real;
begin
  WriteLn('Inserindo logs');
  LogInfo('Log de teste');
  LogError('Erro fake');
  for i:= 1 to 300 do
  begin
    LogInfo('Log de teste ' + Inttostr(i));
    if i mod 20 = 0 then
    begin
      x := (i / 300) * 100;
      WriteLn(x:2:0, '% concluído.');
    end;
  end;
  WriteLn('100% concluído.');
end;


procedure InsertCargos;
var
  i : integer;
begin
  WriteLn('Inserindo cargos');
  for i := 1 to 300 do
  begin
    CargoInsert('Cargo ' + IntToStr(i));
    if i mod 20 = 0 then
    begin
      WriteLn(((i/300)*100):2:0, '% concluído.');
    end;
  end;
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
  InsertTestLogs;
end.

