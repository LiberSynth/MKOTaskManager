
unit uUtils;

interface

uses
  { VCL }
  System.SysUtils, Vcl.Forms;

function MessageBox(const Caption, Text: String; Buttons, Icon: LongInt): Integer;
function ExeDir: String;

implementation

function MessageBox(const Caption, Text: String; Buttons, Icon: LongInt): Integer;
begin
  Result := Application.MessageBox(PChar(Text), PChar(Caption), Buttons + Icon);
end;

function ExeDir: String;
begin
  Result := ExtractFileDir(ParamStr(0));
end;

end.
