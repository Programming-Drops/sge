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

begin

  conexao := CrateNewDataBase('teste.db');
  ExecuteScipt('..\db\estrutura incial.sql', conexao);

end.

