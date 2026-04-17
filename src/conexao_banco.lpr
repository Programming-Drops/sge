program conexao_banco;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes,
  sqldb,
  sqlite3conn,
  SysUtils;


(*, Forms, Controls, Graphics, Dialogs; *)

type

  PCargo = ^TCargo;
  TCargo = record
    Id   : integer;
    Nome : string;
  end;



  function GetConnection(
    const ADatabaseName: string;
    ADefaultTransaction: boolean = true): TSQLite3Connection; forward;

  (***
     CRUD CREATE | READ | UPDATE | DELETE
  ***)




  function CargoInsert(AConnection: TSQLite3Connection; const ANome: string): PCargo;
  const
     SQL_INSERT = 'insert into cargos(nome) values (:nome)';
     SQL_SELECT = 'select max(id) as id from cargos';
  var
     query: TSQLQuery;
  begin
     Result := nil;
     Assert(AConnection <> nil);
     try
        query:= TSQLQuery.Create(nil);
        query.SQLConnection := AConnection;
        query.SQL.Add(SQL_INSERT);
        query.Params.ParamByName('nome').AsString:= ANome;
        query.ExecSQL;
        AConnection.Transaction.Commit;

        query.SQL.Clear;
        query.SQL.Add(SQL_SELECT);
        query.Open;
        if not(query.EOF) then
        begin
           Result := GetMem(SizeOf(TCargo));
           Result^.Id   := query.FieldByName('id').AsInteger;
           Result^.Nome := ANome;
        end;
        query.Close;
     finally
        query.Free;
     end;
  end;


  function CargoLoadById(AConnection: TSQLite3Connection; const AId: integer): PCargo;
  const
    SQL_SELECT = 'select id, nome from cargos where id = :id';
  var
    query : TSQLQuery;
  begin
    Result := nil;
    Assert(AConnection <> nil);
    try
       query:= TSQLQuery.Create(nil);
       query.SQLConnection := AConnection;
       query.SQL.Add(SQL_SELECT);
       query.ParamByName('id').AsInteger:= AId;
       query.Open;
       if (not query.EOF) then
       begin
         Result := GetMem(SizeOf(TCargo));
         Result^.Id   := query.FieldByName('id').AsInteger;
         Result^.Nome := query.FieldByName('nome').AsString;
       end;
    finally
       query.Close;
       query.Free;
    end;
  end;


   procedure CargoPrint(ACargo: PCargo);
   begin
     Assert(ACargo <>nil);
     WriteLn('  id   ' + IntToStr(ACargo^.Id));
     WriteLn('  nome ' + ACargo^.Nome);
   end;



  function GetConnection(
    const ADatabaseName: string;
    ADefaultTransaction: boolean = true ): TSQLite3Connection;
  begin
    Result := TSQLite3Connection.Create(nil);
    Result.DatabaseName:= ADatabaseName;
    if ADefaultTransaction then
      Result.Transaction := TSQLTransaction.Create(Result);
  end;


var
 conexao : TSQLite3Connection;
 cargo   : PCargo;

begin
  conexao := GetConnection('database.sqlite3');
  try
    conexao.Open;
    if (conexao.Connected) then
    begin
      WriteLn('Banco conectado!');

      cargo := CargoInsert(conexao, 'Engenheiro de Software');
      if (cargo = nil) then
        WriteLn('Erro ao inserir o cargo')
      else begin
        WriteLn('O cargo foi inserido com sucesso');
        CargoPrint(cargo);

        Freemem(cargo);
        cargo := CargoLoadById(conexao, 1);
        if (cargo = nil) then
          WriteLn('Cargo 5 não encontrado')
        else begin
          WriteLn('O cargo foi inserido com sucesso');
          CargoPrint(cargo);
        end;
      end;
    end;
    conexao.Close();
    conexao.Free;
  except
    on e: Exception do
       WriteLn('Erro ao conectar no banco: ' + e.Message);
    end;
end.

