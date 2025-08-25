unit uMain;

interface

uses
  { VCL }
  System.Classes, Vcl.Forms, System.Types, Vcl.Controls, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Grids, System.Math, Vcl.Menus, System.SysUtils, System.DateUtils,
  Winapi.Windows, Vcl.Graphics, System.ImageList, Vcl.ImgList, Winapi.Messages,
  { Common }
  Common.uConsts, Common.uTypes, Common.uInterfaces, Common.uGetTextForm, Common.uLibSupport,
  { TM }
  uConsts, uCommon, uUtils;

type

  {TODO 1 -oVasilevSM : Проверить на утечки фастмемом. }
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
    sbState: TStatusBar;

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
    procedure RefreshTaskItem(_RecNo: Integer; _Item: TMKOTaskItem);
    procedure RefreshConsole(_Item: TMKOTaskItem; _FullRefresh: Boolean);
    procedure RefreshProgress(_Item: TMKOTaskItem);
    procedure RefreshStatusBar;
    procedure Finalize;
    procedure StartTask;
    procedure TerminateTask;
    function InputTaskParams(_Task: TMKOTask; var _Params: IMKOTaskParams): Boolean;

    procedure TaskItemListChanged;
    procedure TaskItemChanged(_Item: TMKOTaskItem);
    procedure TaskItemSendData(_Item: TMKOTaskItem);
    procedure TaskItemSendProgress(_Item: TMKOTaskItem);
    function TaskItemsRowChanged: Boolean;
    function TryGetCurrentTask(var _Value: TMKOTask): Boolean;
    function FindTaskItemIndex(_ItemObject: TObject; var _Row: Integer): Boolean;
    function FindTaskItem(_Row: Integer; var _Item: TMKOTaskItem): Boolean;
    function TryGetCurrentTaskItem(var _Item: TMKOTaskItem): Boolean;
    procedure DrawIndicatorCell(_RecNo: Integer; _Rect: TRect);
    function TaskStateImageIndex(_State: TTaskState): Integer;
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
  Item: TMKOTaskItem;
  Index: Integer;
begin

  with sgTaskItems, Canvas do
  begin

    Brush.Color := clWhite;
    FillRect(_Rect);

    if FindTaskItem(_RecNo, Item) then
    begin

      Index := TaskStateImageIndex(Item.State);

      _Rect.Offset(

          (DefaultRowHeight - ilTaskItems.Height) div 2,
          (ColWidths[0] - ilTaskItems.Width) div 2

      );
      ilTaskItems.Draw(Canvas, _Rect.Left, _Rect.Top, Index);

    end;

  end;

end;

procedure TfmMain.RefreshConsole(_Item: TMKOTaskItem; _FullRefresh: Boolean);
var
  Data: String;
begin

  _Item.PullData(Data);

  with mConsole, Lines do
  begin

    LockDrawing;
    try

      BeginUpdate;
      try

        if _FullRefresh then
          Clear;

        Text := Data;

      finally
        EndUpdate;
      end;

    finally
      UnlockDrawing;
    end;

  end;

end;

procedure TfmMain.RefreshProgress(_Item: TMKOTaskItem);
var
  Progress: Integer;
begin

  _Item.PullProgress(Progress);

  with pbProgress do
    if Position <> Progress then
      Position := Progress;

end;

procedure TfmMain.RefreshStatusBar;
begin

  with TaskServices.TaskItems do

    sbState.Panels[0].Text := Format(SC_TASK_SUMMARY, [

        Count,
        StateCount(SS_TASK_STARTED_STATES),
        StateCount(tsFinished)

    ]);

end;

procedure TfmMain.RefreshTaskItem(_RecNo: Integer; _Item: TMKOTaskItem);
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
        if CompareDateTime(_Item.CreatePoint, 0) <> EqualsValue then
          Cells[4, _RecNo] := _Item.CreatePoint.ToString;
        if CompareDateTime(_Item.CompletePoint, 0) <> EqualsValue then
          Cells[5, _RecNo] := _Item.CompletePoint.ToString;

      finally
        EndUpdate;
      end;

    finally
      UnlockDrawing;
    end;

    { Чтобы иконка отрисовалась }
    sgTaskItems.Refresh;

  end;

  RefreshStatusBar;

end;

procedure TfmMain.RefreshTaskItemList;
var
  RecNo: Integer;
  Item: TMKOTaskItem;
begin

  with sgTaskItems do
  begin

    LockDrawing;
    try

      BeginUpdate;
      try

        { Обновляем весь набор, подобно перезапросу данных целиком. }
        RowCount := 1;
        RowCount := Max(TaskServices.TaskItems.Count + 1, 2);
        FixedRows := 1;

        RecNo := 0;
        for Item in TaskServices.TaskItems do
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

  if TryGetCurrentTaskItem(Item) then
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
          Cells[1, RecNo] := MKOTask.Intf.Name;
          Cells[2, RecNo] := MKOTask.Intf.Description;

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
  TaskServices.OnSendProgress := nil;

end;

function TfmMain.FindTaskItem(_Row: Integer; var _Item: TMKOTaskItem): Boolean;
var
  ItemObject: TObject;
begin

  if _Row = 0 then
    Exit(False);

  ItemObject := sgTaskItems.Objects[0, _Row];

  Result := Assigned(ItemObject);

  if Result then
  begin

    if not (ItemObject is TMKOTaskItem) then
      raise EMKOTMException.Create('The object associated with this list item is not TMKOTaskItem.');

    _Item := TMKOTaskItem(ItemObject);

  end;

end;

function TfmMain.FindTaskItemIndex(_ItemObject: TObject; var _Row: Integer): Boolean;
var
  i: Integer;
begin

  with sgTaskItems do

    for i := 0 to RowCount - 1 do

      if Objects[0, i] = _ItemObject then
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

  with TaskServices do
  begin

    OnTaskInstanceListChanged := TaskItemListChanged;
    OnTaskInstanceChanged := TaskItemChanged;
    OnSendData := TaskItemSendData;
    OnSendProgress := TaskItemSendProgress;

  end;

  InitGrids;
  AdjustSizes;

end;

procedure TfmMain.InitGrids;
begin

  with sgTasks do
  begin

    ColWidths[0] := 150;
    ColWidths[1] := 120;
    ColWidths[2] := 500;

    Cells[0, 0] := SC_TASKS_COLUMN_0_CAPTION;
    Cells[1, 0] := SC_TASKS_COLUMN_1_CAPTION;
    Cells[2, 0] := SC_TASKS_COLUMN_2_CAPTION;

  end;

  with sgTaskItems do
  begin

    ColWidths[0] := DefaultRowHeight;
    ColWidths[1] := 180;
    ColWidths[2] := 300;
    ColWidths[3] := 85;
    ColWidths[4] := 110;
    ColWidths[5] := 110;

    Cells[1, 0] := SC_TASKS_ITEMS_COLUMN_1_CAPTION;
    Cells[2, 0] := SC_TASKS_ITEMS_COLUMN_2_CAPTION;
    Cells[3, 0] := SC_TASKS_ITEMS_COLUMN_3_CAPTION;
    Cells[4, 0] := SC_TASKS_ITEMS_COLUMN_4_CAPTION;
    Cells[5, 0] := SC_TASKS_ITEMS_COLUMN_5_CAPTION;

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
  ParamString := '*.pas' + CRLF + 'C:\WorkTP';
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
  Item: TMKOTaskItem;
begin

  miTerminate.Enabled :=

      TryGetCurrentTaskItem(Item) and
      (Item.State = tsProcessing);

end;

procedure TfmMain.pmTasksPopup(Sender: TObject);
var
  Task: TMKOTask;
begin
  miStart.Enabled := TryGetCurrentTask(Task);
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
  Item: TMKOTaskItem;
begin

  if

      not sgTaskItems.IsUpdating and
      (ARow > 0) and
      TaskItemsRowChanged and
      TryGetCurrentTaskItem(Item)

  then RefreshConsole(Item, True);

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

procedure TfmMain.TaskItemChanged(_Item: TMKOTaskItem);
var
  Row: Integer;
begin

  if FindTaskItemIndex(_Item, Row) then
    RefreshTaskItem(Row, _Item);

end;

procedure TfmMain.TaskItemSendData(_Item: TMKOTaskItem);
var
  Row: Integer;
begin

  if

      FindTaskItemIndex(_Item, Row) and
      (Row = sgTaskItems.Row)

  then RefreshConsole(_Item, False);

end;

procedure TfmMain.TaskItemSendProgress(_Item: TMKOTaskItem);
var
  Row: Integer;
begin

  if

      FindTaskItemIndex(_Item, Row) and
      (Row = sgTaskItems.Row)

  then RefreshProgress(_Item);

end;

procedure TfmMain.TaskItemListChanged;
begin
  RefreshTaskItemList;
end;

function TfmMain.TaskStateImageIndex(_State: TTaskState): Integer;
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
  Item: TMKOTaskItem;
begin
  if TryGetCurrentTaskItem(Item) and (Item.State = tsProcessing) then
    Item.Terminate;
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

function TfmMain.TryGetCurrentTaskItem(var _Item: TMKOTaskItem): Boolean;
begin

  with sgTaskItems do
  begin

    Result :=

        (Row > 0) and
        (Objects[0, Row] is TMKOTaskItem);

    if Result then
      _Item := TMKOTaskItem(Objects[0, Row]);

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
