unit uMain;

interface

uses
  { VCL }
  System.Classes, Vcl.Forms, System.Types, Vcl.Controls, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Grids, System.Math, Vcl.Menus, System.SysUtils,
  { TM }
  uConsts, uCommon, uLibSupport, uInterfaces, uTypes, uGetTextForm, uUtils;

type

  {TODO 1 -oVasilevSM : Сделать подсказку на ячейках, к которые не поместился текст. }
  {TODO 1 -oVasilevSM : Горячие клавиши должны работать всегда, а не только когда контрол с менюхой в фокусе. }
  {TODO 1 -oVasilevSM : Проверить на утечки. }
  TfmMain = class(TForm)

    pCommon: TGridPanel;
    pRightSide: TGridPanel;
    pTasks: TPanel;
    pRunning: TPanel;
    pConsole: TPanel;

    lTasks: TLabel;
    lRunning: TLabel;
    lConsole: TLabel;

    sgTasks: TStringGrid;
    sgRunning: TStringGrid;
    mConsole: TMemo;

    pmTasks: TPopupMenu;
    miStart: TMenuItem;

    procedure FormCreate(Sender: TObject);
    procedure miStartClick(Sender: TObject);

  strict private

    procedure AdjustSizes;
    procedure FillTasks;
    procedure StartTask;

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

        Inc(RecNo);

        Objects[0, RecNo] := MKOTask;

        Cells[0, RecNo] := MKOTask.Intf.Caption;
        Cells[1, RecNo] := MKOTask.Intf.Description;

      end;

  end;

end;

procedure TfmMain.FormCreate(Sender: TObject);
begin

  AdjustSizes;
  TaskServices.LoadLibraries;
  FillTasks;

end;

procedure TfmMain.miStartClick(Sender: TObject);
begin
  StartTask;
end;

procedure TfmMain.StartTask;
var
  MKOTask: TObject;
  Params: String;
begin

  with sgTasks do
    MKOTask := Objects[0, Row];

  if not (MKOTask is TMKOTask) then
    raise EMKOTMException.Create('The object associated with this list item is not TMKOTask.');

  with TMKOTask(MKOTask).Intf do
  begin

    if InputText(

        SC_GET_TASK_PARAMS_FORM_CAPTION,
        Format(SC_GET_TASK_PARAMS_FORM_TEXT, [ParamsHelpText]),
        Params

    ) then
    begin

      ValidateParams(Params);
      Start(Params);

    end;

  end;

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
