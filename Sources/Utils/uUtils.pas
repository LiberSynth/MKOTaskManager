
unit uUtils;

interface

uses
  { VCL }
  System.SysUtils, System.Classes;

function ExeDir: String;

implementation

function ExeDir: String;
begin
  Result := ExtractFileDir(ParamStr(0));
end;

end.
