
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
  {TODO 4 -oVasilevSM : Если избавитсья от всех упоминаний Vcl.Forms, фреймворк станет рабочим для
  консольных приложений и служб. (Проверить). }
  Result := Application.MessageBox(PChar(Text), PChar(Caption), Buttons + Icon);
end;

function ExeDir: String;
begin
  Result := ExtractFileDir(ParamStr(0));
end;

end.
