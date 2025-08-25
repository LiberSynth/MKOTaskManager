
unit uUtils;

interface

uses
  { VCL }
  System.SysUtils, Vcl.Forms;

function MessageBox(const Caption, Text: String; Buttons, Icon: LongInt): Integer;

implementation

function MessageBox(const Caption, Text: String; Buttons, Icon: LongInt): Integer;
begin
  Result := Application.MessageBox(PChar(Text), PChar(Caption), Buttons + Icon);
end;

end.
