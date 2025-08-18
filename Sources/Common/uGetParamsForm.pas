unit uGetParamsForm;

interface

uses
  { VCL }
  System.Classes, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls;

type

  TfmGetParamsForm = class(TForm)

    pCommon: TGridPanel;
    pContent: TPanel;
    pButtons: TPanel;

    lText: TLabel;
    mParams: TMemo;

    bOk: TButton;
    bCancel: TButton;

  strict private

    function GetParams: String;

  private

    constructor Create(const _Text: String); reintroduce;

    property Params: String read GetParams;

  end;

function GetParams(const Text: String; var Params: String): Boolean;

implementation

{$R *.dfm}

function GetParams(const Text: String; var Params: String): Boolean;
var
  Form: TfmGetParamsForm;
begin

  Form := TfmGetParamsForm.Create(Text);
  try

    Result := Form.ShowModal = mrOk;
    if Result then
      Params := Form.Params;

  finally
    Form.Free;
  end;

end;

{ TfmGetParamsForm }

constructor TfmGetParamsForm.Create(const _Text: String);
begin
  inherited Create(Application.MainForm);
  lText.Caption := _Text;
end;

function TfmGetParamsForm.GetParams: String;
begin
  Result := mParams.Lines.Text;
end;

end.
