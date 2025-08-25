unit uMain;

interface

uses
  { VCL }
  System.Classes, Vcl.Forms, System.Types, Vcl.Controls, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Grids, System.Math, Vcl.Menus, System.SysUtils, System.DateUtils,
  Winapi.Windows, Vcl.Graphics, System.ImageList, Vcl.ImgList, Winapi.Messages,
  { Common }
  uStringGridHelper,
  { TM }
  uConsts, uCommon, uLibSupport, uInterfaces, uTypes, uGetTextForm, uUtils, Common.uConsts;

type

  {TODO 1 -oVasilevSM : ѕроверить на утечки фастмемом. }
  {TODO 4 -oVasilevSM : TO TRIM ALL UNITS IN PROJECT. }
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
    pbProgress: TProgressBar;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure pmTasksPopup(Sender: TObject);
    procedure miStartClick(Sender: TObject);
    procedure pmTaskItemsPopup(Sender: TObject);
    procedure miTerminateClick(Sender: TObject);
    procedure sgTaskItemsSelectCell(Sender: TObject; ACol, ARow: LongInt; var CanSelect: Boolean);
    procedure sgTasksDblClick(Sender: TObject);
    procedure sgTasksMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure sgTaskItemsDrawCell(Sender: TObject; ACol, ARow: LongInt; Rect: TRect; State: TGridDrawState);

  strict private

    FTaskItemsRow: Integer;

    procedure Init;
    procedure InitGrids;
    procedure AdjustSizes;
    procedure RefreshTasks;
    procedure RefreshTaskItemList;
    procedure RefreshTaskItem(_RecNo: Integer; _Item: TMKOTaskInstance);
    procedure RefreshConsole(_Instance: TMKOTaskInstance; _FullRefresh: Boolean);
    procedure Finalize;
    procedure StartTask;
    procedure TerminateTask;
    function InputTaskParams(_Task: TMKOTask; var _Params: IMKOTaskParams): Boolean;

    procedure TaskInstanceListChanged;
    procedure TaskInstanceChanged(_Instance: TMKOTaskInstance);
    procedure TaskInstanceSendData(_Instance: TMKOTaskInstance);
    function TaskItemsRowChanged: Boolean;
    function FindTaskItemIndex(_TaskItemObject: TObject; var _Row: Integer): Boolean;
    function TryGetCurrentTask(var _Value: TMKOTask): Boolean;
    function FindTaskInstance(_Row: Integer; var _Value: TMKOTaskInstance): Boolean;
    function TryGetCurrentTaskInstance(var _Value: TMKOTaskInstance): Boolean;
    procedure DrawIndicatorCell(_RecNo: Integer; _Rect: TRect);
    function TaskInstanceStateImageIndex(_State: TTaskState): Integer;
    procedure ProcessShortCut(_ShortCut: TShortCut);
    function InputParamsDialogText(_Task: TMKOTask): String;

    property TaskItemsRow: Integer read FTaskItemsRow;

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

  with sgTaskItems, Canvas do
  begin

    Brush.Color := clWhite;
    FillRect(_Rect);

    if FindTaskInstance(_RecNo, TaskInstance) then
    begin

      Index := TaskInstanceStateImageIndex(TaskInstance.State);

      _Rect.Offset(

          (DefaultRowHeight - ilTaskItems.Height) div 2,
          (ColWidths[0] - ilTaskItems.Width) div 2

      );
      ilTaskItems.Draw(Canvas, _Rect.Left, _Rect.Top, Index);

    end;

  end;

end;

procedure TfmMain.RefreshConsole(_Instance: TMKOTaskInstance; _FullRefresh: Boolean);
var
  Progress: Integer;
begin

  with mConsole do
  begin

    LockDrawing;
    try

      if _FullRefresh then
        Clear;

      {TODO 1 -oVasilevSM : Ќужно придумать что-то получше. ¬о-первых, последние сообщени€ сверху,
        а не в конце, потому что EM_LINESCROLL тоже заваливает очередь. », наверное, нужно показывать
        ограниченную часть сообщений, а остальное сохран€ть в логи из потоков. ј здесь добавить команду
        "ѕоказать целиком" и делать ее доступной только после завершени€ задачи. » читать по ней весь лог. }
      _Instance.PullData(Lines, Progress);

      with pbProgress do
        if Position <> Progress then
          Position := Progress;

    finally
      UnlockDrawing;
    end;

    SendMessage(Handle, EM_LINESCROLL, 0, Lines.Count);

  end;

end;

procedure TfmMain.RefreshTaskItem(_RecNo: Integer; _Item: TMKOTaskInstance);
begin

  with sgTaskItems do
  begin

    LockDrawing;
    try

      BeginUpdate;
      try

        Cells[1, _RecNo] := _Item.Task.Intf.Caption;
        Cells[2, _RecNo] := _Item.Params.ToString;
        Cells[3, _RecNo] := _Item.State.ToString;
        Cells[4, _RecNo] := _Item.Date.ToString;

      finally
        EndUpdate;
      end;

    finally
      UnlockDrawing;
    end;

    { „тобы иконка отрисовалась }
    sgTaskItems.Refresh;

  end;

end;

procedure TfmMain.RefreshTaskItemList;
var
  RecNo: Integer;
  Item: TMKOTaskInstance;
begin

  with sgTaskItems do
  begin

    LockDrawing;
    try

      BeginUpdate;
      try

        { ќбновл€ем весь набор, подобно перезапросу данных целиком. }
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

      finally
        EndUpdate;
      end;

    finally
      UnlockDrawing;
    end;

  end;

  if TryGetCurrentTaskInstance(Item) then
    RefreshConsole(Item, True);

end;

procedure TfmMain.RefreshTasks;
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

  TaskServices.OnTaskInstanceListChanged := nil;
  TaskServices.OnTaskInstanceChanged := nil;
  TaskServices.OnSendData := nil;

end;

function TfmMain.FindTaskInstance(_Row: Integer; var _Value: TMKOTaskInstance): Boolean;
var
  TaskInstanceObject: TObject;
begin

  if _Row = 0 then
    Exit(False);

  TaskInstanceObject := sgTaskItems.Objects[0, _Row];

  Result := Assigned(TaskInstanceObject);

  if Result then
  begin

    if not (TaskInstanceObject is TMKOTaskInstance) then
      raise EMKOTMException.Create('The object associated with this list item is not TMKOTaskInstance.');

    _Value := TMKOTaskInstance(TaskInstanceObject);

  end;

end;

function TfmMain.FindTaskItemIndex(_TaskItemObject: TObject; var _Row: Integer): Boolean;
var
  i: Integer;
begin

  with sgTaskItems do

    for i := 0 to RowCount - 1 do

      if Objects[0, i] = _TaskItemObject then
      begin

        _Row := i;
        Exit(True);

      end;

  Result := False;

end;

procedure TfmMain.FormCreate(Sender: TObject);
begin

  Init;
  TaskServices.LoadLibraries;
  RefreshTasks;

end;

procedure TfmMain.FormDestroy(Sender: TObject);
begin
  Finalize;
end;

procedure TfmMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  ProcessShortCut(ShortCut(Key, Shift));
end;

procedure TfmMain.Init;
begin

  TaskServices.OnTaskInstanceListChanged := TaskInstanceListChanged;
  TaskServices.OnTaskInstanceChanged := TaskInstanceChanged;
  TaskServices.OnSendData := TaskInstanceSendData;
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
    ColWidths[3] := 85;
    ColWidths[4] := 110;

    Cells[1, 0] := SC_TASKS_ITEMS_COLUMN_0_CAPTION;
    Cells[2, 0] := SC_TASKS_ITEMS_COLUMN_1_CAPTION;
    Cells[3, 0] := SC_TASKS_ITEMS_COLUMN_2_CAPTION;
    Cells[4, 0] := SC_TASKS_ITEMS_COLUMN_3_CAPTION;

  end;

end;

function TfmMain.InputParamsDialogText(_Task: TMKOTask): String;
begin

  Result := SC_GET_TASK_PARAMS_FORM_TEXT;
  if Length(_Task.Intf.ParamsHelpText) > 0 then
    Result := Format('%s' + CRLFx2 + '%s', [Result, _Task.Intf.ParamsHelpText]);

end;

function TfmMain.InputTaskParams(_Task: TMKOTask; var _Params: IMKOTaskParams): Boolean;
var
  ParamString: String;
begin

  ParamString := '';
  {$IFDEF DEBUG}
  ParamString := '12' + CRLF + 'C:\WorkMKO\_out\Win32\Debug\MKOTaskManager.exe';
  {$ENDIF}

  Result := False;
  repeat

    if not InputText(

        SC_GET_TASK_PARAMS_FORM_CAPTION,
        InputParamsDialogText(_Task),
        ParamString

    ) then Break;

    _Params := TMKOTaskParams.Create(ParamString);
    try

      Result := _Task.ValidateParams(_Params);

      if not Result then
      begin

        if Length(_Params.ErrorMessage) = 0 then
          raise EMKOTMException.Create(SC_EMPTY_TASK_PARAMS_ERROR_MESSAGE);

        MessageBox(SC_MESSAGE_BOX_ERROR_CAPTION, _Params.ErrorMessage, MB_OK, MB_ICONERROR);

      end;

    finally
      if not Result then
        _Params := nil;
    end;

  until Result;

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
var
  TaskItem: TMKOTaskInstance;
begin

  with sgTaskItems do

    miTerminate.Enabled :=

        (Row >= 1) and
        TryGetCurrentTaskInstance(TaskItem) and
        (TaskItem.State = tsProcessing);

end;

procedure TfmMain.pmTasksPopup(Sender: TObject);
var
  Task: TMKOTask;
begin

  with sgTaskItems do

    miStart.Enabled :=

        (Row >= 1) and
        TryGetCurrentTask(Task);

end;

procedure TfmMain.ProcessShortCut(_ShortCut: TShortCut);

  function _CheckMenu(_MenuItem: TMenuItem): Boolean;
  var
    i: Integer;
  begin

    if

        (_MenuItem.ShortCut = _ShortCut) and
      _MenuItem.Visible and
      _MenuItem.Enabled

    then
    begin

      _MenuItem.Click;
      Exit(True);

    end;

    for i := 0 to _MenuItem.Count - 1 do
      if _CheckMenu(_MenuItem[i]) then
        Exit(True);

    Result := False;

  end;

var
  i: Integer;
  Component: TComponent;
begin

  for i := 0 to ComponentCount - 1 do
  begin

    Component := Components[i];
    if

        (Component is TPopupMenu) and
        _CheckMenu(TPopupMenu(Component).Items)

    then Exit;

  end;

end;

procedure TfmMain.sgTaskItemsDrawCell(Sender: TObject; ACol, ARow: LongInt; Rect: TRect; State: TGridDrawState);
begin

  if (ACol = 0) and (ARow > 0) then
    DrawIndicatorCell(ARow, Rect);

end;

procedure TfmMain.sgTaskItemsSelectCell(Sender: TObject; ACol, ARow: LongInt; var CanSelect: Boolean);
var
  TaskInstance: TMKOTaskInstance;
begin

  if

      not sgTaskItems.IsUpdating and
      (ARow > 0) and
      TaskItemsRowChanged and
      TryGetCurrentTaskInstance(TaskInstance)

  then RefreshConsole(TaskInstance, True);

end;

procedure TfmMain.sgTasksDblClick(Sender: TObject);
begin
  miStart.Click;
end;

procedure TfmMain.sgTasksMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin

  if Button = mbRight then
    with Sender as TStringGrid, MouseCoord(X, Y) do
      if Y > -1 then
        Row := Y;

end;

procedure TfmMain.StartTask;
var
  Task: TMKOTask;
  Params: IMKOTaskParams;
begin

  if not TryGetCurrentTask(Task) then
    raise Exception.Create('Something''s going wrong.');

  if InputTaskParams(Task, Params) then
  begin

    Task.StartTask(Params);
    mConsole.Clear;

  end;

end;

procedure TfmMain.TaskInstanceChanged(_Instance: TMKOTaskInstance);
var
  Row: Integer;
begin

  if FindTaskItemIndex(_Instance, Row) then
    RefreshTaskItem(Row, _Instance);

end;

procedure TfmMain.TaskInstanceSendData(_Instance: TMKOTaskInstance);
var
  Row: Integer;
begin

  if

      FindTaskItemIndex(_Instance, Row) and
      (Row = sgTaskItems.Row)

  then RefreshConsole(_Instance, False);

end;

procedure TfmMain.TaskInstanceListChanged;
begin
  RefreshTaskItemList;
end;

function TfmMain.TaskInstanceStateImageIndex(_State: TTaskState): Integer;
const
  AA_MAP: array[TTaskState] of Byte = (0, 1, 2, 3, 4, 5);
begin
  Result := AA_MAP[_State];
end;

function TfmMain.TaskItemsRowChanged: Boolean;
begin

  Result := sgTaskItems.Row <> TaskItemsRow;
  if Result then
    FTaskItemsRow := sgTaskItems.Row;

end;

procedure TfmMain.TerminateTask;
var
  TaskInstance: TMKOTaskInstance;
begin
  if TryGetCurrentTaskInstance(TaskInstance) and (TaskInstance.State = tsProcessing) then
    TaskInstance.Terminate;
end;

function TfmMain.TryGetCurrentTask(var _Value: TMKOTask): Boolean;
begin

  with sgTasks do
  begin

    Result :=

        (Row > 0) and
        (Objects[0, Row] is TMKOTask);

    if Result then
      _Value := TMKOTask(Objects[0, Row]);

  end;

end;

function TfmMain.TryGetCurrentTaskInstance(var _Value: TMKOTaskInstance): Boolean;
begin

  with sgTaskItems do
  begin

    Result :=

        (Row > 0) and
        (Objects[0, Row] is TMKOTaskInstance);

    if Result then
      _Value := TMKOTaskInstance(Objects[0, Row]);

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
