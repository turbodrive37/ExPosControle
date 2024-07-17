{******************************************************************************}
{ Projeto: BrCoop Pay FireMonkey                                               }
{  Biblioteca multiplataforma de componentes Delphi para interação com equipa- }
{ mentos de Automação Comercial utilizados no Brasil                           }
{                                                                              }
{ Direitos Autorais Reservados (c) 2024 Hacson "Turbo Drive" Alexandre         }
{                                                                              }
{ Colaboradores nesse arquivo:                                                 }
{                                                                              }
{                                                                              }
{  Esta biblioteca é software livre; você pode redistribuí-la e/ou modificá-la }
{ sob os termos da Licença Pública Geral Menor do GNU conforme publicada pela  }
{ Free Software Foundation; tanto a versão 2.1 da Licença, ou (a seu critério) }
{ qualquer versão posterior.                                                   }
{                                                                              }
{  Esta biblioteca é distribuída na expectativa de que seja útil, porém, SEM   }
{ NENHUMA GARANTIA; nem mesmo a garantia implícita de COMERCIABILIDADE OU      }
{ ADEQUAÇÃO A UMA FINALIDADE ESPECÍFICA. Consulte a Licença Pública Geral Menor}
{ do GNU para mais detalhes. (Arquivo LICENÇA.TXT ou LICENSE.TXT)              }
{                                                                              }
{  Você deve ter recebido uma cópia da Licença Pública Geral Menor do GNU junto}
{ com esta biblioteca; se não, escreva para a Free Software Foundation, Inc.,  }
{ no endereço 59 Temple Street, Suite 330, Boston, MA 02111-1307 USA.          }
{ Você também pode obter uma copia da licença em:                              }
{ http://www.opensource.org/licenses/lgpl-license.php                          }
{                                                                              }
{ Hacson Alexandre Menezes de Andrade Lima - hacson25@gmail.com			      	   }
{******************************************************************************}

unit SmartPos;

interface

uses
  System.JSON, REST.Client, REST.Json, SysUtils, REST.Types, DateUtils, 
  ShellApi, DBClient, System.Net.URLClient, IPPeerClient, IdHTTP,
  IdMultipartFormData, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL;

const
  WUrlApi         = 'https://api.poscontrole.com.br/v3/smart-tef/';
  WUrlTok         = 'https://api.poscontrole.com.br/v2/auth/token';

type

  TBusca = class(TObject)
  private
    FIDCobranca      : String;
  public
    constructor Create();
    destructor  Destroy; override;
    property IDCobranca: String read FIDCobranca write FIDCobranca;
  end;

  TExtras = class(TObject)
  private
    FCPF      : String;
    FNome     : String;
  public
    property CPF: String read FCPF write FCPF;
    property Nome: String read FNome write FNome;
  end;

  TItemVnd = class(TObject)
  private
    FNumSerialPOS   : String;
    FIDCobranca     : String;
    FIDPagamento    : String;
    FQTParcelas     : String;
    FAmount         : String;
    Faction         : String;
    FExtras         : TExtras;
  public
    constructor Create();
    destructor  Destroy; override;
    property NumSerialPOS: String read FNumSerialPOS write FNumSerialPOS;
    property IDCobranca: String read FIDCobranca write FIDCobranca;
    property IDPagamento: String read FIDPagamento write FIDPagamento;
    property QTParcelas: String read FQTParcelas write FQTParcelas;
    property Amount: String read FAmount write FAmount;
    property action: String read Faction write Faction;
    property Extras: TExtras read FExtras write FExtras;
  end;

  TSmartTef = class(TObject)
  private
    class function GetTokenSmart(PUrl, PClId, PClSec : String): string;
  public
    class function Operation(PClId, PClSec, PBody : String; TpOper : Integer): string;
  end;

var
  wTokenPos, wOciKey : String;

implementation

{ TItemVnd }
constructor TItemVnd.Create;
begin
  FExtras := TExtras.Create;
end;

destructor TItemVnd.Destroy;
begin
  FreeAndNil(FExtras);
end;

{ TBusca }
constructor TBusca.Create;
begin
  //
end;

destructor TBusca.Destroy;
begin
  //
end;

class function TSmartTef.GetTokenSmart(PUrl, PClId, PClSec : String): string;
var
  wRESTClient     : REST.Client.TRESTClient;
  wRESTRequest    : REST.Client.TRESTRequest;
  wRESTResponse   : REST.Client.TRESTResponse;
  wRetorno        : TJsonObject;
begin
    Result := '';
    wRESTClient := TRESTClient.Create(nil);
    wRESTRequest := TRESTRequest.Create(nil);
    wRESTResponse := TRESTResponse.Create(nil);

    try
      wRESTClient.BaseURL := PUrl;
      wRESTResponse.ContentType := 'application/x-www-form-urlencoded';
      wRESTRequest.Client := wRESTClient;
      wRESTRequest.Response := wRESTResponse;
      wRESTRequest.Method := TRESTRequestMethod.rmPOST;
      wRESTRequest.Params.AddItem('Ocp-Apim-Subscription-Key', wOciKey, pkHTTPHEADER, [poDoNotEncode]);
      wRESTRequest.Params.AddItem('ContentType','application/x-www-form-urlencoded',pkHTTPHEADER, [poDoNotEncode]);
      wRESTRequest.AddParameter('username',PClId);
      wRESTRequest.AddParameter('password',PClSec);
      wRESTRequest.Execute;
      wRetorno := TJsonObject.ParseJSONValue(wRESTResponse.Content) as TJsonObject;
      if wRESTResponse.StatusCode in [200, 201] then
        Result := wRetorno.GetValue<string>('jwt')
      else
        Result := 'E1 - Erro na validação do Token: '+wRESTResponse.Content;
    finally
      wRESTClient.Free;
      wRESTRequest.Free;
      wRESTResponse.Free;
    end;
end;

class function TSmartTef.Operation(PClId, PClSec, PBody : String; TpOper : Integer): string;
var
  wRESTClient     : REST.Client.TRESTClient;
  wRESTRequest    : REST.Client.TRESTRequest;
  wRESTResponse   : REST.Client.TRESTResponse;
  wRetorno        : TJsonObject;
begin
  if wTokenPos = '' then
    wTokenPos := GetTokenSmart(WUrlTok, PClId, PClSec);
  if copy(wTokenPos, 1, 2) <> 'E1' then
  begin
    Result := '';
    try
      case TpOper of
        0 : wRESTClient   := TRESTClient.Create(WUrlApi+'newItem');
        1 : wRESTClient   := TRESTClient.Create(WUrlApi+'get-status');
      end;

      wRESTRequest  := TRESTRequest.Create(nil);
      wRESTResponse := TRESTResponse.Create(nil);

      wRESTClient.Accept              := 'application/json;q=0.9,text/plain;q=0.9,text/html';
      wRESTClient.AcceptCharset       := 'UTF-8';
      wRESTClient.HandleRedirects     := True;
      wRESTClient.RaiseExceptionOn500 := False;

      wRESTRequest.Accept             := 'application/json;q=0.9,text/plain;q=0.9,text/html';
      wRESTRequest.AcceptCharset      := 'UTF-8';
      wRESTRequest.Client             := wRESTClient;
      wRESTRequest.Method             := TRESTRequestMethod.rmPOST;
      wRESTRequest.Body.ClearBody;
      wRESTRequest.Params.AddItem('Ocp-Apim-Subscription-Key', wOciKey, pkHTTPHEADER, [poDoNotEncode]);
      wRESTRequest.Params.AddItem('Authorization','Bearer '+wTokenPos, pkHTTPHEADER, [poDoNotEncode]);
      wRESTRequest.Params.AddItem('ContentType','application/json',pkHTTPHEADER, [poDoNotEncode]);
      wRESTRequest.AddBody(PBody, TRestContentType.ctAPPLICATION_JSON);

      wRESTRequest.Response           := wRESTResponse;
      wRESTRequest.Timeout            := 0;
      wRESTRequest.SynchronizedEvents := False;

      try
        wRESTRequest.Execute;
        if wRESTResponse.StatusCode in [200, 201] then
          begin
            wRetorno := TJsonObject.ParseJSONValue(wRESTResponse.Content) as TJsonObject;
            if wRetorno.GetValue<string>('msg') = 'OK' then
              Result := wRESTResponse.Content
            else
              Result := 'E1 - '+wRetorno.GetValue<string>('msg')+' '+wRetorno.GetValue<string>('responseCode');
          end
        else
          Result := 'E1 - '+wRESTResponse.StatusCode.ToString;
      except
        on e: exception  do
          Result := 'E1 - '+e.message;
      end;
    finally
      wRESTClient.Free;
      wRESTRequest.Free;
      wRESTResponse.Free;
    end;
  end
  else
    Result := wTokenPos;
end;

end.
