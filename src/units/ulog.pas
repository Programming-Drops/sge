unit ulog;

{$mode ObjFPC}{$H+}

interface

{
    id   integer primary key autoincrement,
    data timestamp not null,
    tipo char(1) not null,
    text varchar
    }


type

  TLogType = (
    ltErro         = 'E',
    ltInformation  = 'I'
  );

  TLogEntry = record
    Id   : Int64;
    Data : TDateTime;
    Tipo : TLogType;
    Text : string;
  end;


  function Log(ATipo: TLogType; const AText: string) : Int64;
  function LogInfo(const AText: string): Int64;
  function LogError(const AText: string): Int64;

implementation

uses
  udb, SQLDB, sqlite3conn, SysUtils;

function Log(ATipo: TLogType; const AText: string) : Int64;
const
  SQL_INSERT = 'insert into log(tipo, text) values (:tipo, :text)';
var
  cnn  : TSQLite3Connection;
  sql:  string;
begin
  sql := 'insert into log(tipo, text) values ('
        + QuotedStr(Char(ATipo)) + ', '
        + QuotedStr(AText) + '); commit;';

  cnn := GetDefaultConnection;
  cnn.ExecuteDirect(sql);
  //cnn.Transaction.Commit;

  {
  try
     Query := GetQuery(SQL_INSERT);
     Query.Params.ParamByName('tipo').AsString := Char(ATipo);
     Query.Params.ParamByName('text').AsString := AText;
     Query.ExecSQL;
     Query.SQLConnection.Transaction.Commit;
     //Result := TSQLite3Connection(query.SQLConnection).GetInsertID;
  finally
    Query.Free;
  end;
  }
end;

function LogInfo(const AText: string): Int64;
begin
  Result := Log(ltInformation, AText);
end;

function LogError(const AText: string): Int64;
begin
  Result := Log(ltErro, AText);
end;

end.

