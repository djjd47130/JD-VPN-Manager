program JDVPNMGR;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {frmMain},
  JD.Ras in 'JD.Ras.pas',
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.ShowMainForm:= False;
  Application.Title := 'JD VPN Manager';
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
