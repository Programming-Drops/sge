unit SGE.Api;

{$mode ObjFPC}{$H+}

interface

uses
  fphttpapp,
  HTTPRoute, HTTPDefs;

type

  { TJsonRequestValidador }
  TRequestValidadorEnum = (
    rvOk,
    rvJsonMimeTypeRequired,
    rvJsonEmptyBody
  );

  TRequestValidadorResult = record
    Code    : TRequestValidadorEnum;
    Message : string;
  end;

  { TRequestValidador }
  TRequestValidador = class
  public
     class function RequiredJson(ARequest: TRequest): TRequestValidadorResult;
  end;




type
  { TApiApplication }
  TApiApplication = class(THTTPApplication)
  public
    function RegisterPublicRoute(const APattern : String; AMethod : TRouteMethod; ACallBack: TRouteCallBack): THTTPRoute;
  end;

  procedure SendText(AResponse: TResponse; ACode: integer; const AText: string);
  procedure SendJson(AResponse: TResponse; ACode: integer; const AJsonText: string);
  procedure SendResponse(AResponse: TResponse; ACode: integer);
  procedure SendBadRequest(AResponse: TResponse; const AText: string = '');

  procedure SendOk(AResponse: TResponse; const AText: string = ''; IsJSON: boolean = false);
  procedure SendNotFound(AResponse: TResponse; const AText: string = '');
  procedure SendUnauthorized(AResponse: TResponse; const AText: string = '');
  procedure SendConfict(AResponse: TResponse; const AText: string = '');
  procedure SendInternalServerError(AResponse: TResponse; const AText: string = '');
  procedure SendCreated(AResponse: TResponse; const ALocation:string = ''; const AText: string = '');

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

procedure SendJson(AResponse: TResponse; ACode: integer; const AJsonText: string);
begin
   AResponse.Code:= ACode;
   AResponse.Content:= AJsonText;
   AResponse.ContentType:= 'application/json';
   AResponse.SendContent;
end;

procedure SendResponse(AResponse: TResponse; ACode: integer);
begin
  AResponse.Code:= ACode;
  case AResponse.Code of
     200 : AResponse.CodeText:= 'OK';
     201 : AResponse.CodeText:= 'Created';
     400 : AResponse.CodeText:= 'Bad Request';
     401 : AResponse.CodeText:= 'Unauthorized';
     404 : AResponse.CodeText:= 'Not Found';
     409 : AResponse.CodeText:= 'Conflict';
     500 : AResponse.CodeText:= 'Internal Server Error';
  end;
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

procedure SendConfict(AResponse: TResponse; const AText: string = '');
begin
  if (AText = '') then
    SendText(AResponse, 409, 'Conflict')
  else
    SendText(AResponse, 409, AText);
end;

procedure SendInternalServerError(AResponse: TResponse; const AText: string = '');
begin
  if (AText = '') then
    SendText(AResponse, 500, 'Internal Server Error')
  else
    SendText(AResponse, 500, AText);
end;

procedure SendOk(AResponse: TResponse; const AText: string = ''; IsJSON: boolean = false);
begin
  if (AText = '') then
    SendResponse(AResponse, 200)
  else
    if IsJSON then
      SendJson(AResponse, 200, AText)
    else
      SendText(AResponse, 200, AText);
end;

procedure SendCreated(AResponse: TResponse; const ALocation:string = ''; const AText: string = '');
begin
  AResponse.Code:= 201;

  if ( ALocation <> '') then
    AResponse.SetCustomHeader('Location', ALocation);

  if AText <> '' then
  begin
    AResponse.ContentType:=  'text/plain';
    AResponse.Content    := AText;
  end;
  AResponse.SendContent;
end;

procedure SendNotFound(AResponse: TResponse; const AText: string = '');
begin
  if (AText = '') then
    SendResponse(AResponse, 404)
  else
    SendText(AResponse, 404, AText);
end;


{ TRequestValidador }

class function TRequestValidador.RequiredJson(ARequest: TRequest
  ): TRequestValidadorResult;
begin
  if (ARequest.ContentType <> 'application/json') then
  begin
    Result.Code   := rvJsonMimeTypeRequired;
    Result.Message:= 'Mime type invalid';
  end else
  if ARequest.ContentLength = 0 then
    begin
      Result.Code   := rvJsonEmptyBody;
      Result.Message := 'Content cannot be empty';
    end
  else
  begin
    Result.Code    := rvOk;
    Result.Message := '';
  end;
end;

{ TApiApplication }

function TApiApplication.RegisterPublicRoute(const APattern: String;
  AMethod: TRouteMethod; ACallBack: TRouteCallBack): THTTPRoute;
begin
  Result := HTTPRouter.RegisterRoute(APattern, AMethod, ACallBack);
end;


end.

