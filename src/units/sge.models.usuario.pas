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
  function UsuarioLoadByName(const AUsuario: string): PUsuario;
  function UsuarioAuthenticate(const AUsuario, ASenha: string): boolean;
  function UsuarioUpdatePassword(const AUsuario, ASenha: string): boolean;
  function UsuarioPasswordIsHashed(const ASenha: string): boolean;
  function UsuarioHashPassword(const ASenha: string): string;


implementation

uses
  HlpIHashInfo,
  HlpHashFactory,
  HlpConverters,
  HlpPBKDF_Argon2NotBuildInAdapter,
  HlpArgon2TypeAndVersion,
  SGE.Consts,
  SGE.DataBase,
  sqlite3conn, sqldb;

const
  PASSWORD_HASH_PREFIX = 'argon2id$';
  ARGON2_MEMORY_KB = 65536;
  ARGON2_ITERATIONS = 3;
  ARGON2_PARALLELISM = 1;
  ARGON2_HASH_BYTES = 32;

function GeneratePasswordSalt: string;
var
  saltId: TGuid;
begin
  CreateGUID(saltId);
  Result := GUIDToString(saltId);
  Result := StringReplace(Result, '{', '', [rfReplaceAll]);
  Result := StringReplace(Result, '}', '', [rfReplaceAll]);
  Result := StringReplace(Result, '-', '', [rfReplaceAll]);
end;

function Argon2idHash(const APassword, ASalt: string): string;
var
  generator: IPBKDF_Argon2;
  parameters: IArgon2Parameters;
  builder: IArgon2ParametersBuilder;
  passwordBytes, saltBytes: TBytes;
begin
  passwordBytes := TConverters.ConvertStringToBytes(APassword, TEncoding.UTF8);
  saltBytes := TConverters.ConvertStringToBytes(ASalt, TEncoding.UTF8);

  builder := TArgon2idParametersBuilder.Builder;
  builder
    .WithVersion(TArgon2Version.a2vARGON2_VERSION_13)
    .WithIterations(ARGON2_ITERATIONS)
    .WithMemoryAsKB(ARGON2_MEMORY_KB)
    .WithParallelism(ARGON2_PARALLELISM)
    .WithSalt(saltBytes);

  parameters := builder.Build;
  builder.Clear;

  generator := TKDF.TPBKDF_Argon2.CreatePBKDF_Argon2(passwordBytes, parameters);
  Result := TConverters.ConvertBytesToHexString(generator.GetBytes(ARGON2_HASH_BYTES), False);

  parameters.Clear;
  generator.Clear;
end;

function UsuarioPasswordIsHashed(const ASenha: string): boolean;
begin
  Result := Pos(PASSWORD_HASH_PREFIX, ASenha) = 1;
end;

function UsuarioHashPassword(const ASenha: string): string;
var
  salt, hash: string;
begin
  salt := GeneratePasswordSalt;
  hash := Argon2idHash(ASenha, salt);
  Result := Format(
    'argon2id$v=19$m=%d,t=%d,p=%d$%s$%s',
    [ARGON2_MEMORY_KB, ARGON2_ITERATIONS, ARGON2_PARALLELISM, salt, hash]);
end;

function UsuarioVerifyPasswordHash(const ASenha, AHash: string): boolean;
var
  parts: TStringList;
  expectedHash, params: string;
begin
  Result := false;
  parts := TStringList.Create;
  try
    parts.StrictDelimiter := true;
    parts.Delimiter := '$';
    parts.DelimitedText := AHash;

    params := Format('m=%d,t=%d,p=%d', [
      ARGON2_MEMORY_KB, ARGON2_ITERATIONS, ARGON2_PARALLELISM]);

    if (parts.Count <> 5) or
       (parts[0] <> 'argon2id') or
       (parts[1] <> 'v=19') or
       (parts[2] <> params) then
      Exit;

    expectedHash := Argon2idHash(ASenha, parts[3]);
    Result := SameText(expectedHash, parts[4]);
  finally
    parts.Free;
  end;
end;

function UsuarioInsert(const AUsuario, ASenha : string): PUsuario;
const
  SQL_INSERT = 'insert into usuarios(usuario, senha) values (:usuario, :senha)';
var
  query: TSQLQuery;
  newId :Int64;
  senhaHash: string;
begin
  Result := nil;
  senhaHash := UsuarioHashPassword(ASenha);
  try
    query := GetQuery(SQL_INSERT);
    try
      query.ParamByName('usuario').AsString:= AUsuario;
      query.ParamByName('senha').AsString:= senhaHash;
      query.ExecSQL;
      query.SQLConnection.Transaction.Commit;

      newId := TSQLite3Connection(query.SQLConnection).GetInsertID;
      if newId <> NULL_ID then
      begin
        New(Result);
        Result^.Id      := newId;
        Result^.Usuario := AUsuario;
        Result^.Senha   := senhaHash;
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

function UsuarioLoadByName(const AUsuario: string): PUsuario;
const
  SQL_SELECT = 'select id, usuario, senha, ativo from usuarios where usuario = :usuario';
var
  query: TSQLQuery;
begin
  Result := nil;
  query := GetQuery(SQL_SELECT);
  try
    query.ParamByName('usuario').AsString := AUsuario;
    query.Open;
    if not query.EOF then
    begin
      New(Result);
      Result^.Id      := query.FieldByName('id').AsInteger;
      Result^.Usuario := query.FieldByName('usuario').AsString;
      Result^.Senha   := query.FieldByName('senha').AsString;
      Result^.Ativo   := query.FieldByName('ativo').AsBoolean;
    end;
  finally
    query.Close;
    query.Free;
  end;
end;

function UsuarioUpdatePassword(const AUsuario, ASenha: string): boolean;
const
  SQL_UPDATE = 'update usuarios set senha = :senha where usuario = :usuario';
var
  query: TSQLQuery;
begin
  Result := false;
  query := GetQuery(SQL_UPDATE);
  try
    query.ParamByName('usuario').AsString := AUsuario;
    query.ParamByName('senha').AsString := ASenha;
    query.ExecSQL;
    query.SQLConnection.Transaction.Commit;
    Result := true;
  finally
    query.Free;
  end;
end;

function UsuarioAuthenticate(const AUsuario, ASenha: string): boolean;
var
  user: PUsuario;
  migratedPassword: string;
begin
  Result := false;
  user := UsuarioLoadByName(AUsuario);
  try
    if user = nil then
      Exit;

    if not user^.Ativo then
      Exit;

    if UsuarioPasswordIsHashed(user^.Senha) then
      Exit(UsuarioVerifyPasswordHash(ASenha, user^.Senha));

    if user^.Senha <> ASenha then
      Exit;

    migratedPassword := UsuarioHashPassword(ASenha);
    UsuarioUpdatePassword(AUsuario, migratedPassword);
    Result := true;
  finally
    if Assigned(user) then
      Dispose(user);
  end;
end;

end.

