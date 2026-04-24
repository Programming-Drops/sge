unit uFuncionario;

{$mode ObjFPC}{$H+}

interface

uses
 uConstantes;

type
  PFuncionario = ^TFuncionario;
  TFuncionario = record
    Id        : int64;
    Nome      : string;
    IdCargo   : integer;
    IdUsuario : integer;
    Ativo     : boolean;
  end;


  function FuncionarioInsert(
      const ANome      : string;
      const AIdCargo   : integer;
      const AIdUsuario : integer;
      const AAtivo     : boolean
    ): PFuncionario;


  function FuncionarioLoadById(const AId: int64) : PFuncionario;
  function FuncionarioUpadate(const AId: int64; AFuncionario: PFuncionario): boolean;
  function FuncionarioDelete(const AId: Int64): boolean;


implementation

uses
  udb, sqldb, sqlite3conn;

function FuncionarioInsert(
      const ANome      : string;
      const AIdCargo   : integer;
      const AIdUsuario : integer;
      const AAtivo     : boolean
    ): PFuncionario;
const
  SQL = 'insert into funcionarios(nome, id_cargo, id_usuario, ativo) values(' +
    ':nome, :id_cargo, :id_usuario, :ativo)';
var
  query: TSQLQuery;
  insertId : int64;
begin
  Result := nil;
  query := GetQuery(SQL);
  try
    query.ParamByName('nome').AsAnsiString:= ANome;
    query.ParamByName('id_cargo').AsInteger:= AIdCargo;
    query.ParamByName('id_usuario').Value:= Null;
    if AIdUsuario <> NULL_ID then
       query.ParamByName('AIdUsuario').AsInteger:= AIdUsuario;
    query.ParamByName('ativo').AsBoolean:= AAtivo;
    query.ExecSQL;
    query.SQLConnection.Transaction.Commit;

    insertId:= TSQLite3Connection(query.SQLConnection).GetInsertID;
    if insertId > NULL_ID then
    begin
      Result := GetMem(Sizeof(TFuncionario));
      Result^.Id        := insertId;
      Result^.Nome      := ANome;
      Result^.IdCargo   := AIdCargo;
      Result^.IdUsuario := AIdUsuario;
      Result^.Ativo     := AAtivo;
    end;
  finally
    query.Free;
  end;
end;

function FuncionarioLoadById(const AId: int64) : PFuncionario;
const
  SQL = 'select nome, id_cargo, id_usuario, ativo from funcionarios where id = :id';
var
  query: TSQLQuery;
begin
   Result := nil;
   try
     query := GetQuery(SQL);
     query.ParamByName('id').AsInteger:= AId;
     query.Open;
     if not (query.EOF) then
     begin
       Result := GetMem(Sizeof(TFuncionario));
       Result^.Id        := AId;
       Result^.Nome      := query.FieldByName('nome').AsString;
       Result^.IdCargo   := query.FieldByName('id_cargo').AsInteger;

       if (query.FieldByName('id_usuario').IsNull) then
          Result^.IdUsuario  := NULL_ID
       else
          Result^.IdUsuario := query.FieldByName('id_usuario').AsInteger;

       Result^.Ativo     := query.FieldByName('ativo').AsBoolean;
     end;
   finally
     if Assigned(query) then
        query.Free;
   end;
end;


function FuncionarioUpadate(const AId: int64; AFuncionario: PFuncionario): boolean;
const
  SQL = 'update funcionarios set ' +
        '  nome = :nome, id_cargo = :id_cargo, id_usuario = :id_usario, ativo = :ativo' +
        ' where id = :id';
var
  query : TSQLQuery;
begin
  Result := false;
  query := GetQuery(SQL);
  try
    query.ParamByName('id').AsInteger:= AId;
    query.ParamByName('nome').AsString:= AFuncionario^.Nome;
    query.ParamByName('id_cargo').AsInteger:= AFuncionario^.IdCargo;

    if AFuncionario^.IdUsuario = NULL_ID then
       query.ParamByName('id_usuario').Value := Null
    else
      query.ParamByName('id_usuario').AsInteger:= AFuncionario^.IdUsuario;

    query.ParamByName('ativo').AsBoolean := AFuncionario^.Ativo;
    query.ExecSQL;
    Result := (query.RowsAffected = 1);
  finally
    query.Free;
  end;
end;

function FuncionarioDelete(const AId: Int64): boolean;
const
  SQL = 'delte from funcionarios where id = :id';
var
  query: TSQLQuery;
begin
  Result := false;
  query := GetQuery(SQL);
  try
    query.ExecSQL;
    Result := (query.RowsAffected = 1);
  finally
    query.Free;
  end;
end;

end.

