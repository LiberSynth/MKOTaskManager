program MKOTaskManager;

uses
  Vcl.Forms,
  uMain in 'Common\uMain.pas' {fmMain},
  uConsts in 'Common\uConsts.pas',
  uCommon in 'Common\uCommon.pas',
  uLibSupport in 'Utils\uLibSupport.pas',
  uUtils in 'Utils\uUtils.pas',
  Common.uFileExplorer in '..\..\MKOCommon\Utils\Common.uFileExplorer.pas',
  Common.uConsts in '..\..\MKOCommon\Utils\Common.uConsts.pas',
  Common.uTypes in '..\..\MKOCommon\TaskManager\Common.uTypes.pas',
  Common.uInterfaces in '..\..\MKOCommon\TaskManager\Common.uInterfaces.pas',
  Common.uGetTextForm in '..\..\MKOCommon\Utils\Common.uGetTextForm.pas' {fmGetTextForm},
  uThread in 'Common\uThread.pas',
  Common.uUtils in '..\..\MKOCommon\Utils\Common.uUtils.pas',
  Common.uFileUtils in '..\..\MKOCommon\Utils\Common.uFileUtils.pas';

{$R *.res}

begin

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;

end.
