unit uMain;

interface

uses
  { VCL }
  System.Classes, Vcl.Forms, System.Types, Vcl.Controls, Vcl.ComCtrls,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids, System.Math,
  { TM }
  uConsts, uCommon, uLibSupport, uInterfaces;

type

  {TODO -oVasilevSM : —делать подсказку на €чейках, к которые не поместилс€ текст. }
  TfmMain = class(TForm)

    pCommon: TGridPanel;
    pRightSide: TGridPanel;
    pTasks: TPanel;
    pRunning: TPanel;
    pConsole: TPanel;

    lTasks: TLabel;
    lRunning: TLabel;
    lvRunning: TListView;
    lConsole: TLabel;
    lvConsole: TListView;

    sgTasks: TStringGrid;

    procedure FormCreate(Sender: TObject);

  strict private

    procedure AdjustSizes;
    procedure FillTasks;

  end;

var
  fmMain: TfmMain;

implementation

{$R *.dfm}

procedure TfmMain.FillTasks;
var
  RecNo: Integer;
  MKOLibrary: TMKOLibrary;
  MKOTask: TMKOTask;
begin

  with sgTasks do
  begin

    ColWidths[0] := 200;
    ColWidths[1] := 400;

    Cells[0, 0] := SC_TASKS_COLUMN_0_CAPTION;
    Cells[1, 0] := SC_TASKS_COLUMN_1_CAPTION;

    RowCount := Max(TaskServices.TaskCount + 1, 2);
    RecNo := 0;

    for MKOLibrary in TaskServices.Libraries do

      for MKOTask in MKOLibrary.Tasks do
      begin

        Cells[0, RecNo + 1] := MKOTask.Caption;
        Cells[1, RecNo + 1] := MKOTask.Description;

        Inc(RecNo);

      end;

  end;

end;

procedure TfmMain.FormCreate(Sender: TObject);
begin

  AdjustSizes;
  TaskServices.LoadLibraries;
  FillTasks;

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
