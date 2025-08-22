unit uThread;

interface

uses
  { VCL }
  System.Classes,
  { TM }
  Common.uUtils, uInterfaces;

type

  TMKOTaskThread = class(TThread)

  strict private type

    TBeforeExecuteEvent = procedure of object;
    TAfterExecuteEvent = procedure(_ErrorOccured: Boolean) of object;

  strict private

    FIntf: IMKOTaskInstance;
    FWiteOutIntf: IMKOTaskWiteOut;
    FBeforeExecute: TBeforeExecuteEvent;
    FAfterExecute: TAfterExecuteEvent;

    procedure DoBeforeExecute;
    procedure DoAfterExecute(_ErrorOccured: Boolean);

    property Intf: IMKOTaskInstance read FIntf;
    property WiteOutIntf: IMKOTaskWiteOut read FWiteOutIntf;

  protected

    procedure Execute; override;

  public

    constructor Create(_Intf: IMKOTaskInstance; _WiteOutIntf: IMKOTaskWiteOut); reintroduce;

    property BeforeExecute: TBeforeExecuteEvent read FBeforeExecute write FBeforeExecute;
    property AfterExecute: TAfterExecuteEvent read FAfterExecute write FAfterExecute;

  end;

implementation

{ TMKOTaskThread }

constructor TMKOTaskThread.Create;
begin

  inherited Create(True);

  FIntf := _Intf;
  FWiteOutIntf := _WiteOutIntf;

end;

procedure TMKOTaskThread.DoAfterExecute(_ErrorOccured: Boolean);
begin
  if Assigned(FAfterExecute) then
    AfterExecute(_ErrorOccured);
end;

procedure TMKOTaskThread.DoBeforeExecute;
begin
  if Assigned(FBeforeExecute) then
    BeforeExecute;
end;

procedure TMKOTaskThread.Execute;
var
  ErrorOccured: Boolean;
begin

  ErrorOccured := False;

  DoBeforeExecute;
  try

    try

      Intf.Execute(WiteOutIntf);

    except
      ErrorOccured := True;
    end;

  finally
    DoAfterExecute(ErrorOccured);
  end;

end;

end.
