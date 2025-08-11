program MKOTaskManager;

uses
  Vcl.Forms,
  uMain in 'Common\uMain.pas' {fmMain};

{$R *.res}

begin

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;

end.
