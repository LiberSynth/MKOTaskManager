unit uLibSupport;

interface

uses
  { VCL }
  System.SysUtils, Generics.Collections, Winapi.Windows, System.SyncObjs, System.Classes,
  Winapi.Messages,
  { Common }
  uInterfaces, uFileExplorer,
  { TM }
  uUtils, uTypes, uThread, uConsts, Common.uUtils;

type

  TTaskState = (tsCreated, tsWaiting, tsProcessing, tsFinished, tsCanceled, tsError);

  TTaskStateHelper = record helper for TTaskState

  public

    function ToString: String;
    function Report: String;

  end;

  TMKOTask = class;

  TMKOTaskInstance = class

  strict private type

    TOutputIntf = class(TInterfacedObject, IMKOTaskOutput)

    strict private

      FTaskInstance: TMKOTaskInstance;

      { IMKOTaskOutput }
      procedure WriteOut(const _Value: WideString; _Progress: Integer); safecall;

      property TaskInstance: TMKOTaskInstance read FTaskInstance;

    private

      constructor Create(_TaskInstance: TMKOTaskInstance); reintroduce;

    end;

  strict private

    FTask: TMKOTask;
    FIntf: IMKOTaskInstance;
    FThread: TMKOTaskThread;
    FParams: IMKOTaskParams;
    FWndHandle: HWND;
    FState: TTaskState;
    FData: TStringList;
    FProgress: Integer;
    FDate: TDateTime;
    FLastPostPoint: Cardinal;
    FStateLocker: TCriticalSection;
    FDataLocker: TCriticalSection;

    function GetState: TTaskState;
    procedure SetState(const _Value: TTaskState);

    procedure CreateThread;
    procedure ThreadBeforeExecute;
    procedure ThreadAfterExecute(_ErrorOccured: Boolean);
    procedure ThreadOnTerminate(_Sender: TObject);
    function CanStart: Boolean;
    procedure DoChanged;
    procedure DoSendData(_Assured: Boolean);

    property Intf: IMKOTaskInstance read FIntf;
    property Thread: TMKOTaskThread read FThread;
    property StateLocker: TCriticalSection read FStateLocker;
    property DataLocker: TCriticalSection read FDataLocker;
    property WndHandle: HWND read FWndHandle;
    property Data: TStringList read FData write FData;
    property LastPostPoint: Cardinal read FLastPostPoint write FLastPostPoint;

  private

    constructor Create(

        _MKOTask: TMKOTask;
        const _Params: IMKOTaskParams;
        _WndHandle: HWND

    ); reintroduce;

    procedure StartThread;

    { Многопоточный метод }
    procedure WriteOut(const _Value: WideString; _Progress: Integer; _Assured: Boolean = False);

    property Progress: Integer read FProgress;

  public

    destructor Destroy; override;

    procedure Terminate;

    property Task: TMKOTask read FTask;
    property Params: IMKOTaskParams read FParams;
    property Date: TDateTime read FDate;

    { Многопоточный метод }
    procedure PullData(_Target: TStrings; var _Progress: Integer);

    { Многопоточное свойство }
    property State: TTaskState read GetState write SetState;

  end;

  TMKOTaskInstanceList = class(TList<TMKOTaskInstance>)

  private

    function StateCount(_State: TTaskState): Integer;
    function StateFind(_State: TTaskState; var _Instance: TMKOTaskInstance): Boolean;

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
    function StartTask(const _Params: IMKOTaskParams): TMKOTaskInstance;

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
    TOnTaskInstanceProc = procedure(_Instance: TMKOTaskInstance) of object;

  strict private

    class var FInstance: TMKOTaskServices;
    class var FFinalized: Boolean;

    class property Finalized: Boolean read FFinalized;

  strict private

    FWndHandle: HWND;
    FLibraries: TMKOLibraryList;
    FTaskInstances: TMKOTaskInstanceList;
    FOnTaskInstanceListChanged: TTaskInstanceListChangedProc;
    FOnTaskInstanceChanged: TOnTaskInstanceProc;
    FOnSendData: TOnTaskInstanceProc;

    function GetTaskCount: Integer;

    procedure LoadLibrary(const _File: String);
    procedure MessageProc(var _Message: TMessage);
    procedure DoOnTaskInstanceListChanged;
    procedure DoOnTaskInstanceChanged(_Instance: TMKOTaskInstance);
    procedure DoOnSendData(_Instance: TMKOTaskInstance);

    property WndHandle: HWND read FWndHandle;

  private

    constructor Create;

    class function Instance: TMKOTaskServices;
    class procedure Finalize;

    procedure FinalizeLibraries;
    procedure FinalizeTaskInstances;

    procedure StartWaiting;

    function AddTaskInstance(_MKOTask: TMKOTask; const _Params: IMKOTaskParams): TMKOTaskInstance;

  public

    destructor Destroy; override;

    procedure LoadLibraries;

    property Libraries: TMKOLibraryList read FLibraries;
    property TaskInstances: TMKOTaskInstanceList read FTaskInstances;
    property TaskCount: Integer read GetTaskCount;
    property OnTaskInstanceListChanged: TTaskInstanceListChangedProc read FOnTaskInstanceListChanged write FOnTaskInstanceListChanged;
    property OnTaskInstanceChanged: TOnTaskInstanceProc read FOnTaskInstanceChanged write FOnTaskInstanceChanged;
    property OnSendData: TOnTaskInstanceProc read FOnSendData write FOnSendData;

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

{ TMKOTaskInstance.TOutputIntf }

constructor TMKOTaskInstance.TOutputIntf.Create(_TaskInstance: TMKOTaskInstance);
begin
  inherited Create;
  FTaskInstance := _TaskInstance;
end;

procedure TMKOTaskInstance.TOutputIntf.WriteOut(const _Value: WideString; _Progress: Integer);
begin
  TaskInstance.WriteOut(_Value, _Progress);
end;

{ TMKOTaskInstance }

function TMKOTaskInstance.CanStart: Boolean;
begin
  Result := TaskServices.TaskInstances.StateCount(tsProcessing) < IC_MAXTHREAD_COUNT;
end;

constructor TMKOTaskInstance.Create;
begin

  inherited Create;

  FTask := _MKOTask;
  FParams := _Params;
  FWndHandle := _WndHandle;
  FDate := Now;

  FStateLocker := TCriticalSection.Create;
  FDataLocker := TCriticalSection.Create;
  FData := TStringList.Create;

  { Для вывода }
  State := tsCreated;

  CreateThread;

end;

procedure TMKOTaskInstance.CreateThread;
begin

  FIntf := Task.Intf.StartTask(Params);
  FThread := TMKOTaskThread.Create(Intf, TOutputIntf.Create(Self));

  Thread.BeforeExecute := ThreadBeforeExecute;
  Thread.AfterExecute := ThreadAfterExecute;
  Thread.OnTerminate := ThreadOnTerminate;

  if CanStart then StartThread
  else State := tsWaiting;

end;

destructor TMKOTaskInstance.Destroy;
begin

  FreeAndNil(FDataLocker);
  FreeAndNil(FStateLocker);
  FreeAndNil(FData);

  inherited Destroy;

end;

procedure TMKOTaskInstance.DoChanged;
begin
  PostMessage(WndHandle, WM_TASK_INSTANCE_CHANGED, WPARAM(Self), 0);
end;

procedure TMKOTaskInstance.DoSendData(_Assured: Boolean);
var
  TC: Cardinal;
begin

  TC := GetTickCount;

  { Отправляем сообщение не слишком часто, чтобы не завалить очередь. }
  if _Assured or (TC - LastPostPoint > 100) then
  begin

    PostMessage(WndHandle, WM_TASK_SEND_DATA, WPARAM(Self), 0);
    LastPostPoint := TC;

  end;

end;

function TMKOTaskInstance.GetState: TTaskState;
begin

  StateLocker.Acquire;
  try

    Result := FState;

  finally
    StateLocker.Release;
  end;

end;

procedure TMKOTaskInstance.PullData(_Target: TStrings; var _Progress: Integer);
var
  i: Integer;
begin

  DataLocker.Acquire;
  try

    with _Target do
    begin

      BeginUpdate;
      try

        for i := Count to Data.Count - 1 do
          Add(Data[i]);

      finally
        EndUpdate;
      end;

    end;

    _Progress := Progress;

  finally
    DataLocker.Release;
  end;

end;

procedure TMKOTaskInstance.SetState(const _Value: TTaskState);
const
  SS_FINAL_STATES = [tsFinished, tsCanceled, tsError];
begin

  StateLocker.Acquire;
  try

    if FState in SS_FINAL_STATES then
      Exit;

    FState := _Value;

  finally
    StateLocker.Release;
  end;

  DoChanged;
  WriteOut(State.Report, -1, True);

end;

procedure TMKOTaskInstance.StartThread;
begin
  Thread.Start;
end;

procedure TMKOTaskInstance.Terminate;
begin

  State := tsCanceled;

  Intf.Terminate;
  Thread.Terminate;
  Thread.WaitFor;

end;

procedure TMKOTaskInstance.ThreadAfterExecute(_ErrorOccured: Boolean);
const
  AC_MAP: array[Boolean] of TTaskState = (tsFinished, tsError);
begin

  {$IFDEF DEBUG}
  { Чтобы в при отладке нагладнее наблюдать за процессом. }
  Sleep(800);
  {$ENDIF}
  State := AC_MAP[_ErrorOccured];

  TaskServices.StartWaiting;

end;

procedure TMKOTaskInstance.ThreadBeforeExecute;
begin

  {$IFDEF DEBUG}
  { Чтобы в при отладке нагладнее наблюдать за процессом. }
  Sleep(800);
  {$ENDIF}
  State := tsProcessing;

end;

procedure TMKOTaskInstance.ThreadOnTerminate(_Sender: TObject);
begin
  State := tsCanceled;
end;

procedure TMKOTaskInstance.WriteOut(const _Value: WideString; _Progress: Integer; _Assured: Boolean);
begin

  DataLocker.Acquire;
  try

    if Length(_Value) > 0 then
      Data.Add(_Value);

    if _Progress <> -1 then
      FProgress := _Progress;

    DoSendData(_Assured);

  finally
    DataLocker.Release;
  end;

end;

{ TMKOTaskInstanceList }

function TMKOTaskInstanceList.StateCount(_State: TTaskState): Integer;
var
  Item: TMKOTaskInstance;
begin

  Result := 0;
  for Item in Self do
    if Item.State = _State then
      Inc(Result);

end;

function TMKOTaskInstanceList.StateFind(_State: TTaskState; var _Instance: TMKOTaskInstance): Boolean;
var
  Item: TMKOTaskInstance;
begin

  for Item in Self do

    if Item.State = _State then
    begin

      _Instance := Item;
      Exit(True);

    end;

  Result := False;

end;

{ TMKOTaskParams }

constructor TMKOTaskParams.Create(const _Params: String);
begin

  inherited Create;

  FList := TStringList.Create;
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

function TMKOTask.StartTask(const _Params: IMKOTaskParams): TMKOTaskInstance;
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

function TMKOTaskServices.AddTaskInstance(_MKOTask: TMKOTask; const _Params: IMKOTaskParams): TMKOTaskInstance;
begin

  Result := TMKOTaskInstance.Create(_MKOTask, _Params, WndHandle);
  TaskInstances.Insert(0, Result);

  DoOnTaskInstanceListChanged;

end;

constructor TMKOTaskServices.Create;
begin

  inherited Create;

  FWndHandle     := AllocateHWnd(MessageProc);
  FLibraries     := TMKOLibraryList.Create;
  FTaskInstances := TMKOTaskInstanceList.Create;

end;

destructor TMKOTaskServices.Destroy;
begin

  FOnTaskInstanceListChanged := nil;
  FOnTaskInstanceChanged := nil;

  FreeAndNil(FTaskInstances);
  FreeAndNil(FLibraries);
  DeallocateHWnd(FWndHandle);

  inherited Destroy;

end;

procedure TMKOTaskServices.DoOnTaskInstanceChanged(_Instance: TMKOTaskInstance);
begin
  if Assigned(FOnTaskInstanceChanged) then
    OnTaskInstanceChanged(_Instance);
end;

procedure TMKOTaskServices.DoOnSendData(_Instance: TMKOTaskInstance);
begin
  if Assigned(FOnSendData) then
    OnSendData(_Instance);
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

    WM_TASK_INSTANCE_CHANGED: DoOnTaskInstanceChanged(TMKOTaskInstance(_Message.WParam));
    WM_TASK_SEND_DATA:        DoOnSendData           (TMKOTaskInstance(_Message.WParam));

  end;

end;

procedure TMKOTaskServices.StartWaiting;
var
  TaskInstance: TMKOTaskInstance;
begin

  if TaskInstances.StateFind(tsWaiting, TaskInstance) then
    TaskInstance.StartThread;

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

  for i := TaskInstances.Count - 1 downto 0 do
  begin

    with TaskInstances[i] do
    begin

      Terminate;
      Free;

    end;

    TaskInstances.Delete(i);

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
