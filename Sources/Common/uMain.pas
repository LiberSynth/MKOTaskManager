unit uMain;

interface

uses
  { VCL }
  System.Classes, Vcl.Forms, System.Types, Vcl.Controls, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Grids, System.Math, Vcl.Menus, System.SysUtils, System.DateUtils,
  Winapi.Windows, Vcl.Graphics,
  { Common }
  uStringGridHelper,
  { TM }
  uConsts, uCommon, uLibSupport, uInterfaces, uTypes, uGetTextForm, uUtils,
  System.ImageList, Vcl.ImgList;

type

  {TODO 3 -oVasilevSM : Сделать подсказку на ячейках, в которые не поместился текст. }
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
    ilTaskItems: TImageList;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure miStartClick(Sender: TObject);
    procedure sgTasksDblClick(Sender: TObject);
    procedure pmTaskItemsPopup(Sender: TObject);
    procedure miTerminateClick(Sender: TObject);
    procedure sgTaskItemsDrawCell(Sender: TObject; ACol, ARow: LongInt; Rect: TRect; State: TGridDrawState);
    procedure sgTaskItemsSelectCell(Sender: TObject; ACol, ARow: LongInt; var CanSelect: Boolean);

  strict private

    procedure Init;
    procedure InitGrids;
    procedure AdjustSizes;
    procedure FillTasks;
    procedure FillTaskItems;
    procedure RefreshTaskItem(_RecNo: Integer; _Item: TMKOTaskInstance);
    procedure RefreshConsole;
    procedure Finalize;
    procedure StartTask;
    procedure TerminateTask;

    procedure LocateTaskItems(_TaskInstance: TMKOTaskInstance);
    procedure TaskInstancesChanged;
    procedure TaskInstanceChanged(_Sender: TMKOTaskInstance);
    function FindTaskItem(_TaskItemObject: TObject; var _RecNo: Integer): Boolean;
    function CurrentTaskInstance: TMKOTaskInstance;
    function FindTaskInstance(_RecNo: Integer; var _Value: TMKOTaskInstance): Boolean;
    procedure DrawIndicatorCell(_RecNo: Integer; _Rect: TRect);
    function TaskInstanceStateImageIndex(_State: TTaskState): Integer;

  end;

var
  fmMain: TfmMain;

implementation

{$R *.dfm}

procedure TfmMain.DrawIndicatorCell(_RecNo: Integer; _Rect: TRect);
var
  TaskInstance: TMKOTaskInstance;
  Index: Integer;
begin

  with sgTaskItems.Canvas do
  begin

    Brush.Color := clWhite;
    FillRect(_Rect);

  end;

  if FindTaskInstance(_RecNo, TaskInstance) then
  begin

    Index := TaskInstanceStateImageIndex(TaskInstance.State);

    _Rect.Offset(

        (sgTaskItems.DefaultRowHeight - ilTaskItems.Height) div 2,
        (sgTaskItems.ColWidths[0] - ilTaskItems.Width) div 2

    );
    ilTaskItems.Draw(sgTaskItems.Canvas, _Rect.Left, _Rect.Top, Index);

  end;

end;

procedure TfmMain.RefreshConsole;
begin
  CurrentTaskInstance.PullData(mConsole.Lines);
end;

procedure TfmMain.RefreshTaskItem(_RecNo: Integer; _Item: TMKOTaskInstance);
begin

  with sgTaskItems do
  begin

    Cells[1, _RecNo] := _Item.Task.Intf.Caption;
    Cells[2, _RecNo] := _Item.Params;
    Cells[3, _RecNo] := _Item.State.ToString;
    Cells[5, _RecNo] := _Item.Date.ToString;

    { Чтобы иконка отрисовалась }
    sgTaskItems.Refresh;

  end;

end;

procedure TfmMain.FillTaskItems;
var
  Bookmark: TObject;
  RecNo: Integer;
  Item: TMKOTaskInstance;
begin

  with sgTaskItems do
  begin

    BeginUpdate;
    try

      Bookmark := Objects[0, Row];

      { Обновляем весь набор, подобно перезапросу данных целиком. }
      RowCount := 1;
      RowCount := Max(TaskServices.TaskInstances.Count + 1, 2);
      FixedRows := 1;

      RecNo := 0;
      for Item in TaskServices.TaskInstances do
      begin

        Inc(RecNo);

        Objects[0, RecNo] := Item;
        RefreshTaskItem(RecNo, Item);

      end;

      Locate(Bookmark, 0)

    finally
      EndUpdate;
    end;

  end;

  RefreshConsole;

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

procedure TfmMain.Finalize;
begin

  { Чтобы не забыть. }
  TaskServices.OnTaskInstancesChanged := nil;
  TaskServices.OnTaskInstanceChanged := nil;

end;

function TfmMain.FindTaskInstance(_RecNo: Integer; var _Value: TMKOTaskInstance): Boolean;
var
  TaskInstanceObject: TObject;
begin

  with sgTaskItems do
    TaskInstanceObject := Objects[0, _RecNo];

  Result := Assigned(TaskInstanceObject);

  if Result then
  begin

    if not (TaskInstanceObject is TMKOTaskInstance) then
      raise EMKOTMException.Create('The object associated with this list item is not TMKOTaskInstance.');

    _Value := TMKOTaskInstance(TaskInstanceObject);

  end;

end;

function TfmMain.FindTaskItem(_TaskItemObject: TObject; var _RecNo: Integer): Boolean;
var
  i: Integer;
begin

  with sgTaskItems do

    for i := 0 to RowCount - 1 do

      if Objects[0, i] = _TaskItemObject then
      begin

        _RecNo := i;
        Exit(True);

      end;

  Result := False;

end;

procedure TfmMain.FormCreate(Sender: TObject);
begin

  Init;
  TaskServices.LoadLibraries;
  FillTasks;

end;

procedure TfmMain.FormDestroy(Sender: TObject);
begin
  Finalize;
end;

function TfmMain.CurrentTaskInstance: TMKOTaskInstance;
var
  TaskInstanceObject: TObject;
begin

  with sgTaskItems do
    TaskInstanceObject := Objects[0, Row];

  if not (TaskInstanceObject is TMKOTaskInstance) then
    raise EMKOTMException.Create('The object associated with this list item is not TMKOTaskInstance.');

  Result := TMKOTaskInstance(TaskInstanceObject);

end;

procedure TfmMain.Init;
begin

  TaskServices.OnTaskInstancesChanged := TaskInstancesChanged;
  TaskServices.OnTaskInstanceChanged := TaskInstanceChanged;
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

    ColWidths[0] := DefaultRowHeight;
    ColWidths[1] := 200;
    ColWidths[2] := 300;
    ColWidths[3] := 200;
    ColWidths[4] := 200;

    Cells[1, 0] := SC_TASKS_ITEMS_COLUMN_0_CAPTION;
    Cells[2, 0] := SC_TASKS_ITEMS_COLUMN_1_CAPTION;
    Cells[3, 0] := SC_TASKS_ITEMS_COLUMN_2_CAPTION;
    Cells[4, 0] := SC_TASKS_ITEMS_COLUMN_3_CAPTION;

  end;

end;

procedure TfmMain.LocateTaskItems(_TaskInstance: TMKOTaskInstance);
var
  RecNo: Integer;
begin

  if FindTaskItem(_TaskInstance, RecNo) then
    sgTaskItems.Row := RecNo;

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

procedure TfmMain.sgTaskItemsDrawCell(Sender: TObject; ACol, ARow: LongInt; Rect: TRect; State: TGridDrawState);
begin

  if (ACol = 0) and (ARow > 0) then
    DrawIndicatorCell(ARow, Rect);

end;

procedure TfmMain.sgTaskItemsSelectCell(Sender: TObject; ACol, ARow: LongInt; var CanSelect: Boolean);
begin
  if ARow > 0 then
    RefreshConsole;
end;

procedure TfmMain.sgTasksDblClick(Sender: TObject);
begin
  miStart.Click;
end;

procedure TfmMain.StartTask;
var
  TaskObject: TObject;
  Task: TMKOTask;
  TaskInstance: TMKOTaskInstance;
  Params: String;
begin

  with sgTasks do
    TaskObject := Objects[0, Row];

  if not (TaskObject is TMKOTask) then
    raise EMKOTMException.Create('The object associated with this list item is not TMKOTask.');

  Task := TMKOTask(TaskObject);

  if InputText(

      SC_GET_TASK_PARAMS_FORM_CAPTION,
      Format(SC_GET_TASK_PARAMS_FORM_TEXT, [Task.Intf.ParamsHelpText]),
      Params

  ) then
  begin

    TaskInstance := Task.StartTask(Params);
    LocateTaskItems(TaskInstance);

  end;

end;

procedure TfmMain.TaskInstanceChanged(_Sender: TMKOTaskInstance);
var
  RecNo: Integer;
begin

  if FindTaskItem(_Sender, RecNo) then
    RefreshTaskItem(RecNo, _Sender);

  with sgTaskItems do
    if _Sender = Objects[0, Row] then
      RefreshConsole;

end;

procedure TfmMain.TaskInstancesChanged;
begin
  FillTaskItems;
end;

function TfmMain.TaskInstanceStateImageIndex(_State: TTaskState): Integer;
begin

  case _State of

    tsCreated:    Result := 0;
    tsProcessing: Result := 1;
    tsFinished:   Result := 2;
    tsCanceled:   Result := 3;
    tsError:      Result := 4;

  else
    raise Exception.Create('Complete this method.');
  end;

end;

procedure TfmMain.TerminateTask;
begin
  CurrentTaskInstance.Terminate;
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
