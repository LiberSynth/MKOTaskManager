unit uLibSupport;

interface

uses
  { VCL }
  System.SysUtils, Generics.Collections, Winapi.Windows, System.SyncObjs, System.Classes,
  Winapi.Messages, System.DateUtils,
  { Common }
  Common.uConsts, Common.uTypes, Common.uUtils, Common.uInterfaces, Common.uFileExplorer,
  Common.uFileUtils,
  { TM }
  uUtils, uThread, uConsts;

type

  TTaskState = (tsCreated, tsWaiting, tsProcessing, tsFinished, tsCanceled, tsError);
  TTaskStates = set of TTaskState;

const

  SS_TASK_STARTED_STATES = [tsCreated, tsWaiting, tsProcessing];
  SS_TASK_FINAL_STATES   = [tsFinished, tsCanceled, tsError];

type

  TTaskStateHelper = record helper for TTaskState

  public

    function ToString: String;
    function Report: String;

  end;

  TMKOTask = class;

  TMKOTaskItem = class

  strict private type

    TOutputIntf = class(TInterfacedObject, IMKOTaskOutput)

    strict private

      FTaskItem: TMKOTaskItem;

      { IMKOTaskOutput }
      procedure WriteOut(const _Value: WideString; _Progress: Integer); safecall;

      property TaskItem: TMKOTaskItem read FTaskItem;

    private

      constructor Create(_Item: TMKOTaskItem); reintroduce;

    end;

  strict private

    FTask: TMKOTask;
    FIntf: IMKOTaskInstance;
    FThread: TMKOTaskThread;
    FParams: IMKOTaskParams;
    FWndHandle: HWND;
    FState: TTaskState;
    FData: String;
    FDataChanged: Boolean;
    FDataPosted: Boolean;
    FLastPostPoint: Cardinal;
    FProgress: Integer;
    FCreatePoint: TDateTime;
    FCompletePoint: TDateTime;
    FLogFile: String;
    FStateLocker: TCriticalSection;
    FDataLocker: TCriticalSection;
    FProgressLocker: TCriticalSection;

    function GetState: TTaskState;
    procedure SetState(const _Value: TTaskState);

    procedure CreateThread;
    procedure ThreadBeforeExecute;
    procedure ThreadAfterExecute(_ErrorOccured: Boolean);
    procedure ThreadOnTerminate(_Sender: TObject);
    function CanStart: Boolean;
    procedure DoChanged;
    procedure DoSendData(_Assured: Boolean);
    procedure DoSendProgress;
    procedure SaveToLog;

    property Intf: IMKOTaskInstance read FIntf;
    property Thread: TMKOTaskThread read FThread;
    property StateLocker: TCriticalSection read FStateLocker;
    property DataLocker: TCriticalSection read FDataLocker;
    property ProgressLocker: TCriticalSection read FProgressLocker;
    property WndHandle: HWND read FWndHandle;
    property DataChanged: Boolean read FDataChanged;
    property DataPosted: Boolean read FDataPosted;
    property LastPostPoint: Cardinal read FLastPostPoint write FLastPostPoint;
    property LogFile: String read FLogFile;

  private

    constructor Create(

        _MKOTask: TMKOTask;
        const _Params: IMKOTaskParams;
        _WndHandle: HWND

    ); reintroduce;

    procedure StartThread;
    procedure CompleteTaskProcessing;

    { Многопоточный метод }
    procedure WriteOut(const _Value: WideString; _Progress: Integer; _Assured: Boolean = False);

  public

    destructor Destroy; override;

    procedure Terminate;

    property Task: TMKOTask read FTask;
    property Params: IMKOTaskParams read FParams;
    property CreatePoint: TDateTime read FCreatePoint;
    property CompletePoint: TDateTime read FCompletePoint;

    { Многопоточные методы }
    procedure PullData(var _Target: String);
    procedure PullProgress(var _Progress: Integer);

    { Многопоточное свойство }
    property State: TTaskState read GetState write SetState;

  end;

  TMKOTaskItemList = class(TList<TMKOTaskItem>)

  private

    function StateFind(_State: TTaskState; var _Item: TMKOTaskItem): Boolean;

  public

    function StateCount(_State: TTaskState): Integer; overload;
    function StateCount(_States: TTaskStates): Integer; overload;

  end;

  TMKOTaskParams = class(TInterfacedObject, IMKOTaskParams)

  strict private

    FList: TStringList;
    FErrorMessage: String;

    { IMKOTaskParams }
    function GetItems(_Index: Integer): WideString; safecall;
    procedure SetItems(_Index: Integer; const _Value: WideString); safecall;
    function GetCount: Integer; safecall;
    function GetErrorMessage: WideString; safecall;
    procedure SetErrorMessage(const _Value: WideString); safecall;
    procedure Delete(_Index: Integer); safecall;
    function ToString: WideString; reintroduce; safecall;

    property List: TStringList read FList;

  public

    constructor Create(const _Params: String); reintroduce;
    destructor Destroy; override;

  end;

  TMKOTask = class

  strict private

    FIntf: IMKOTask;

    procedure TrimParams(const _Params: IMKOTaskParams);

  public

    constructor Create(const _Intf: IMKOTask); reintroduce;

    function ValidateParams(const _Params: IMKOTaskParams): Boolean;
    function StartTask(const _Params: IMKOTaskParams): TMKOTaskItem;

    property Intf: IMKOTask read FIntf;

  end;

  TMKOTaskList = class(TObjectList<TMKOTask>)

  private

    function Contains(const _TaskName: String): Boolean; overload;

  end;

  TMKOLibraryIntf = class(TInterfacedObject, IMKOTaskLibrary)

  strict private

    FTasks: TMKOTaskList;

    { IMKOTaskLibrary }
    procedure RegisterTask(_MKOTask: IMKOTask); safecall;

    property Tasks: TMKOTaskList read FTasks;

  private

    constructor Create(_Tasks: TMKOTaskList); reintroduce;

  end;

  TMKOLibrary = class

  strict private type

    TMKOTaskLibraryMarkerProc = procedure; safecall;
    TMKOInitLibraryProc       = procedure(_MKOTaskLibrary: IMKOTaskLibrary); safecall;
    TFinLibraryProc           = procedure; safecall;

  strict private

    FHandle: THandle;
    FFinProc: TFinLibraryProc;
    FTasks: TMKOTaskList;

  private

    constructor Create; reintroduce;

    function Load(const _File: String): Boolean;
    procedure Finalize;

    property Handle: THandle read FHandle write FHandle;
    property FinProc: TFinLibraryProc read FFinProc write FFinProc;

  public

    destructor Destroy; override;

    property Tasks: TMKOTaskList read FTasks;

  end;

  TMKOLibraryList = class(TObjectList<TMKOLibrary>);

  TMKOTaskServices = class

  strict private type

    TTaskInstanceListChangedProc = procedure of object;
    TOnTaskInstanceProc = procedure(_Item: TMKOTaskItem) of object;

  strict private

    class var FInstance: TMKOTaskServices;
    class var FFinalized: Boolean;

    class property Finalized: Boolean read FFinalized;

  strict private

    FWndHandle: HWND;
    FLibraries: TMKOLibraryList;
    FTaskItems: TMKOTaskItemList;
    FOnTaskInstanceListChanged: TTaskInstanceListChangedProc;
    FOnTaskInstanceChanged: TOnTaskInstanceProc;
    FOnSendData: TOnTaskInstanceProc;
    FOnSendProgress: TOnTaskInstanceProc;

    function GetTaskCount: Integer;

    procedure LoadLibrary(const _File: String);
    procedure MessageProc(var _Message: TMessage);
    procedure DoOnTaskInstanceListChanged;
    procedure DoOnTaskItemChanged(_Item: TMKOTaskItem);
    procedure DoOnSendData(_Item: TMKOTaskItem);
    procedure DoOnSendProgress(_Item: TMKOTaskItem);

    property WndHandle: HWND read FWndHandle;

  private

    constructor Create;

    class function Instance: TMKOTaskServices;
    class procedure Finalize;

    procedure FinalizeLibraries;
    procedure FinalizeTaskInstances;

    procedure CheckWaiting;

    function AddTaskInstance(_MKOTask: TMKOTask; const _Params: IMKOTaskParams): TMKOTaskItem;

  public

    destructor Destroy; override;

    procedure LoadLibraries;

    property Libraries: TMKOLibraryList read FLibraries;
    property TaskItems: TMKOTaskItemList read FTaskItems;
    property TaskCount: Integer read GetTaskCount;
    property OnTaskInstanceListChanged: TTaskInstanceListChangedProc read FOnTaskInstanceListChanged write FOnTaskInstanceListChanged;
    property OnTaskInstanceChanged: TOnTaskInstanceProc read FOnTaskInstanceChanged write FOnTaskInstanceChanged;
    property OnSendData: TOnTaskInstanceProc read FOnSendData write FOnSendData;
    property OnSendProgress: TOnTaskInstanceProc read FOnSendProgress write FOnSendProgress;

  end;

function TaskServices: TMKOTaskServices;

implementation

function TaskServices: TMKOTaskServices;
begin
  Result := TMKOTaskServices.Instance;
end;

{ TTaskStateHelper }

function TTaskStateHelper.ToString: String;
const

  AA_MAP: array[TTaskState] of String = (

    SC_TASK_STATE_CREATED_CAPTION,
    SC_TASK_STATE_WAITING_CAPTION,
    SC_TASK_STATE_PROCESSING_CAPTION,
    SC_TASK_STATE_FINISHED_CAPTION,
    SC_TASK_STATE_CANCELED_CAPTION,
    SC_TASK_STATE_ERROR_CAPTION

  );

begin
  Result := AA_MAP[Self];
end;

function TTaskStateHelper.Report: String;
const

  AA_MAP: array[TTaskState] of String = (

      SC_TASK_STATE_CREATED_REPORT,
      SC_TASK_STATE_WAITING_REPORT,
      SC_TASK_STATE_PROCESSING_REPORT,
      SC_TASK_STATE_FINISHED_REPORT,
      SC_TASK_STATE_CANCELED_REPORT,
      SC_TASK_STATE_ERROR_REPORT

  );

begin
  Result := AA_MAP[Self];
end;

{ TMKOTaskItem.TOutputIntf }

constructor TMKOTaskItem.TOutputIntf.Create(_Item: TMKOTaskItem);
begin
  inherited Create;
  FTaskItem := _Item;
end;

procedure TMKOTaskItem.TOutputIntf.WriteOut(const _Value: WideString; _Progress: Integer);
begin
  TaskItem.WriteOut(_Value, _Progress);
end;

{ TMKOTaskItem }

function TMKOTaskItem.CanStart: Boolean;
begin
  Result := TaskServices.TaskItems.StateCount(tsProcessing) < IC_MAX_RUNNING_THREAD_COUNT;
end;

procedure TMKOTaskItem.CompleteTaskProcessing;
begin

  FCompletePoint := Now;

  WriteOut(Format(SC_TASK_COMPLETED_REPORT, [

      TimeToStr(CompletePoint - CreatePoint)

  ]), -1, True);

  SaveToLog;

end;

constructor TMKOTaskItem.Create;
begin

  inherited Create;

  FTask := _MKOTask;
  FParams := _Params;
  FWndHandle := _WndHandle;
  FCreatePoint := Now;

  FStateLocker := TCriticalSection.Create;
  FDataLocker := TCriticalSection.Create;
  FProgressLocker := TCriticalSection.Create;

  { Для вывода }
  State := tsCreated;

  CreateThread;

end;

procedure TMKOTaskItem.CreateThread;
begin

  FIntf := Task.Intf.StartTask(Params);
  FThread := TMKOTaskThread.Create(Intf, TOutputIntf.Create(Self));

  Thread.BeforeExecute := ThreadBeforeExecute;
  Thread.AfterExecute := ThreadAfterExecute;
  Thread.OnTerminate := ThreadOnTerminate;

  if CanStart then StartThread
  else State := tsWaiting;

end;

destructor TMKOTaskItem.Destroy;
begin

  FreeAndNil(FProgressLocker);
  FreeAndNil(FDataLocker);
  FreeAndNil(FStateLocker);

  inherited Destroy;

end;

procedure TMKOTaskItem.DoChanged;
begin
  PostMessage(WndHandle, WM_TASK_INSTANCE_CHANGED, WPARAM(Self), 0);
end;

procedure TMKOTaskItem.DoSendData(_Assured: Boolean);
var
  TC: Cardinal;
begin

  TC := GetTickCount;

  if

      DataChanged and
      not DataPosted and
      { Отправляем сообщение не слишком часто, чтобы не заваливать очередь. По завершению
        обработки в любом случае будет смена статуса с гарантированной отправкой. }
      (_Assured or (TC - LastPostPoint > IC_MIN_POSTING_INTERVAL))

  then
  begin

    FDataPosted := True;
    PostMessage(WndHandle, WM_TASK_SEND_DATA, WPARAM(Self), 0);
    LastPostPoint := TC;

  end;

end;

procedure TMKOTaskItem.DoSendProgress;
begin
  PostMessage(WndHandle, WM_TASK_SEND_PROGRESS, WPARAM(Self), 0);
end;

function TMKOTaskItem.GetState: TTaskState;
begin

  StateLocker.Acquire;
  try

    Result := FState;

  finally
    StateLocker.Release;
  end;

end;

procedure TMKOTaskItem.PullData(var _Target: String);
begin

  DataLocker.Acquire;
  try

    if _Target.Length <> FData.Length then
    begin

      if (IC_MAX_DATA_PULLING_LENGTH = -1) or (State in SS_TASK_FINAL_STATES) then
        _Target := FData
      else
        _Target := Copy(FData, 1, IC_MAX_DATA_PULLING_LENGTH);

    end;

    FDataPosted := False;
    FDataChanged := False;

  finally
    DataLocker.Release;
  end;

end;

procedure TMKOTaskItem.PullProgress(var _Progress: Integer);
begin

  ProgressLocker.Acquire;
  try

    _Progress := FProgress;

  finally
    ProgressLocker.Release;
  end;

end;

procedure TMKOTaskItem.SaveToLog;
const
  SC_FORMAT = '%s\Logs\%s_%s.log';
begin

  FLogFile := UniqueFileName(Format(SC_FORMAT, [

      ExeDir,
      Task.Intf.Name,
      FormatDateTime('yyyy-mm-dd hh-nn-ss-zzz', CompletePoint)

  ]));

  StrToFile(LogFile, FData);

end;

procedure TMKOTaskItem.SetState(const _Value: TTaskState);
begin

  StateLocker.Acquire;
  try

    if FState in SS_TASK_FINAL_STATES then
      Exit;

    FState := _Value;

  finally
    StateLocker.Release;
  end;

  WriteOut(State.Report, -1);
  DoChanged;

end;

procedure TMKOTaskItem.StartThread;
begin
  Thread.Start;
end;

procedure TMKOTaskItem.Terminate;
begin

  State := tsCanceled;

  Intf.Terminate;
  Thread.Terminate;
  Thread.WaitFor;

end;

procedure TMKOTaskItem.ThreadAfterExecute(_ErrorOccured: Boolean);
const
  AC_MAP: array[Boolean] of TTaskState = (tsFinished, tsError);
begin

  State := AC_MAP[_ErrorOccured];
  TaskServices.CheckWaiting;

end;

procedure TMKOTaskItem.ThreadBeforeExecute;
begin
  State := tsProcessing;
end;

procedure TMKOTaskItem.ThreadOnTerminate(_Sender: TObject);
begin
  State := tsCanceled;
end;

procedure TMKOTaskItem.WriteOut(const _Value: WideString; _Progress: Integer; _Assured: Boolean);
begin

  DataLocker.Acquire;
  try

    if Length(_Value) > 0 then
    begin

      {TODO 1 -oVasilevSM : Тут очень долго. }
      FData := _Value + CRLF + FData;
      FDataChanged := True;
      DoSendData(_Assured);

    end;

  finally
    DataLocker.Release;
  end;

  ProgressLocker.Acquire;
  try

    if (_Progress <> -1) and (FProgress <> _Progress) then
    begin

      FProgress := _Progress;
      DoSendProgress;

    end;

  finally
    ProgressLocker.Release;
  end;

end;

{ TMKOTaskItemList }

function TMKOTaskItemList.StateCount(_State: TTaskState): Integer;
var
  Item: TMKOTaskItem;
begin

  Result := 0;
  for Item in Self do
    if Item.State = _State then
      Inc(Result);

end;

function TMKOTaskItemList.StateCount(_States: TTaskStates): Integer;
var
  Item: TMKOTaskItem;
begin

  Result := 0;
  for Item in Self do
    if Item.State in _States then
      Inc(Result);

end;

function TMKOTaskItemList.StateFind(_State: TTaskState; var _Item: TMKOTaskItem): Boolean;
var
  Item: TMKOTaskItem;
begin

  for Item in Self do

    if Item.State = _State then
    begin

      _Item := Item;
      Exit(True);

    end;

  Result := False;

end;

{ TMKOTaskParams }

constructor TMKOTaskParams.Create(const _Params: String);
begin

  inherited Create;

  FList := TStringList.Create;
  {TODO 2 -oVasilevSM : Здесь нужен парсер для более свободного формата параметров. Через , итд. }
  List.Text := _Params;

end;

procedure TMKOTaskParams.Delete(_Index: Integer);
begin
  List.Delete(_Index);
end;

destructor TMKOTaskParams.Destroy;
begin
  FreeAndNil(FList);
  inherited Destroy;
end;

function TMKOTaskParams.GetItems(_Index: Integer): WideString;
begin
  Result := List[_Index];
end;

procedure TMKOTaskParams.SetErrorMessage(const _Value: WideString);
begin
  FErrorMessage := _Value;
end;

procedure TMKOTaskParams.SetItems(_Index: Integer; const _Value: WideString);
begin
  List[_Index] := _Value;
end;

function TMKOTaskParams.ToString: WideString;
var
  S: String;
begin

  Result := '';

  for S in List do
    Result := Format('%s"%s" ', [Result, S]);

  CutStr(Result, 1);

end;

function TMKOTaskParams.GetCount: Integer;
begin
  Result := List.Count;
end;

function TMKOTaskParams.GetErrorMessage: WideString;
begin
  Result := FErrorMessage;
end;

{ TMKOTask }

constructor TMKOTask.Create;
begin
  inherited Create;
  FIntf := _Intf;
end;

function TMKOTask.StartTask(const _Params: IMKOTaskParams): TMKOTaskItem;
begin
  TrimParams(_Params);
  Result := TaskServices.AddTaskInstance(Self, _Params);
end;

procedure TMKOTask.TrimParams(const _Params: IMKOTaskParams);
var
  i: Integer;
  S: String;
begin

  for i := _Params.Count - 1 downto 0 do
  begin

    S := _Params[i];
    S := S.Trim;

    if S.Length = 0 then
      _Params.Delete(i)
    else
      _Params[i] := S;

  end;

end;

function TMKOTask.ValidateParams(const _Params: IMKOTaskParams): Boolean;
begin
  Result := Intf.ValidateParams(_Params);
end;

{ TMKOTaskList }

function TMKOTaskList.Contains(const _TaskName: String): Boolean;
var
  Item: TMKOTask;
begin

  for Item in Self do
    if AnsiSameText(Item.Intf.Name, _TaskName) then
      Exit(True);

  Result := False;

end;

{ TMKOLibraryIntf }

constructor TMKOLibraryIntf.Create(_Tasks: TMKOTaskList);
begin
  inherited Create;
  FTasks := _Tasks;
end;

procedure TMKOLibraryIntf.RegisterTask(_MKOTask: IMKOTask);
begin

  if Tasks.Contains(_MKOTask.Name) then
    raise EMKOTMException.CreateFmt(SC_TASK_NAME_UNIQUE_ERROR, [_MKOTask.Name]);

  Tasks.Add(TMKOTask.Create(_MKOTask));

end;

{ TMKOLibrary }

constructor TMKOLibrary.Create;
begin
  inherited Create;
  FTasks := TMKOTaskList.Create;
end;

destructor TMKOLibrary.Destroy;
begin
  FreeAndNil(FTasks);
  inherited Destroy;
end;

function TMKOLibrary.Load(const _File: String): Boolean;
var
  Marker: TMKOTaskLibraryMarkerProc;
  InitProc: TMKOInitLibraryProc;
begin

  FHandle := LoadLibrary(PWideChar(_File));

  Result := Handle <> 0;
  if Result then
  begin

    Marker   := GetProcAddress(Handle, PWideChar('MKOTaskLibraryMarker'));
    InitProc := GetProcAddress(Handle, PWideChar('InitLibrary'         ));
    FFinProc := GetProcAddress(Handle, PWideChar('FinLibrary'          ));

    { FinProc может быть не назначен, если там нечего освобождать. }
    Result := Assigned(Marker) and Assigned(InitProc);

    if Result then

      { Этот экземпляр уничтожится интерфейсом. }
      InitProc(TMKOLibraryIntf.Create(Tasks))

    else
    begin

      FreeLibrary(Handle);
      FHandle := 0;

    end;

  end;

end;

procedure TMKOLibrary.Finalize;
begin

  Tasks.Clear;

  if Assigned(FinProc) then
    FinProc;
  if Handle <> 0 then
    FreeLibrary(Handle);

end;

{ TMKOTaskServices }

function TMKOTaskServices.AddTaskInstance(_MKOTask: TMKOTask; const _Params: IMKOTaskParams): TMKOTaskItem;
begin

  Result := TMKOTaskItem.Create(_MKOTask, _Params, WndHandle);
  TaskItems.Insert(0, Result);

  DoOnTaskInstanceListChanged;

end;

constructor TMKOTaskServices.Create;
begin

  inherited Create;

  FWndHandle := AllocateHWnd(MessageProc);
  FLibraries := TMKOLibraryList.Create;
  FTaskItems := TMKOTaskItemList.Create;

end;

destructor TMKOTaskServices.Destroy;
begin

  FOnTaskInstanceListChanged := nil;
  FOnTaskInstanceChanged := nil;

  FreeAndNil(FTaskItems);
  FreeAndNil(FLibraries);
  DeallocateHWnd(FWndHandle);

  inherited Destroy;

end;

procedure TMKOTaskServices.DoOnTaskItemChanged(_Item: TMKOTaskItem);
begin

  with _Item do
    if State in SS_TASK_FINAL_STATES then
      CompleteTaskProcessing;

  if Assigned(FOnTaskInstanceChanged) then
    OnTaskInstanceChanged(_Item);

end;

procedure TMKOTaskServices.DoOnSendData(_Item: TMKOTaskItem);
begin
  if Assigned(FOnSendData) then
    OnSendData(_Item);
end;

procedure TMKOTaskServices.DoOnSendProgress(_Item: TMKOTaskItem);
begin
  if Assigned(FOnSendProgress) then
    OnSendProgress(_Item);
end;

procedure TMKOTaskServices.DoOnTaskInstanceListChanged;
begin
  if Assigned(FOnTaskInstanceListChanged) then
    OnTaskInstanceListChanged;
end;

function TMKOTaskServices.GetTaskCount: Integer;
var
  MKOLibrary: TMKOLibrary;
begin

  Result := 0;
  for MKOLibrary in Libraries do
    Inc(Result, MKOLibrary.Tasks.Count)

end;

procedure TMKOTaskServices.LoadLibrary(const _File: String);
var
  MKOLibrary: TMKOLibrary;
begin

  MKOLibrary := TMKOLibrary.Create;
  try

    if MKOLibrary.Load(_File) then
      Libraries.Add(MKOLibrary);

  except
    MKOLibrary.Free;
  end;

end;

procedure TMKOTaskServices.MessageProc(var _Message: TMessage);
begin

  case _Message.Msg of

    WM_TASK_INSTANCE_CHANGED: DoOnTaskItemChanged(TMKOTaskItem(_Message.WParam));
    WM_TASK_SEND_DATA:        DoOnSendData       (TMKOTaskItem(_Message.WParam));
    WM_TASK_SEND_PROGRESS:    DoOnSendProgress   (TMKOTaskItem(_Message.WParam));

  end;

end;

procedure TMKOTaskServices.CheckWaiting;
var
  Item: TMKOTaskItem;
begin

  if TaskItems.StateFind(tsWaiting, Item) then
    Item.StartThread;

end;

class function TMKOTaskServices.Instance: TMKOTaskServices;
begin

  if Finalized then
    raise EMKOTMException.Create('Using after finalization.');

  if not Assigned(FInstance) then
    FInstance := Self.Create;

  Result := FInstance;

end;

class procedure TMKOTaskServices.Finalize;
begin

  if Assigned(FInstance) then
  begin

    Instance.FinalizeTaskInstances;
    Instance.FinalizeLibraries;

  end;

  FreeAndNil(FInstance);
  FFinalized := True;

end;

procedure TMKOTaskServices.FinalizeLibraries;
var
  MKOLibrary: TMKOLibrary;
begin

  for MKOLibrary in Libraries do
    MKOLibrary.Finalize;

end;

procedure TMKOTaskServices.FinalizeTaskInstances;
var
  i: Integer;
begin

  for i := TaskItems.Count - 1 downto 0 do
  begin

    with TaskItems[i] do
    begin

      Terminate;
      Free;

    end;

    TaskItems.Delete(i);

  end;

end;

procedure TMKOTaskServices.LoadLibraries;
var
  RootPath: String;
begin

  RootPath := ExeDir;

  ExploreFiles(RootPath, '*.dll',

      procedure (const _File: String; _MaskMatches: Boolean; var _Terminated: Boolean)
      begin

        if _MaskMatches then
          LoadLibrary(_File);

      end

  );

end;

initialization

finalization

  TMKOTaskServices.Finalize;

end.
