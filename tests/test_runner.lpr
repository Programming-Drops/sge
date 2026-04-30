program test_runner;

{$mode objfpc}{$H+}
{$codepage utf8}

uses
  simpletestrunner,
  test_udb;

var
  Application: TTestRunner;
begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Run;
  Application.Free;
end.
