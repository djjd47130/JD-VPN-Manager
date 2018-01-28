unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Mask,
  JvExMask, JvSpin, JvComponentBase, JvRas32,
  Vcl.Buttons, Vcl.Menus,
  System.Win.Registry, Vcl.WinXCtrls;

const
  REG_KEY = 'Software\JD Software\JD VPN Manager\';
  RECON_KEY = REG_KEY + 'Auto Reconnect\';
  DEF_RECONNECT_SECS = 20;
  DEF_START_WITH_WINDOWS = tssOn;

type
  TfrmMain = class(TForm)
    Ras: TJvRas32;
    lstConnections: TListView;
    Tmr: TTimer;
    txtReconnectSecs: TJvSpinEdit;
    Label1: TLabel;
    Tray: TTrayIcon;
    TrayMenu: TPopupMenu;
    ShowHide1: TMenuItem;
    ConnectAll1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    chkStartWithWindows: TToggleSwitch;
    Label2: TLabel;
    btnRefresh: TBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure lstConnectionsItemChecked(Sender: TObject; Item: TListItem);
    procedure TmrTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Exit1Click(Sender: TObject);
    procedure ShowHide1Click(Sender: TObject);
    procedure ConnectAll1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure chkStartWithWindowsClick(Sender: TObject);
    procedure txtReconnectSecsChange(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
  private
    FDoClose: Boolean;
    FLoading: Boolean;
    procedure Refresh;
    procedure SavePrefs;
    procedure LoadPrefs;
    procedure EnsureStartWithWindows;
    procedure SaveRecon;
    procedure LoadRecon;
    procedure ConnectByName(const N: String);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FLoading:= True;
  try
    FDoClose:= False;
    Refresh;
    LoadPrefs;
  finally
    FLoading:= False;
  end;
  TmrTimer(nil);
end;

procedure TfrmMain.btnRefreshClick(Sender: TObject);
begin
  Self.Refresh;
  Self.LoadPrefs;
end;

procedure TfrmMain.chkStartWithWindowsClick(Sender: TObject);
begin
  if not FLoading then
    Self.SavePrefs;
end;

procedure TfrmMain.ConnectAll1Click(Sender: TObject);
begin
  Self.TmrTimer(nil);
end;

procedure TfrmMain.Exit1Click(Sender: TObject);
begin
  FDoClose:= True;
  Close;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not FDoClose then
    Action:= TCloseAction.caHide
  else
    SavePrefs;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if not FDoClose then begin
    CanClose:= False;
    Self.Hide;
  end;
end;

procedure TfrmMain.LoadPrefs;
var
  R: TRegistry;
  procedure HandleDefault;
  begin
    txtReconnectSecs.Value:= DEF_RECONNECT_SECS;
    chkStartWithWindows.State:= DEF_START_WITH_WINDOWS;
    SavePrefs;
    if FLoading then begin
      Self.Show;
      Self.BringToFront;
      Application.ProcessMessages;      
    end;
    R.WriteInteger('Configured', 1);
  end;
begin
  R:= TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    R.RootKey:= HKEY_CURRENT_USER;
    if R.KeyExists(REG_KEY) then begin
      if R.OpenKey(REG_KEY, False) then begin
        if R.ValueExists('Configured') and (R.ReadInteger('Configured') = 1) then begin           
          if R.ValueExists('ReconnectSecs') then
            Self.txtReconnectSecs.Value:= R.ReadInteger('ReconnectSecs')
          else
            Self.txtReconnectSecs.Value:= DEF_RECONNECT_SECS;
          Self.txtReconnectSecsChange(nil);
          if R.ValueExists('StartWithWindows') then begin
            if R.ReadBool('StartWithWindows') then
              chkStartWithWindows.State:= TToggleSwitchState.tssOn
            else
              chkStartWithWindows.State:= TToggleSwitchState.tssOff          
          end else begin
            chkStartWithWindows.State:= DEF_START_WITH_WINDOWS;
          end;
          EnsureStartWithWindows;
          LoadRecon;
        end else begin
          HandleDefault;
        end;
      end else begin
        raise Exception.Create('Failed to open registry key to load preferences.');
      end;
    end else begin
      HandleDefault;
    end;
  finally
    R.Free;
  end;
end;

procedure TfrmMain.EnsureStartWithWindows;
var
  R: TRegistry;
begin
  R:= TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    R.RootKey:= HKEY_CURRENT_USER;
    if R.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', False) then begin
      try
        if chkStartWithWindows.IsOn then begin
          R.WriteString('JDVPNMGR', ParamStr(0));
        end else begin
          if R.ValueExists('JDVPNMGR') then
            R.DeleteValue('JDVPNMGR');
        end;
      finally
        R.CloseKey;
      end;
    end else begin
      raise Exception.Create('Failed to open registry key to save windows startup preference.');
    end;
  finally
    R.Free;
  end;
end;

procedure TfrmMain.SavePrefs;
var
  R: TRegistry;
begin
  R:= TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    R.RootKey:= HKEY_CURRENT_USER;
    if R.OpenKey(REG_KEY, True) then begin
      R.WriteInteger('ReconnectSecs', Trunc(txtReconnectSecs.Value));
      R.WriteBool('StartWithWindows', chkStartWithWindows.IsOn);
      EnsureStartWithWindows;
      SaveRecon;
    end else begin
      raise Exception.Create('Failed to open registry key to save preferences.');
    end;
  finally
    R.Free;
  end;
end;

procedure TfrmMain.SaveRecon;
var
  R: TRegistry;
  X: Integer;
begin
  if FLoading then Exit;
  
  R:= TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    R.RootKey:= HKEY_CURRENT_USER;
    if R.KeyExists(RECON_KEY) then
      R.DeleteKey(RECON_KEY);
    if R.OpenKey(RECON_KEY, True) then begin
      try
        for X := 0 to lstConnections.Items.Count-1 do begin
          R.WriteBool(lstConnections.Items[X].Caption, lstConnections.Items[X].Checked);
        end;
      finally
        R.CloseKey;
      end;
    end;
  finally
    R.Free;
  end;
end;

procedure TfrmMain.LoadRecon;
var
  R: TRegistry;
  X: Integer;
  I: TListItem;
begin
  R:= TRegistry.Create(KEY_READ);
  try
    R.RootKey:= HKEY_CURRENT_USER;
    if R.OpenKey(RECON_KEY, False) then begin
      try
        for X := 0 to lstConnections.Items.Count-1 do begin
          I:= lstConnections.Items[X];
          if R.ValueExists(I.Caption) then begin
            I.Checked:= R.ReadBool(I.Caption);
          end else begin
            I.Checked:= False;
          end;
        end;
      finally
        R.CloseKey;
      end;
    end;
  finally
    R.Free;
  end;
end;

procedure TfrmMain.lstConnectionsItemChecked(Sender: TObject; Item: TListItem);
begin
  if not FLoading then
    SavePrefs;
  //Refresh; //EVIL!!! Causes Stack Overflow!!!
end;

procedure TfrmMain.Refresh;
var
  X: Integer;
  I: TListItem;
begin
  Ras.RefreshPhoneBook;
  lstConnections.Items.BeginUpdate;
  try
    lstConnections.Items.Clear;
    for X := 0 to Ras.PhoneBook.Count-1 do begin
      I:= lstConnections.Items.Add;
      I.Caption:= Ras.PhoneBook[X];
    end;
  finally
    lstConnections.Items.EndUpdate;
  end;
  lstConnections.Width:= lstConnections.Width + 1;
  lstConnections.Width:= lstConnections.Width - 1;
end;

procedure TfrmMain.ShowHide1Click(Sender: TObject);
begin
  Show;
  BringToFront;
end;

procedure TfrmMain.TmrTimer(Sender: TObject);
var
  X: Integer;
  I: TListItem;
begin
  try
    for X := 0 to Self.lstConnections.Items.Count-1 do begin
      I:= Self.lstConnections.Items[X];
      if I.Checked then begin
        ConnectByName(I.Caption);
      end;
    end;
  except
    on E: Exception do begin
      //TODO
    end;
  end;
end;

procedure TfrmMain.ConnectByName(const N: String);
var
  R: TJvRas32;
  I: Integer;
begin
  try
    I:= Ras.PhoneBook.IndexOf(N);
    Ras.EntryIndex:= I;
    if not Ras.Connected then begin

      R:= TJvRas32.Create(nil);
      try
        R.KeepConnected:= True;
        R.RefreshPhoneBook;
        I:= R.PhoneBook.IndexOf(N);
        if I >= 0 then begin
          R.Dial(I);
        end;
      finally
        R.Free;
      end;
      
    end;
  except
    on E: Exception do begin
      //TODO: Log error...

    end;
  end;
end;

procedure TfrmMain.txtReconnectSecsChange(Sender: TObject);
begin
  Tmr.Interval:= Trunc(txtReconnectSecs.Value) * 1000;
  if not FLoading then
    Self.SavePrefs;
end;

end.
