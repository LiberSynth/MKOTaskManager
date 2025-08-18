program MKOTaskManager;

uses
  Vcl.Forms,
  uMain in 'Common\uMain.pas' {fmMain},
  uConsts in 'Common\uConsts.pas',
  uCommon in 'Common\uCommon.pas',
  uLibSupport in 'Utils\uLibSupport.pas',
  uUtils in 'Utils\uUtils.pas',
  uFileExplorer in '..\..\MKOCommon\Utils\uFileExplorer.pas',
  uInterfaces in '..\..\MKOCommon\TaskManager\uInterfaces.pas',
  uTypes in '..\..\MKOCommon\TaskManager\uTypes.pas',
  uGetTextForm in '..\..\MKOCommon\Utils\uGetTextForm.pas' {fmGetTextForm},
  Common.uConsts in '..\..\MKOCommon\Utils\Common.uConsts.pas';

{$R *.res}

begin

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;

end.
