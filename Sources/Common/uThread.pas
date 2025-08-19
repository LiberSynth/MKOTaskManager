unit uThread;

interface

uses
  { VCL }
  System.Classes,
  { TM }
  Common.uUtils, uInterfaces;

type

  TMKOTaskThreadOnExecute = procedure of object;

  TMKOTaskThread = class(TThread)

  strict private

    FIntf: IMKOTaskInstance;
    FOnExecute: TMKOTaskThreadOnExecute;

    procedure DoOnExecute;

    property Intf: IMKOTaskInstance read FIntf;

  protected

    procedure Execute; override;

  public

    constructor Create(_Intf: IMKOTaskInstance); reintroduce;

    property OnExecute: TMKOTaskThreadOnExecute read FOnExecute write FOnExecute;

  end;

implementation

{ TMKOTaskThread }

constructor TMKOTaskThread.Create;
begin
  inherited Create(True);
  FIntf := _Intf;
end;

procedure TMKOTaskThread.DoOnExecute;
begin
  if Assigned(FOnExecute) then
    OnExecute;
end;

procedure TMKOTaskThread.Execute;
begin

  DoOnExecute;
  Intf.Execute;

end;

end.
