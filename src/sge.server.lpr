program sge.server;


uses
  SysUtils,


  SGE.Models.Cargo,

  SGE.Api,
  SGE.Api.Auth,
  SGE.Api.Cargos,
  SGE.Api.HealthCheck,
  SGE.Api.DataBase,
  SGE.Api.Usuarios;


begin
  WriteLn('SGE server.');
  SGE.Api.DataBase.InitializeDatabase;

  WriteLn(' -> Setting up server...');
  ApiServer := TApiApplication.Create(nil);
  ApiServer.Port := 8085;
  ApiServer.Threaded:= False;

  WriteLn(' -> Setting up routes...');
  SGE.Api.HealthCheck.Register;
  SGE.Api.Auth.Register;
  SGE.Api.Cargos.Register;
  SGE.Api.Usuarios.Register;

  ApiServer.Initialize;
  WriteLn(' -> Server is running on localhost:', ApiServer.Port);
  try
    ApiServer.Run;
  except
     on e:Exception do
     begin
        WriteLn('Houve um erro ao processar a requisição');
        WriteLn(e.Message);
     end;
  end;
end.

