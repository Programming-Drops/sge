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


  (*
  function CargoLoadById(const AId: integer): PCargo;
  function CargoUpdate(const AId: integer; const ANome: string) : boolean;
  function CargoDelete(const AId: integer): boolean;
  procedure CargoPrint(ACargo: PCargo);
  *)



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
  query.ParamByName('nome').AsAnsiString:= ANome;
  query.ParamByName('id_cargo').AsInteger:= AIdCargo;
  query.ParamByName('id_usuario').Value:= Null;
  if AIdUsuario <> NULL_ID then
     query.ParamByName('AIdUsuario').AsInteger:= AIdUsuario;
  query.ParamByName('ativo').AsBoolean:= AAtivo;
  query.ExecSQL;

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
end;




end.

