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

function ResolveStructureScript: string;
begin
  Result := '..\db\estrutura incial.sql';
  if FileExists(Result) then
    Exit;

  Result := 'db\estrutura incial.sql';
end;

function UsuariosTableExists(AConnection: TSQLite3Connection): boolean;
var
  query: TSQLQuery;
begin
  Result := false;
  query := TSQLQuery.Create(AConnection);
  try
    query.SQLConnection := AConnection;
    query.Transaction := AConnection.Transaction;
    query.SQL.Text :=
      'select name from sqlite_master where type = ''table'' and name = ''usuarios''';
    query.Open;
    Result := not query.EOF;
  finally
    query.Close;
    query.Free;
  end;
end;

procedure ExecuteStructureScript(AConnection: TSQLite3Connection);
var
  error: TScriptError;
  scriptFile: string;
begin
  scriptFile := ResolveStructureScript;
  case ExecuteScipt(scriptFile, AConnection, error) of
    esrSuccess:
      Exit;
    esrScriptNotFound:
      begin
        WriteLn('Script de banco não encontrado: ', scriptFile);
        Halt(1);
      end;
    esrScriptError:
      begin
        WriteLn('Erro ao exectuar o script');
        WriteLn('Comando:', error.Command);
        WriteLn('Erro   :', error.Message);
        Halt(1);
      end;
  end;
end;

procedure InitializeDatabase;
var
  conexao : TSQLite3Connection;
begin
   WriteLn('Initializing database...');

  if FileExists(SERVER_DB) then
  begin
    conexao := GetConnection(SERVER_DB);
    if not UsuariosTableExists(conexao) then
    begin
      WriteLn(' -> Database schema not found. Creating tables...');
      ExecuteStructureScript(conexao);
    end;
  end
  else begin
    conexao := CrateNewDataBase(SERVER_DB);
    SetDefaultConnection(conexao);
    ExecuteStructureScript(conexao);
  end;

  WriteLn(' -> Database found (', SERVER_DB,')');
end;

end.

