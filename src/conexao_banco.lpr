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
  conexao := GetConnection;
  try
    if (conexao.Connected) then
    begin
      WriteLn('Banco conectado!');

      cargo := CargoInsert('Cargo de teste');
      id := cargo^.Id;
      CargoDelete(id);
      cargo := CargoLoadById(id);

      if (cargo = nil) then
        WriteLn('A função funcionou')
      else
        WriteLn('Houve algum erro');

    end;
    conexao.Close();
    conexao.Free;
  except
    on e: Exception do
       WriteLn('Erro ao conectar no banco: ' + e.Message);
    end;
end.

