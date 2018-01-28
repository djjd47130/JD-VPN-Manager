program JDVPNMGR;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {frmMain},
  JD.Rasdial in 'JD.Rasdial.pas',
  Vcl.Themes,
  Vcl.Styles,
  JD.RasApi in 'JD.RasApi.pas';

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
