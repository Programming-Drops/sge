unit SGE.Api;

{$mode ObjFPC}{$H+}

interface

uses
  fphttpapp,
  HTTPRoute, HTTPDefs;

type
  { TApiApplication }
  TApiApplication = class(THTTPApplication)
  public
    function RegisterPublicRoute(const APattern : String; AMethod : TRouteMethod; ACallBack: TRouteCallBack): THTTPRoute;
  end;

  procedure SendText(AResponse: TResponse; ACode: integer; const AText: string);
  procedure SendResponse(AResponse: TResponse; ACode: integer);
  procedure SendBadRequest(AResponse: TResponse; const AText: string = '');
  procedure SendUnauthorized(AResponse: TResponse; const AText: string = '');

var
  ApiServer : TApiApplication;

implementation

procedure SendText(AResponse: TResponse; ACode: integer; const AText: string);
begin
   AResponse.Code:= ACode;
   AResponse.Content:= AText;
   AResponse.ContentType:= 'text/plain';
   AResponse.SendContent;
end;

procedure SendResponse(AResponse: TResponse; ACode: integer);
begin
  AResponse.Code:= ACode;
  AResponse.SendContent;
end;

procedure SendBadRequest(AResponse: TResponse; const AText: string = '');
begin
  if (AText = '') then
    SendResponse(AResponse, 400)
  else
    SendText(AResponse, 400, AText);
end;

procedure SendUnauthorized(AResponse: TResponse; const AText: string = '');
begin
  if (AText = '') then
      SendResponse(AResponse, 401)
    else
      SendText(AResponse, 401, AText);
end;


{ TApiApplication }

function TApiApplication.RegisterPublicRoute(const APattern: String;
  AMethod: TRouteMethod; ACallBack: TRouteCallBack): THTTPRoute;
begin
  Result := HTTPRouter.RegisterRoute(APattern, AMethod, ACallBack);
end;


end.

