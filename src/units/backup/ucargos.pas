unit uCargos;

{$mode ObjFPC}{$H+}

interface

uses
  sqlite3conn;

type
  PCargo = ^TCargo;
  TCargo = record
    Id   : integer;
    Nome : string;
  end;



  function CargoInsert(const ANome: string): PCargo;
  function CargoLoadById(const AId: integer): PCargo;
  function CargoUpdate(const AId: integer; const ANome: string) : boolean;
  function CargoDelete(const AId: integer): boolean;
  procedure CargoPrint(ACargo: PCargo);


implementation

uses
  sqldb, sysutils, udb, uConstantes;

function CargoInsert(const ANome: string): PCargo;
const
   SQL_INSERT = 'insert into cargos(nome) values (:nome)';
var
   newId :Int64;
   query: TSQLQuery;
begin
   Result := nil;
   try
      query:= GetQuery(SQL_INSERT);
      query.Params.ParamByName('nome').AsString:= ANome;
      query.ExecSQL;
      query.SQLConnection.Transaction.Commit;

      newId := TSQLite3Connection(query.SQLConnection).GetInsertID;
      if newId <> ID then
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

function CargoLoadById(const AId: integer): PCargo;
const
  SQL_SELECT = 'select id, nome from cargos where id = :id';
var
  query : TSQLQuery;
begin
  Result := nil;
  try
     query:= GetQuery(SQL_SELECT);
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

function CargoUpdate(const AId: integer; const ANome: string) : boolean;
const
  SQL_UPDATE = 'update cargos set nome = :nome where id = :id';
var
  query : TSQLQuery;
begin
  result := false;
  query:= nil;
  try
    query := GetQuery(SQL_UPDATE);
    query.ParamByName('id').AsInteger  := AId;
    query.ParamByName('nome').AsString := ANome;
    query.ExecSQL;
    result := true;
  finally
     query.Free;
  end;
end;

function CargoDelete(const AId: integer): boolean;
const
  SQL_DELETE = 'delete from cargos where id = :id';
var
  query : TSQLQuery;
begin
  result := false;
  try
    query := GetQuery(SQL_DELETE);
    query.ParamByName('id').AsInteger:= AId;
    query.ExecSQL;
    result := true;
  finally
     query.Free;
  end;
end;

procedure CargoPrint(ACargo: PCargo);
 begin
   Assert(ACargo <>nil);
   WriteLn('  id   ' + IntToStr(ACargo^.Id));
   WriteLn('  nome ' + ACargo^.Nome);
 end;



end.

