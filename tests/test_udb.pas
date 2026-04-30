unit test_udb;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes,
  fpcunit,
  testregistry;

type
  TDbTests = class(TTestCase)
  private
    function CreateTempScript(const AContent: string): string;
  published
    procedure ParseScriptReturnsCommandsEndingWithSemicolon;
    procedure ParseScriptReturnsEmptyListForEmptyFile;
  end;

implementation

uses
  SysUtils,
  udb;

function TDbTests.CreateTempScript(const AContent: string): string;
var
  Script: TStringList;
begin
  Result := IncludeTrailingPathDelimiter(GetTempDir) +
    Format('sge-test-%d.sql', [Random(MaxInt)]);

  Script := TStringList.Create;
  try
    Script.Text := AContent;
    Script.SaveToFile(Result);
  finally
    Script.Free;
  end;
end;

procedure TDbTests.ParseScriptReturnsCommandsEndingWithSemicolon;
var
  FileName: string;
  Commands: TStringList;
begin
  FileName := CreateTempScript(
    'create table cargos (id integer primary key, nome varchar(100));' + LineEnding +
    'insert into cargos(nome) values (''Administrador'');'
  );
  Commands := nil;
  try
    Commands := ParseScript(FileName);

    AssertEquals('Quantidade de comandos', 2, Commands.Count);
    AssertEquals(
      'Primeiro comando',
      'create table cargos (id integer primary key, nome varchar(100));',
      Commands[0]
    );
    AssertEquals(
      'Segundo comando',
      'insert into cargos(nome) values (''Administrador'');',
      Commands[1]
    );
  finally
    Commands.Free;
    DeleteFile(FileName);
  end;
end;

procedure TDbTests.ParseScriptReturnsEmptyListForEmptyFile;
var
  FileName: string;
  Commands: TStringList;
begin
  FileName := CreateTempScript('');
  Commands := nil;
  try
    Commands := ParseScript(FileName);

    AssertEquals('Quantidade de comandos', 0, Commands.Count);
  finally
    Commands.Free;
    DeleteFile(FileName);
  end;
end;

initialization
  RegisterTest(TDbTests);

end.
