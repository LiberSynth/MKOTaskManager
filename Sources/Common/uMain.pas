unit uMain;

interface

uses
  { VCL }
  System.Classes, Vcl.Forms, System.Types, Vcl.Controls, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Grids, System.Math, Vcl.Menus, System.SysUtils, System.DateUtils,
  { Common }
  uStringGridHelper,
  { TM }
  uConsts, uCommon, uLibSupport, uInterfaces, uTypes, uGetTextForm, uUtils;

type

  {TODO 3 -oVasilevSM : Сделать подсказку на ячейках, в которые не поместился текст. }
  {TODO 3 -oVasilevSM : Зачем в задачах заголовки столбцов выделяются? }
  {TODO 3 -oVasilevSM : Возможно, текущие задачи надо добавлять в начало списка, чтобы сверху были последние. }
  {TODO 2 -oVasilevSM : Горячие клавиши должны работать всегда, а не только когда контрол с менюхой в фокусе. }
  {TODO 1 -oVasilevSM : Добавить оболочку для исключений из библиотек. }
  {TODO 1 -oVasilevSM : Проверить на утечки фастмемом. }
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
    sgTaskItems: TStringGrid;
    mConsole: TMemo;

    pmTasks: TPopupMenu;
    miStart: TMenuItem;
    pmTaskItems: TPopupMenu;
    miTerminate: TMenuItem;

    procedure FormCreate(Sender: TObject);
    procedure miStartClick(Sender: TObject);
    procedure sgTasksDblClick(Sender: TObject);
    procedure pmTaskItemsPopup(Sender: TObject);
    procedure miTerminateClick(Sender: TObject);

  strict private

    procedure Init;
    procedure InitGrids;
    procedure AdjustSizes;
    procedure FillTasks;
    procedure FillTaskItems;
    procedure StartTask;
    procedure TerminateTask;

    procedure TaskInstancesChanged;

  end;

var
  fmMain: TfmMain;

implementation

{$R *.dfm}

procedure TfmMain.FillTaskItems;
var
  Bookmark: TObject;
  RecNo: Integer;
  MKOTaskItem: TMKOTaskInstance;
begin

  with sgTaskItems do
  begin

    BeginUpdate;
    try

      Bookmark := Objects[0, Row];

      { Обновляем весь набор, подобно перезапросу данных целиком. }
      RowCount := 1;
      RowCount := Max(TaskServices.TaskInstances.Count + 1, 2);
      RecNo := 0;

      for MKOTaskItem in TaskServices.TaskInstances do
      begin

        Inc(RecNo);

        Objects[0, RecNo] := MKOTaskItem;

        Cells[0, RecNo] := MKOTaskItem.Task.Intf.Caption;
        Cells[1, RecNo] := MKOTaskItem.Params;
        Cells[2, RecNo] := MKOTaskItem.State.ToStr;
        Cells[3, RecNo] := MKOTaskItem.Date.ToString;

      end;

      if Assigned(Bookmark) then
        Locate(Bookmark, 0);

    finally
      EndUpdate;
    end;

  end;

end;

procedure TfmMain.FillTasks;
var
  RecNo: Integer;
  MKOLibrary: TMKOLibrary;
  MKOTask: TMKOTask;
begin

  with sgTasks do
  begin

    BeginUpdate;
    try

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

    finally
      EndUpdate;
    end;

  end;

end;

procedure TfmMain.FormCreate(Sender: TObject);
begin

  Init;
  TaskServices.LoadLibraries;
  FillTasks;

end;

procedure TfmMain.Init;
begin

  TaskServices.OnTaskInstancesChanged := TaskInstancesChanged;
  InitGrids;
  AdjustSizes;

end;

procedure TfmMain.InitGrids;
begin

  with sgTasks do
  begin

    ColWidths[0] := 200;
    ColWidths[1] := 500;

    Cells[0, 0] := SC_TASKS_COLUMN_0_CAPTION;
    Cells[1, 0] := SC_TASKS_COLUMN_1_CAPTION;

  end;

  with sgTaskItems do
  begin

    ColWidths[0] := 200;
    ColWidths[1] := 300;
    ColWidths[2] := 200;
    ColWidths[3] := 200;

    Cells[0, 0] := SC_TASKS_ITEMS_COLUMN_0_CAPTION;
    Cells[1, 0] := SC_TASKS_ITEMS_COLUMN_1_CAPTION;
    Cells[2, 0] := SC_TASKS_ITEMS_COLUMN_2_CAPTION;
    Cells[3, 0] := SC_TASKS_ITEMS_COLUMN_3_CAPTION;

  end;

end;

procedure TfmMain.miStartClick(Sender: TObject);
begin
  StartTask;
end;

procedure TfmMain.miTerminateClick(Sender: TObject);
begin
  TerminateTask;
end;

procedure TfmMain.pmTaskItemsPopup(Sender: TObject);
begin

  with sgTaskItems do

    miTerminate.Enabled :=

        (Row >= 1) and
        Assigned(Objects[0, Row]);

end;

procedure TfmMain.sgTasksDblClick(Sender: TObject);
begin
  miStart.Click;
end;

procedure TfmMain.StartTask;
var
  TaskObject: TObject;
  MKOTask: TMKOTask;
  Params: String;
begin

  with sgTasks do
    TaskObject := Objects[0, Row];

  if not (TaskObject is TMKOTask) then
    raise EMKOTMException.Create('The object associated with this list item is not TMKOTask.');

  MKOTask := TMKOTask(TaskObject);

  if InputText(

      SC_GET_TASK_PARAMS_FORM_CAPTION,
      Format(SC_GET_TASK_PARAMS_FORM_TEXT, [MKOTask.Intf.ParamsHelpText]),
      Params

  ) then

    MKOTask.StartTask(Params);

end;

procedure TfmMain.TaskInstancesChanged;
begin
  FillTaskItems;
end;

procedure TfmMain.TerminateTask;
var
  TaskInstanceObject: TObject;
begin

  with sgTaskItems do
    TaskInstanceObject := Objects[0, Row];

  if not (TaskInstanceObject is TMKOTaskInstance) then
    raise EMKOTMException.Create('The object associated with this list item is not TMKOTaskInstance.');

  TMKOTaskInstance(TaskInstanceObject).Terminate;

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
