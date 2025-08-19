unit uLibSupport;

interface

uses
  { VCL }
  System.SysUtils, Generics.Collections, Winapi.Windows, System.SyncObjs,
  { Common }
  uInterfaces, uFileExplorer,
  { TM }
  uUtils, uTypes, uThread, uConsts;

type

  TTaskInstanceState = (tsCreated, tsProcessing, tsFinished, tsCanceled, tsError);

  TTaskInstanceStateHelper = record helper for TTaskInstanceState

  public

    function ToStr: String;

  end;

  TMKOTask = class;

  TMKOTaskInstance = class

  strict private

    FTask: TMKOTask;
    FIntf: IMKOTaskInstance;
    FThread: TMKOTaskThread;
    FParams: String;
    FState: TTaskInstanceState;
    FDate: TDateTime;
    FStateLocker: TCriticalSection;

    function GetState: TTaskInstanceState;
    procedure SetState(const _Value: TTaskInstanceState);

    procedure CreateThread;
    procedure ThreadOnExecute;
    procedure ThreadOnTerminate(_Sender: TObject);

    property Intf: IMKOTaskInstance read FIntf;
    property Thread: TMKOTaskThread read FThread;
    property StateLocker: TCriticalSection read FStateLocker;

  private

    constructor Create(

        _MKOTask: TMKOTask;
        const _Params: String

    ); reintroduce;

  public

    destructor Destroy; override;

    procedure Terminate;

    property Task: TMKOTask read FTask;
    property Params: String read FParams;
    property State: TTaskInstanceState read GetState write SetState;
    property Date: TDateTime read FDate;

  end;

  TMKOTask = class

  strict private

    FIntf: IMKOTask;

  public

    constructor Create(const _Intf: IMKOTask); reintroduce;

    procedure StartTask(const _Params: String);

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

  TMKOTaskInstanceList = class(TList<TMKOTaskInstance>);

  TMKOTaskServices = class

  strict private type

    TTaskInstancesChangedProc = procedure of object;

  strict private

    class var FInstance: TMKOTaskServices;
    class var FFinalized: Boolean;

    class property Finalized: Boolean read FFinalized;

  strict private

    FLibraries: TMKOLibraryList;
    FTaskInstance: TMKOTaskInstanceList;
    FOnTaskInstancesChanged: TTaskInstancesChangedProc;

    function GetTaskCount: Integer;

    procedure LoadLibrary(const _File: String);

  private

    constructor Create;

    class function Instance: TMKOTaskServices;
    class procedure Finalize;

    procedure FinalizeLibraries;

    procedure AddTaskInstance(_TaskInstance: TMKOTaskInstance);
    procedure DoOnTaskInstancesChanged;

  public

    destructor Destroy; override;

    procedure LoadLibraries;

    property Libraries: TMKOLibraryList read FLibraries;
    property TaskInstances: TMKOTaskInstanceList read FTaskInstance;
    property TaskCount: Integer read GetTaskCount;
    property OnTaskInstancesChanged: TTaskInstancesChangedProc read FOnTaskInstancesChanged write FOnTaskInstancesChanged;

  end;

function TaskServices: TMKOTaskServices;

implementation

function TaskServices: TMKOTaskServices;
begin
  Result := TMKOTaskServices.Instance;
end;

{ TMKOTaskInstance }

constructor TMKOTaskInstance.Create;
begin

  inherited Create;

  FTask   := _MKOTask;
  FParams := _Params;
  FDate   := Now;

  FStateLocker := TCriticalSection.Create;
  CreateThread;

end;

procedure TMKOTaskInstance.CreateThread;
begin

  FIntf := Task.Intf.StartTask(Params);
  FThread := TMKOTaskThread.Create(Intf);

  FThread.OnExecute := ThreadOnExecute;
  FThread.OnTerminate := ThreadOnTerminate;

  FThread.Start;

end;

destructor TMKOTaskInstance.Destroy;
begin
  FreeAndNil(FStateLocker);
  inherited Destroy;
end;

function TMKOTaskInstance.GetState: TTaskInstanceState;
begin

  StateLocker.Acquire;
  try

    Result := FState;

  finally
    StateLocker.Release;
  end;

end;

procedure TMKOTaskInstance.SetState(const _Value: TTaskInstanceState);
begin

  StateLocker.Acquire;
  try

    if FState <> _Value then
    begin

      FState := _Value;
      {TODO 1 -oVasilevSM : Где-то здесь надо триггернуть DataChanged листа с параметром "я". }

    end;

  finally
    StateLocker.Release;
  end;

end;

procedure TMKOTaskInstance.Terminate;
begin
  Intf.Terminate;
  Thread.Terminate;
end;

procedure TMKOTaskInstance.ThreadOnExecute;
begin
  State := tsProcessing;
end;

procedure TMKOTaskInstance.ThreadOnTerminate(_Sender: TObject);
begin
  State := tsCanceled;
end;

{ TMKOTask }

constructor TMKOTask.Create;
begin
  inherited Create;
  FIntf := _Intf;
end;

procedure TMKOTask.StartTask(const _Params: String);
var
  Params: WideString;
begin

  Params := _Params;
  Intf.ValidateParams(Params);
  TaskServices.AddTaskInstance(TMKOTaskInstance.Create(Self, Params));

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

procedure TMKOTaskServices.AddTaskInstance(_TaskInstance: TMKOTaskInstance);
begin
  TaskInstances.Add(_TaskInstance);
  DoOnTaskInstancesChanged;
end;

constructor TMKOTaskServices.Create;
begin

  inherited Create;

  FLibraries := TMKOLibraryList.Create;
  FTaskInstance := TMKOTaskInstanceList.Create;

end;

destructor TMKOTaskServices.Destroy;
begin

  FreeAndNil(FTaskInstance);
  FreeAndNil(FLibraries);

  inherited Destroy;

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
    Instance.FinalizeLibraries;
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

{ TTaskInstanceStateHelper }

function TTaskInstanceStateHelper.ToStr: String;
begin

  case Self of

    tsCreated:    Result := SC_TASK_ITEM_STATE_CREATED_CAPTION;
    tsProcessing: Result := SC_TASK_ITEM_STATE_PROCESSING_CAPTION;
    tsFinished:   Result := SC_TASK_ITEM_STATE_FINISHED_CAPTION;
    tsCanceled:   Result := SC_TASK_ITEM_STATE_CANCELED_CAPTION;
    tsError:      Result := SC_TASK_ITEM_STATE_ERROR_CAPTION

  else
    raise EMKOTMException.Create('Complete this method.');
  end;

end;

initialization

finalization

  TMKOTaskServices.Finalize;

end.
