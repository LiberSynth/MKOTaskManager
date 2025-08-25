unit uThread;

interface

uses
  { VCL }
  System.Classes, System.SysUtils,
  { TM }
  Common.uUtils, uInterfaces, uConsts;

type

  TMKOTaskThread = class(TThread)

  strict private type

    TBeforeExecuteEvent = procedure of object;
    TAfterExecuteEvent = procedure(_ErrorOccured: Boolean) of object;

  strict private

    FIntf: IMKOTaskInstance;
    FWiteOutIntf: IMKOTaskOutput;
    FBeforeExecute: TBeforeExecuteEvent;
    FAfterExecute: TAfterExecuteEvent;

    procedure DoBeforeExecute;
    procedure DoAfterExecute(_ErrorOccured: Boolean);

    property Intf: IMKOTaskInstance read FIntf;
    property WiteOutIntf: IMKOTaskOutput read FWiteOutIntf;

  protected

    procedure Execute; override;

  public

    constructor Create(_Intf: IMKOTaskInstance; _WiteOutIntf: IMKOTaskOutput); reintroduce;

    property BeforeExecute: TBeforeExecuteEvent read FBeforeExecute write FBeforeExecute;
    property AfterExecute: TAfterExecuteEvent read FAfterExecute write FAfterExecute;

  end;

implementation

{ TMKOTaskThread }

constructor TMKOTaskThread.Create;
begin

  inherited Create(True);

  Priority := tpIdle;

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

  DoBeforeExecute;
  try

    try

      Intf.Execute(WiteOutIntf);
      ErrorOccured := False;

    except
      {TODO 3 -oVasilevSM: Здесь нужно добавить оболочку для обработки исключений. }
      on E: Exception do
      begin

        ErrorOccured := True;
        WiteOutIntf.WriteOut(Format(SC_TASK_EXECUTE_ERROR_MESSAGE, [E.ClassName, E.Message]), -1);

      end;

    end;

  finally
    DoAfterExecute(ErrorOccured);
  end;

end;

end.
