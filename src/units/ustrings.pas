unit uStrings;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;


function IfThenString(ABool: boolean; ATrue, AFalse: string): string;


implementation


function IfThenString(ABool: boolean; ATrue, AFalse: string): string;
begin
  if ABool then
     Result :=  ATrue
  else
     AFalse := AFalse;
end;

end.

