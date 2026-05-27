unit SGE.Api.HealthCheck;

{$mode ObjFPC}{$H+}

interface

uses
  SGE.Api,
  Classes, SysUtils;


procedure Register;


implementation

uses
  httproute,
  HTTPDefs;


procedure GetHealth(ARequest: TRequest; AResponse: TResponse);
begin
  WriteLn(' > ', ARequest.Method, ' ', ARequest.URI);

  SendOk(AResponse, 'Healty');
end;



procedure Register;
begin
  ApiServer.RegisterPublicRoute('/health', rmGet, @GetHealth);

  WriteLn('    - [ok] SGE.Api.HealthCheck' );
end;

end.

