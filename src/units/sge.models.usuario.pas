unit SGE.Models.Usuario;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  PUsuario = ^TUsuario;
  TUsuario = record
    Id      : Int64;
    Usuario : string;
    Senha   : string;
    Ativo   : boolean;
  end;

  EUserAlreadyExists = class(Exception);

  function UsuarioInsert(const AUsuario, ASenha : string): PUsuario;


implementation

uses
  SGE.Consts,
  SGE.DataBase,
  sqlite3conn, sqldb;

function UsuarioInsert(const AUsuario, ASenha : string): PUsuario;
const
  SQL_INSERT = 'insert into usuarios(usuario, senha) values (:usuario, :senha)';
var
  query: TSQLQuery;
  newId :Int64;
begin
  // todo: implement encyption for passowrd
  try
    query := GetQuery(SQL_INSERT);
    try
      query.ParamByName('usuario').AsString:= AUsuario;
      query.ParamByName('senha').AsString:= ASenha;
      query.ExecSQL;
      query.SQLConnection.Transaction.Commit;

      newId := TSQLite3Connection(query.SQLConnection).GetInsertID;
      if newId <> NULL_ID then
      begin
        New(Result);
        Result^.Id      := newId;
        Result^.Usuario := AUsuario;
        Result^.Senha   := ASenha;
        Result^.Ativo   := True;
      end;
    except
      on e:ESQLDatabaseError do
       if Pos('SQLITE_CONSTRAINT_UNIQUE', e.Message) >= 0 then
         raise EUserAlreadyExists.Create('This username is already taken');
    end;
  finally
    query.Free;
  end;
end;

end.

