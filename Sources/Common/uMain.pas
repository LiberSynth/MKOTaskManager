unit uMain;

interface

uses
  { VCL }
  System.Classes, Vcl.Forms, System.Types, Vcl.Controls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.StdCtrls,
  { TM }
  uCommon, uLibSupport;

type

  TfmMain = class(TForm)

    pCommon: TGridPanel;
    pRightSide: TGridPanel;
    pTaskTypes: TPanel;
    pTasks: TPanel;
    pConsole: TPanel;
    lTaskTypes: TLabel;
    lvTaskTypes: TListView;
    lTasks: TLabel;
    lvTasks: TListView;
    lConsole: TLabel;
    lvConsole: TListView;

    procedure FormCreate(Sender: TObject);

  strict private

    procedure AdjustSizes;

  end;

var
  fmMain: TfmMain;

implementation

{$R *.dfm}

procedure TfmMain.FormCreate(Sender: TObject);
begin

  AdjustSizes;
  LoadLibraries;

end;

procedure TfmMain.AdjustSizes;
var
  Size: TRect;
begin

  Size := GoldenSize(Screen.Width, Screen.Height);

  Left   := Size.Left;
  Top    := Size.Top;
  Width  := Size.Width;
  Height := Size.Height;

end;

end.
