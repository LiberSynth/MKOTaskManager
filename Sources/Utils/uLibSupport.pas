unit uLibSupport;

interface

uses
  { VCL }
  System.SysUtils, Generics.Collections, Winapi.Windows, System.SyncObjs, System.Classes,
  Winapi.Messages,
  { Common }
  uInterfaces, uFileExplorer,
  { TM }
  uUtils, uTypes, uThread, uConsts;

type

  TTaskState = (tsCreated, tsProcessing, tsFinished, tsCanceled, tsError);

  TTaskStateHelper = record helper for TTaskState

  public

    function ToString: String;
    function Report: String;

  end;

  TMKOTask = class;

  TMKOTaskInstance = class

  strict private type

    TWiteOutIntf = class(TInterfacedObject, IMKOTaskWiteOut)

    strict private

      FTaskInstance: TMKOTaskInstance;

      { IMKOTaskWiteOut }
      procedure WriteOut(const _Value: WideString); safecall;

      property TaskInstance: TMKOTaskInstance read FTaskInstance;

    private

      constructor Create(_TaskInstance: TMKOTaskInstance); reintroduce;

    end;

  strict private

    FTask: TMKOTask;
    FIntf: IMKOTaskInstance;
    FThread: TMKOTaskThread;
    FParams: String;
    FWndHandle: HWND;
    FState: TTaskState;
    FData: TStringList;
    FDate: TDateTime;
    FStateLocker: TCriticalSection;
    FDataLocker: TCriticalSection;

    function GetState: TTaskState;
    procedure SetState(const _Value: TTaskState);

    procedure CreateThread;
    procedure ThreadBeforeExecute;
    procedure ThreadAfterExecute(_ErrorOccured: Boolean);
    procedure ThreadOnTerminate(_Sender: TObject);
    procedure DoChanged;

    property Intf: IMKOTaskInstance read FIntf;
    property Thread: TMKOTaskThread read FThread;
    property StateLocker: TCriticalSection read FStateLocker;
    property DataLocker: TCriticalSection read FDataLocker;
    property WndHandle: HWND read FWndHandle;
    property Data: TStringList read FData write FData;

  private

    constructor Create(

        _MKOTask: TMKOTask;
        const _Params: String;
        _WndHandle: HWND

    ); reintroduce;

    procedure WriteOut(const _Value: WideString);

  public

    destructor Destroy; override;

    procedure Terminate;

    { Однопоточные свойства }
    property Task: TMKOTask read FTask;
    property Params: String read FParams;
    property Date: TDateTime read FDate;

    { Многопоточные методы и свойства }
    procedure PullData(_Target: TStrings);

    property State: TTaskState read GetState write SetState;

  end;

  TMKOTaskInstanceList = class(TList<TMKOTaskInstance>);

  TMKOTask = class

  strict private

    FIntf: IMKOTask;

  public

    constructor Create(const _Intf: IMKOTask); reintroduce;

    function StartTask(const _Params: String): TMKOTaskInstance;

    property Intf: IMKOTask read FIntf;

  end;

  {TODO 1 -oVasilyevSM: Проконтролировать уникальность поля Name. (Если понадобится поле Name вообще.) }
  TMKOTaskList = class(TObjectList<TMKOTask>);

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

    TTaskInstancesChangedProc = procedure of object;
    TOnTaskInstanceChanged = procedure(_Sender: TMKOTaskInstance) of object;

  strict private

    class var FInstance: TMKOTaskServices;
    class var FFinalized: Boolean;

    class property Finalized: Boolean read FFinalized;

  strict private

    FWndHandle: HWND;
    FLibraries: TMKOLibraryList;
    FTaskInstances: TMKOTaskInstanceList;
    FOnTaskInstancesChanged: TTaskInstancesChangedProc;
    FOnTaskInstanceChanged: TOnTaskInstanceChanged;

    function GetTaskCount: Integer;

    procedure LoadLibrary(const _File: String);
    procedure MessageProc(var _Message: TMessage);
    procedure DoOnTaskInstancesChanged;
    procedure DoOnTaskInstanceChanged(_Sender: TMKOTaskInstance);

    property WndHandle: HWND read FWndHandle;

  private

    constructor Create;

    class function Instance: TMKOTaskServices;
    class procedure Finalize;

    procedure FinalizeLibraries;
    procedure FinalizeTaskInstances;

    function AddTaskInstance(_MKOTask: TMKOTask; const _Params: String): TMKOTaskInstance;

  public

    destructor Destroy; override;

    procedure LoadLibraries;

    property Libraries: TMKOLibraryList read FLibraries;
    property TaskInstances: TMKOTaskInstanceList read FTaskInstances;
    property TaskCount: Integer read GetTaskCount;
    property OnTaskInstancesChanged: TTaskInstancesChangedProc read FOnTaskInstancesChanged write FOnTaskInstancesChanged;
    property OnTaskInstanceChanged: TOnTaskInstanceChanged read FOnTaskInstanceChanged write FOnTaskInstanceChanged;

  end;

function TaskServices: TMKOTaskServices;

implementation

function TaskServices: TMKOTaskServices;
begin
  Result := TMKOTaskServices.Instance;
end;

{ TTaskStateHelper }

function TTaskStateHelper.Report: String;
const

  AA_MAP: array[TTaskState] of String = (

      SC_TASK_STATE_REPORT_CREATED,
      SC_TASK_STATE_REPORT_PROCESSING,
      SC_TASK_STATE_REPORT_FINISHED,
      SC_TASK_STATE_REPORT_CANCELED,
      SC_TASK_STATE_REPORT_ERROR

  );

begin
  Result := AA_MAP[Self];
end;


function TTaskStateHelper.ToString: String;
begin

  case Self of

    tsCreated:    Result := SC_TASK_STATE_CREATED_CAPTION;
    tsProcessing: Result := SC_TASK_STATE_PROCESSING_CAPTION;
    tsFinished:   Result := SC_TASK_STATE_FINISHED_CAPTION;
    tsCanceled:   Result := SC_TASK_STATE_CANCELED_CAPTION;
    tsError:      Result := SC_TASK_STATE_ERROR_CAPTION

  else
    raise EMKOTMException.Create('Complete this method.');
  end;

end;

{ TMKOTaskInstance.TWiteOutIntf }

constructor TMKOTaskInstance.TWiteOutIntf.Create(_TaskInstance: TMKOTaskInstance);
begin
  inherited Create;
  FTaskInstance := _TaskInstance;
end;

procedure TMKOTaskInstance.TWiteOutIntf.WriteOut(const _Value: WideString);
begin
  TaskInstance.WriteOut(_Value);
end;

{ TMKOTaskInstance }

constructor TMKOTaskInstance.Create;
begin

  inherited Create;

  FTask   := _MKOTask;
  FParams := _Params;
  FWndHandle := _WndHandle;
  FDate   := Now;

  FStateLocker := TCriticalSection.Create;
  FDataLocker := TCriticalSection.Create;
  FData := TStringList.Create;
  CreateThread;

  { Для вывода }
  State := tsCreated;

end;

procedure TMKOTaskInstance.CreateThread;
begin

  FIntf := Task.Intf.StartTask(Params);
  FThread := TMKOTaskThread.Create(Intf, TWiteOutIntf.Create(Self));

  Thread.BeforeExecute := ThreadBeforeExecute;
  Thread.AfterExecute := ThreadAfterExecute;
  Thread.OnTerminate := ThreadOnTerminate;

  Thread.Start;

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
  PostMessage(WndHandle, WM_TASK_INSTANCE_CHANGED, WPARAM(Self), 0)
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

procedure TMKOTaskInstance.PullData(_Target: TStrings);
begin

  DataLocker.Acquire;
  try

    _Target.Assign(Data);

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

  WriteOut(State.Report);

end;

procedure TMKOTaskInstance.Terminate;
begin

  Intf.Terminate;

  Thread.Terminate;
  Thread.WaitFor;

end;

procedure TMKOTaskInstance.ThreadAfterExecute(_ErrorOccured: Boolean);
const
  AC_MAP: array[Boolean] of TTaskState = (tsFinished, tsError);
begin

  {TODO 1 -oVasilevSM: Убрать: }
  Sleep(1000);
  State := AC_MAP[_ErrorOccured];

end;

procedure TMKOTaskInstance.ThreadBeforeExecute;
begin

  {TODO 1 -oVasilevSM: Убрать: }
  Sleep(1000);
  State := tsProcessing;

end;

procedure TMKOTaskInstance.ThreadOnTerminate(_Sender: TObject);
begin
  State := tsCanceled;
end;

procedure TMKOTaskInstance.WriteOut(const _Value: WideString);
begin

  DataLocker.Acquire;
  try

    Data.Add(_Value);

  finally
    DataLocker.Release;
  end;

  DoChanged;

end;

{ TMKOTask }

constructor TMKOTask.Create;
begin
  inherited Create;
  FIntf := _Intf;
end;

function TMKOTask.StartTask(const _Params: String): TMKOTaskInstance;
var
  Params: WideString;
begin

  Params := _Params;
  Intf.ValidateParams(Params);
  Result := TaskServices.AddTaskInstance(Self, Params);

end;

{ TMKOLibraryIntf }

constructor TMKOLibraryIntf.Create(_Tasks: TMKOTaskList);
begin
  inherited Create;
  FTasks := _Tasks;
end;

procedure TMKOLibraryIntf.RegisterTask(_MKOTask: IMKOTask);
begin

  with _MKOTask do
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

function TMKOTaskServices.AddTaskInstance(_MKOTask: TMKOTask; const _Params: String): TMKOTaskInstance;
begin

  Result := TMKOTaskInstance.Create(_MKOTask, _Params, WndHandle);
  TaskInstances.Add(Result);

  DoOnTaskInstancesChanged;

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

  FOnTaskInstancesChanged := nil;
  FOnTaskInstanceChanged := nil;

  FreeAndNil(FTaskInstances);
  FreeAndNil(FLibraries);
  DeallocateHWnd(FWndHandle);

  inherited Destroy;

end;

procedure TMKOTaskServices.DoOnTaskInstanceChanged(_Sender: TMKOTaskInstance);
begin
  if Assigned(FOnTaskInstanceChanged) then
    OnTaskInstanceChanged(_Sender);
end;

procedure TMKOTaskServices.DoOnTaskInstancesChanged;
begin
  if Assigned(FOnTaskInstancesChanged) then
    OnTaskInstancesChanged;
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
  if _Message.Msg = WM_TASK_INSTANCE_CHANGED then
    DoOnTaskInstanceChanged(TMKOTaskInstance(_Message.WParam));
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

      procedure (const _File: String)
      begin
        LoadLibrary(_File);
      end

  );

end;

initialization

finalization

  TMKOTaskServices.Finalize;

end.
