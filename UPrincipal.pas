{******************************************************************************}
{ Projeto: BrCoop Pay FireMonkey                                               }
{  Biblioteca multiplataforma de componentes Delphi para intera��o com equipa- }
{ mentos de Automa��o Comercial utilizados no Brasil                           }
{                                                                              }
{ Direitos Autorais Reservados (c) 2024 Hacson "Turbo Drive" Alexandre         }
{                                                                              }
{ Colaboradores nesse arquivo:                                                 }
{                                                                              }
{                                                                              }
{  Esta biblioteca � software livre; voc� pode redistribu�-la e/ou modific�-la }
{ sob os termos da Licen�a P�blica Geral Menor do GNU conforme publicada pela  }
{ Free Software Foundation; tanto a vers�o 2.1 da Licen�a, ou (a seu crit�rio) }
{ qualquer vers�o posterior.                                                   }
{                                                                              }
{  Esta biblioteca � distribu�da na expectativa de que seja �til, por�m, SEM   }
{ NENHUMA GARANTIA; nem mesmo a garantia impl�cita de COMERCIABILIDADE OU      }
{ ADEQUA��O A UMA FINALIDADE ESPEC�FICA. Consulte a Licen�a P�blica Geral Menor}
{ do GNU para mais detalhes. (Arquivo LICEN�A.TXT ou LICENSE.TXT)              }
{                                                                              }
{  Voc� deve ter recebido uma c�pia da Licen�a P�blica Geral Menor do GNU junto}
{ com esta biblioteca; se n�o, escreva para a Free Software Foundation, Inc.,  }
{ no endere�o 59 Temple Street, Suite 330, Boston, MA 02111-1307 USA.          }
{ Voc� tamb�m pode obter uma copia da licen�a em:                              }
{ http://www.opensource.org/licenses/lgpl-license.php                          }
{                                                                              }
{ Hacson Alexandre Menezes de Andrade Lima - hacson25@gmail.com			      	   }
{******************************************************************************}

unit UPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Edit,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.TabControl,
  System.Generics.Collections, System.JSON, REST.Client,
  REST.Json, REST.Types, SmartPos, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo;

type
  TForm1 = class(TForm)
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    Label1: TLabel;
    edtOciKey: TEdit;
    Label2: TLabel;
    edtcliid: TEdit;
    Label3: TLabel;
    edtsecret: TEdit;
    Label4: TLabel;
    edtserial: TEdit;
    Button1: TButton;
    mmresp: TMemo;
    Label5: TLabel;
    edtnrtran: TEdit;
    Label6: TLabel;
    edtoper: TEdit;
    Label7: TLabel;
    edtqtde: TEdit;
    Label8: TLabel;
    edtcpf: TEdit;
    edtnome: TEdit;
    edtvalor: TEdit;
    Label9: TLabel;
    Label10: TLabel;
    Button2: TButton;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    wBody, WResponseContent, NSUPos, CdBand, IntegTef : String;

    procedure Operacao(ASerial, AIdCob, AOpTef, AQtParc, ACpf, ANome : String;
                AValor : Double; TpOper : Integer );
    function ConsultaPOS : Boolean;
  end;

var
  Form1: TForm1;
  WItemVnd, WItemCnc  : TItemVnd;
  WIdVnd              : TBusca;

implementation

{$R *.fmx}

procedure TForm1.Operacao(ASerial, AIdCob, AOpTef, AQtParc, ACpf, ANome : String;
                AValor : Double;  TpOper : Integer );
begin
  mmresp.lines.clear;
  WItemVnd := TItemVnd.Create;
  WItemCnc := TItemVnd.Create;
  WIdVnd := TBusca.Create;
  wTokenPos := '';
  wOciKey   := edtOcikey.Text;

  With WItemVnd do
  begin // json para registrar a transa��o
    IDCobranca     := AIdCob;

    if TpOper = 0 then
    begin
      NumSerialPOS   := ASerial;
      IDPagamento    := AOpTef;
      QTParcelas     := AQtParc;
      Amount         := StringReplace(
                        FormatFloat( '0.##', Round(AValor * 100) / 100 ),
                                     ',', '.', [rfReplaceAll]);
      if ACpf <> '' then
      begin
        With Extras do
          begin
            CPF := ACpf;
            Nome := ANome;
          end;
      end;
    end;
  end;

  With WItemCnc do
  begin  // json para CANCELAR A MESMA venda
    IDCobranca     := AIdCob;

    if TpOper = 0 then
    begin
      NumSerialPOS   := ASerial;
      IDPagamento    := AOpTef;
      QTParcelas     := AQtParc;
      Amount         := StringReplace(
                        FormatFloat( '0.##', Round(AValor * 100) / 100 ),
                                     ',', '.', [rfReplaceAll]);
      if ACpf <> '' then
      begin
        With Extras do
          begin
            CPF := ACpf;
            Nome := ANome;
          end;
      end;
      action := 'delete';
    end;
  end;

  // n�mero da transa��o usado na consulta
  WIdVnd.IDCobranca     := WItemVnd.IDCobranca;

  wBody := TJson.ObjectToJsonString(WItemVnd, [joIndentCasePreserve]);


  WResponseContent := TSmartTef.Operation(edtcliid.Text,
                                          edtsecret.Text,
                                          wBody,
                                          TpOper);
  if Copy(WResponseContent, 1, 2) <> 'E1' then
    begin
      Button2.Enabled := true;
      Button3.Enabled := true;

      mmresp.lines.Add('Retorno OK: '+WResponseContent);
    end
  else
    begin
      Button2.Enabled := false;
      Button3.Enabled := false;
      mmresp.lines.Add('Erro: '+WResponseContent);
    end;
end;

function TForm1.ConsultaPOS : Boolean;
var
  wStatus : String;
  wRetorno, jSubObj, jPgtoObj     : TJsonObject;
  JSArray  : TJSONArray;
  i : integer;
begin
  Result := false;
  wBody := TJson.ObjectToJsonString(WIdVnd, [joIndentCasePreserve]);

  WResponseContent := TSmartTef.Operation(edtcliid.Text,
                                          edtsecret.Text,
                                          wBody,
                                          1);  // 1: opera��o de consulta

  if copy(WResponseContent, 1, 2) <> 'E1' then
  begin
    wRetorno := TJsonObject.ParseJSONValue(WResponseContent) as TJsonObject;

    jSubObj := TJSONObject(wretorno.Values['data']);

    wStatus := jSubObj.GetValue<string>('comandaStatus');

    Result := (wStatus = '21') and (Trim(jSubObj.GetValue<string>('Pagamentos')) <> '');

    if Result then
    begin
      JSArray := TJSONObject.ParseJSONValue(
                                             TEncoding.ASCII.GetBytes(
                                               jSubObj.GetValue<string>('Pagamentos')
                                             ),
                                            0) as TJSONArray;
      for i := 0 to JSArray.Count - 1 do
      begin
        jPgtoObj := JSArray.Items[i] as TJSONObject;

        mmresp.lines.add('NameBase '+jPgtoObj.GetValue('NameBase').Value);
        mmresp.lines.add('PaidAmount '+jPgtoObj.GetValue('PaidAmount').Value);
        mmresp.lines.add('TEFCartao '+jPgtoObj.GetValue('TEFCartao').Value);
        mmresp.lines.add('TEFParcelas '+jPgtoObj.GetValue('TEFParcelas').Value);
        mmresp.lines.add('TEFAutorizacao '+jPgtoObj.GetValue('TEFAutorizacao').Value);
        mmresp.lines.add('TEFNSUSitef '+jPgtoObj.GetValue('TEFNSUSitef').Value);
      end;

      wTokenPos := '';
    end;
  end
  else
    mmresp.lines.Add('Erro: '+WResponseContent);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin  // registra a transa��o
  Operacao(edtserial.Text,	// Serial da maquineta
           edtnrtran.Text,  // n�mero da transa��o deve ser controlado pela automa��o
           edtoper.text,    // 1: d�bito; 2 cr�dito; em branco: aparece diversas
           edtqtde.Text,    // para vendas no cr�dito apenas. nas outras modalidades, informar sempre 1
           edtcpf.Text,     // sempre que informar o cfp, deve informar o nome
           edtnome.text,
           Strtofloat(edtvalor.Text),
           0                // 0: opera��o de venda ou cancelamento; 1: consulta
          );
end;

procedure TForm1.Button2Click(Sender: TObject);
begin // id da transa��o j� armazenado no registro
  ConsultaPOS;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  try
    wBody := TJson.ObjectToJsonString(WItemCnc, [joIndentCasePreserve]);
                                      //json de cancelamento criado no registro da transa��o
    WResponseContent := TSmartTef.Operation(edtcliid.Text,
                                            edtsecret.Text,
                                            wBody,
                                            0);
    wTokenPos := '';
  except
  end;
end;

end.
