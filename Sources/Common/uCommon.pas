unit uCommon;

interface

uses
  { VCL }
  System.Types,
  { TM }
  uConsts;

function GoldenSize(Width, Height: Integer): TRect;

implementation

function GoldenSize(Width, Height: Integer): TRect;
var
  W, H, L, T: Integer;
begin

  W := Width * 2 div 3;
  H := Round(W / DC_GOLDEN_SECTION);
  L := (Width - W) div 2;
  T := (Height - H) div 2;

  Result := TRect.Create(L, T, L + W, T + H);

end;

end.
