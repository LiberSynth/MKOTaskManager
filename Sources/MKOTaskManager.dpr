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
  uTypes in 'Common\uTypes.pas';

{$R *.res}

begin

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;

end.
