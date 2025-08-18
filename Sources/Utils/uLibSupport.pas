unit uLibSupport;

interface

uses
  { VCL }
  System.SysUtils, Generics.Collections, Winapi.Windows,
  { Common }
  uInterfaces, uFileExplorer,
  { TM }
  uUtils, uTypes;

type

  TMKOTask = class

  strict private

    FIntf: IMKOTask;

  public

    constructor Create(const _Intf: IMKOTask); reintroduce;

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

  strict private

    class var FInstance: TMKOTaskServices;
    class var FFinalized: Boolean;

    class property Finalized: Boolean read FFinalized;

  strict private

    FLibraries: TMKOLibraryList;

    function GetTaskCount: Integer;

    procedure LoadLibrary(const _File: String);

  private

    constructor Create;

    class function Instance: TMKOTaskServices;
    class procedure Finalize;

    procedure FinalizeLibraries;

  public

    destructor Destroy; override;

    procedure LoadLibraries;

    property Libraries: TMKOLibraryList read FLibraries;
    property TaskCount: Integer read GetTaskCount;

  end;

function TaskServices: TMKOTaskServices;

implementation

function TaskServices: TMKOTaskServices;
begin
  Result := TMKOTaskServices.Instance;
end;

{ TMKOTask }

constructor TMKOTask.Create;
begin
  inherited Create;
  FIntf := _Intf;
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

constructor TMKOTaskServices.Create;
begin
  inherited Create;
  FLibraries := TMKOLibraryList.Create;
end;

destructor TMKOTaskServices.Destroy;
begin
  FreeAndNil(FLibraries);
  inherited Destroy;
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

initialization

finalization

  TMKOTaskServices.Finalize;

end.
