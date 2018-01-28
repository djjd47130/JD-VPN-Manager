unit JD.Ras;

(*
  JD Ras Dial Utilities

  UNDER DEVELOPMENT AND NOT IN USE

*)

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Winapi.Windows, Winapi.Messages,
  Vcl.Controls,
  Ras32;

const
  RsRasDllName = 'RASAPI32.DLL';

type
  TVPNManager = class;
  TVPNConnection = class;



  TVPNManager = class(TComponent)
  private
    FHandle: THandle;
    FPHandle: THandle;
    FDll: THandle;
    FRASEvent: Word;
    FConnections: TObjectList<TVPNConnection>;
    FPhoneBookPath: TFilename;
    FAvailable: Boolean;
    FKeepConnected: Boolean;
    FRasDial: TRasDial;
    FRasEnumConnections: TRasEnumConnections;
    FRasEnumEntries: TRasEnumEntries;
    FRasGetConnectStatus: TRasGetConnectStatus;
    FRasGetErrorstring: TRasGetErrorstring;
    FRasHangUp: TRasHangUp;
    FRasGetEntryDialParams: TRasGetEntryDialParams;
    FRasValidateEntryName: TRasValidateEntryName;
    FRasCreatePhonebookEntry: TRasCreatePhonebookEntry;
    FRasEditPhonebookEntry: TRasEditPhonebookEntry;
    FOnRetryAuthentication: TNotifyEvent;
    FOnAllDevicesConnected: TNotifyEvent;
    FOnPortOpened: TNotifyEvent;
    FOnAuthCallback: TNotifyEvent;
    FOnWaitForModemReset: TNotifyEvent;
    FOnOpenPort: TNotifyEvent;
    FOnWaitForCallBack: TNotifyEvent;
    FOnConnected: TNotifyEvent;
    FOnAuthenticated: TNotifyEvent;
    FOnInteractive: TNotifyEvent;
    FOnPrepareForCallback: TNotifyEvent;
    FOnPasswordExpired: TNotifyEvent;
    FOnDisconnected: TNotifyEvent;
    FOnAuthNotify: TNotifyEvent;
    FOnAuthLinkSpeed: TNotifyEvent;
    FOnAuthProject: TNotifyEvent;
    FOnAuthChangePassword: TNotifyEvent;
    FOnDeviceConnected: TNotifyEvent;
    FOnAuthRetry: TNotifyEvent;
    FOnAuthenticate: TNotifyEvent;
    FOnConnectDevice: TNotifyEvent;
    FOnReAuthenticate: TNotifyEvent;
    FOnAuthAck: TNotifyEvent;
    procedure SetPhoneBookPath(const Value: TFilename);
    procedure WndProc(var Msg: TMessage);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RefreshConnections;
    function ConnectionCount: Integer;
    property RasAvailable: Boolean read FAvailable;
  published
    property PhoneBookPath: TFilename read FPhoneBookPath write SetPhoneBookPath;
    property KeepConnected: Boolean read FKeepConnected write FKeepConnected default False;

    property OnOpenPort: TNotifyEvent read FOnOpenPort write FOnOpenPort;
    property OnPortOpened: TNotifyEvent read FOnPortOpened write FOnPortOpened;
    property OnConnectDevice: TNotifyEvent read FOnConnectDevice write FOnConnectDevice;
    property OnDeviceConnected: TNotifyEvent read FOnDeviceConnected write FOnDeviceConnected;
    property OnAllDevicesConnected: TNotifyEvent read FOnAllDevicesConnected write FOnAllDevicesConnected;
    property OnAuthenticate: TNotifyEvent read FOnAuthenticate write FOnAuthenticate;
    property OnAuthNotify: TNotifyEvent read FOnAuthNotify write FOnAuthNotify;
    property OnAuthRetry: TNotifyEvent read FOnAuthRetry write FOnAuthRetry;
    property OnAuthCallback: TNotifyEvent read FOnAuthCallback write FOnAuthCallback;
    property OnAuthChangePassword: TNotifyEvent read FOnAuthChangePassword write FOnAuthChangePassword;
    property OnAuthProject: TNotifyEvent read FOnAuthProject write FOnAuthProject;
    property OnAuthLinkSpeed: TNotifyEvent read FOnAuthLinkSpeed write FOnAuthLinkSpeed;
    property OnAuthAck: TNotifyEvent read FOnAuthAck write FOnAuthAck;
    property OnReAuthenticate: TNotifyEvent read FOnReAuthenticate write FOnReAuthenticate;
    property OnAuthenticated: TNotifyEvent read FOnAuthenticated write FOnAuthenticated;
    property OnPrepareForCallback: TNotifyEvent read FOnPrepareForCallback write FOnPrepareForCallback;
    property OnWaitForModemReset: TNotifyEvent read FOnWaitForModemReset write FOnWaitForModemReset;
    property OnInteractive: TNotifyEvent read FOnInteractive write FOnInteractive;
    property OnRetryAuthentication: TNotifyEvent read FOnRetryAuthentication write FOnRetryAuthentication;
    property OnPasswordExpired: TNotifyEvent read FOnPasswordExpired write FOnPasswordExpired;
    property OnConnected: TNotifyEvent read FOnConnected write FOnConnected;
    property OnDisconnected: TNotifyEvent read FOnDisconnected write FOnDisconnected;
    property OnWaitForCallBack: TNotifyEvent read FOnWaitForCallBack write FOnWaitForCallBack;
  end;

  TVPNConnection = class(TObject)
  private
    //FConn: TRASConn;
    FTitle: String;
    FConnected: Boolean;
    procedure SetTitle(const Value: String);
    procedure SetConnected(const Value: Boolean);
  public
    property Title: String read FTitle write SetTitle;
    property Connected: Boolean read FConnected write SetConnected;
  end;

implementation

uses
  JvJVCLUtils;

{ TVPNManager }

constructor TVPNManager.Create(AOwner: TComponent);
begin
  inherited;
  FConnections:= TObjectList<TVPNConnection>.Create(True);
  FKeepConnected := False;
  FPhoneBookPath := '';
  //FPassword := '';
  //FDeviceName := '';
  //FUsername := '';
  //FEntry := '';
  //FDeviceType := '';
  //FPhoneNumber := '';
  //FCallBackNumber := '';
  //FDomain := '';
  //FConnection := 0;
  if AOwner is TWinControl then
    FPHandle := (AOwner as TWinControl).Handle
  else
    // (rom) is this safe?
    FPHandle := GetForegroundWindow;
  //FEntryIndex := -1;

  FDll := SafeLoadLibrary(RsRasDllName);
  if FDll <> 0 then
  begin
    FRasDial := GetProcAddress(FDll, {$IFDEF UNICODE}'RasDialW'{$ELSE}'RasDialA'{$ENDIF UNICODE});
    FRasEnumConnections := GetProcAddress(FDll, {$IFDEF UNICODE}'RasEnumConnectionsW'{$ELSE}'RasEnumConnectionsA'{$ENDIF UNICODE});
    FRasEnumEntries := GetProcAddress(FDll, {$IFDEF UNICODE}'RasEnumEntriesW'{$ELSE}'RasEnumEntriesA'{$ENDIF UNICODE});
    FRasGetConnectStatus := GetProcAddress(FDll, {$IFDEF UNICODE}'RasGetConnectStatusW'{$ELSE}'RasGetConnectStatusA'{$ENDIF UNICODE});
    FRasGetErrorstring := GetProcAddress(FDll, {$IFDEF UNICODE}'RasGetErrorstringW'{$ELSE}'RasGetErrorstringA'{$ENDIF UNICODE});
    FRasHangUp := GetProcAddress(FDll, {$IFDEF UNICODE}'RasHangUpW'{$ELSE}'RasHangUpA'{$ENDIF UNICODE});
    FRasGetEntryDialParams := GetProcAddress(FDll, {$IFDEF UNICODE}'RasGetEntryDialParamsW'{$ELSE}'RasGetEntryDialParamsA'{$ENDIF UNICODE});
    FRasValidateEntryName := GetProcAddress(FDll, {$IFDEF UNICODE}'RasValidateEntryNameW'{$ELSE}'RasValidateEntryNameA'{$ENDIF UNICODE});
    FRasCreatePhonebookEntry := GetProcAddress(FDll, {$IFDEF UNICODE}'RasCreatePhonebookEntryW'{$ELSE}'RasCreatePhonebookEntryA'{$ENDIF UNICODE});
    FRasEditPhonebookEntry := GetProcAddress(FDll, {$IFDEF UNICODE}'RasEditPhonebookEntryW'{$ELSE}'RasEditPhonebookEntryA'{$ENDIF UNICODE});

    FHandle := JvJVCLUtils.AllocateHWndEx(WndProc);
    FRASEvent := RegisterWindowMessage(RASDialEvent);
    if FRASEvent = 0 then
      FRASEvent := WM_RASDialEvent;

  end;
  FAvailable := (FDll <> 0) and Assigned(FRasDial);
end;

destructor TVPNManager.Destroy;
begin

  FreeAndNil(FConnections);
  inherited;
end;

procedure TVPNManager.WndProc(var Msg: TMessage);
var
  X: Integer;
begin
  for X := 0 to Self.FConnections.Count-1 do begin


  end;

  {
  if (Msg.Msg = FRASEvent) and (FConnection <> 0) then
  begin
    case Msg.WParam of
      RASCS_OpenPort:
        if Assigned(FOnOpenPort) then
          FOnOpenPort(Self);
      RASCS_PortOpened:
        if Assigned(FOnPortOpened) then
          FOnPortOpened(Self);
      RASCS_ConnectDevice:
        if Assigned(FOnConnectDevice) then
          FOnConnectDevice(Self);
      RASCS_DeviceConnected:
        if Assigned(FOnDeviceConnected) then
          FOnDeviceConnected(Self);
      RASCS_AllDevicesConnected:
        if Assigned(FOnAllDevicesConnected) then
          FOnAllDevicesConnected(Self);
      RASCS_Authenticate:
        if Assigned(FOnAuthenticate) then
          FOnAuthenticate(Self);
      RASCS_AuthNotify:
        if Assigned(FOnAuthNotify) then
          FOnAuthNotify(Self);
      RASCS_AuthRetry:
        if Assigned(FOnAuthRetry) then
          FOnAuthRetry(Self);
      RASCS_AuthCallback:
        if Assigned(FOnAuthCallback) then
          FOnAuthCallback(Self);
      RASCS_AuthChangePassword:
        if Assigned(FOnAuthChangePassword) then
          FOnAuthChangePassword(Self);
      RASCS_AuthProject:
        if Assigned(FOnAuthProject) then
          FOnAuthProject(Self);
      RASCS_AuthLinkSpeed:
        if Assigned(FOnAuthLinkSpeed) then
          FOnAuthLinkSpeed(Self);
      RASCS_AuthAck:
        if Assigned(FOnAuthAck) then
          FOnAuthAck(Self);
      RASCS_ReAuthenticate:
        if Assigned(FOnReAuthenticate) then
          FOnReAuthenticate(Self);
      RASCS_Authenticated:
        if Assigned(FOnAuthenticated) then
          FOnAuthenticated(Self);
      RASCS_PrepareForCallback:
        if Assigned(FOnPrepareForCallback) then
          FOnPrepareForCallback(Self);
      RASCS_WaitForModemReset:
        if Assigned(FOnWaitForModemReset) then
          FOnWaitForModemReset(Self);
      RASCS_Interactive:
        if Assigned(FOnInteractive) then
          FOnInteractive(Self);
      RASCS_RetryAuthentication:
        if Assigned(FOnRetryAuthentication) then
          FOnRetryAuthentication(Self);
      RASCS_PasswordExpired:
        if Assigned(FOnPasswordExpired) then
          FOnPasswordExpired(Self);
      RASCS_Connected:
        if Assigned(FOnConnected) then
          FOnConnected(Self);
      RASCS_DisConnected:
        if Assigned(FOnDisconnected) then
          FOnDisconnected(Self);
      RASCS_WaitForCallBack:
        if Assigned(FOnWaitForCallBack) then
          FOnWaitForCallBack(Self);
    end;
  end
  else
  }
    Msg.Result := DefWindowProc(FHandle, Msg.Msg, Msg.WParam, Msg.LParam);
end;

function TVPNManager.ConnectionCount: Integer;
begin
  Result:= FConnections.Count;
end;

procedure TVPNManager.SetPhoneBookPath(const Value: TFilename);
begin
  FPhoneBookPath := Value;
end;

procedure TVPNManager.RefreshConnections;
var
  RASEntryName: array of TRasEntryName;
  Ret, I, BufSize, Entries: DWORD;
  C: TVPNConnection;
begin
  { Build internal copy. }

  if RasAvailable then
  begin

    FConnections.Clear;

    if Assigned(FRasEnumEntries) then
    begin
      // We enumerate the RAS entries in a loop which allows us to use
      // a dynamic array rather than a static one that may not be big
      // enough to contain all the entries (Mantis 5079).
      // We start with 50 which should be fine on most systems
      repeat
        SetLength(RASEntryName, Length(RASEntryName) + 50);
        BufSize := Length(RASEntryName) * SizeOf(RASEntryName[0]);
        RASEntryName[0].dwSize := SizeOf(RASEntryName[0]);
        if FPhoneBookPath <> '' then
          Ret := FRasEnumEntries(nil, PChar(FPhoneBookPath), @RASEntryName[0], BufSize, Entries)
        else
          Ret := FRasEnumEntries(nil, nil, @RASEntryName[0], BufSize, Entries);
      until Ret <> ERROR_BUFFER_TOO_SMALL;

      if Ret <> ERROR_SUCCESS then
        raise Exception.CreateFmt('Unable to enumerate RAS entries, Error code is %d', [Ret]);

      I := 0;
      while I < Entries do
      begin
        C:= TVPNConnection.Create;
        try
          if (RASEntryName[I].szEntryName[0] <> #0) then begin
            C.FTitle:= StrPas(RASEntryName[I].szEntryName);
            FConnections.Add(C);
          end;
        finally
          Inc(I);
        end;
      end;
    end;

  end;
end;

{ TVPNConnection }

procedure TVPNConnection.SetConnected(const Value: Boolean);
begin
  //TODO...

  FConnected := Value;
end;

procedure TVPNConnection.SetTitle(const Value: String);
begin
  //TODO: Check if in edit mode.....
  FTitle := Value;
end;

end.
