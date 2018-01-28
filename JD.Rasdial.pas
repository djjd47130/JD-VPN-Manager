unit JD.Rasdial;

(*
  JD Ras Dial Utilities

  UNDER DEVELOPMENT AND NOT IN USE

  This unit is a custom implementation of the Windows Rasdial API.
  It wraps the API calls defined in JD.RasApi.pas into an
  easy-to-use Delphi component.

  Main Component: TVPNManager
  - Wraps all Windows VPN implementation
  - Populates a list of individual configured VPN connections
  - Provides events to trigger when certain VPN related things occur
  -

*)

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Winapi.Windows, Winapi.Messages,
  Vcl.Controls,
  JD.RasApi;

const
  RADDIAL_DLL_FILENAME = 'RASAPI32.DLL';

type
  TVPNManager = class;
  TVPNConnection = class;

  TVPNConnectionEvent = procedure(Sender: TObject; Connection: TVPNConnection) of object;

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

    FOnRetryAuthentication: TVPNConnectionEvent;
    FOnAllDevicesConnected: TVPNConnectionEvent;
    FOnPortOpened: TVPNConnectionEvent;
    FOnAuthCallback: TVPNConnectionEvent;
    FOnWaitForModemReset: TVPNConnectionEvent;
    FOnOpenPort: TVPNConnectionEvent;
    FOnWaitForCallBack: TVPNConnectionEvent;
    FOnConnected: TVPNConnectionEvent;
    FOnAuthenticated: TVPNConnectionEvent;
    FOnInteractive: TVPNConnectionEvent;
    FOnPrepareForCallback: TVPNConnectionEvent;
    FOnPasswordExpired: TVPNConnectionEvent;
    FOnDisconnected: TVPNConnectionEvent;
    FOnAuthNotify: TVPNConnectionEvent;
    FOnAuthLinkSpeed: TVPNConnectionEvent;
    FOnAuthProject: TVPNConnectionEvent;
    FOnAuthChangePassword: TVPNConnectionEvent;
    FOnDeviceConnected: TVPNConnectionEvent;
    FOnAuthRetry: TVPNConnectionEvent;
    FOnAuthenticate: TVPNConnectionEvent;
    FOnConnectDevice: TVPNConnectionEvent;
    FOnReAuthenticate: TVPNConnectionEvent;
    FOnAuthAck: TVPNConnectionEvent;

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

    property OnOpenPort: TVPNConnectionEvent read FOnOpenPort write FOnOpenPort;
    property OnPortOpened: TVPNConnectionEvent read FOnPortOpened write FOnPortOpened;
    property OnConnectDevice: TVPNConnectionEvent read FOnConnectDevice write FOnConnectDevice;
    property OnDeviceConnected: TVPNConnectionEvent read FOnDeviceConnected write FOnDeviceConnected;
    property OnAllDevicesConnected: TVPNConnectionEvent read FOnAllDevicesConnected write FOnAllDevicesConnected;
    property OnAuthenticate: TVPNConnectionEvent read FOnAuthenticate write FOnAuthenticate;
    property OnAuthNotify: TVPNConnectionEvent read FOnAuthNotify write FOnAuthNotify;
    property OnAuthRetry: TVPNConnectionEvent read FOnAuthRetry write FOnAuthRetry;
    property OnAuthCallback: TVPNConnectionEvent read FOnAuthCallback write FOnAuthCallback;
    property OnAuthChangePassword: TVPNConnectionEvent read FOnAuthChangePassword write FOnAuthChangePassword;
    property OnAuthProject: TVPNConnectionEvent read FOnAuthProject write FOnAuthProject;
    property OnAuthLinkSpeed: TVPNConnectionEvent read FOnAuthLinkSpeed write FOnAuthLinkSpeed;
    property OnAuthAck: TVPNConnectionEvent read FOnAuthAck write FOnAuthAck;
    property OnReAuthenticate: TVPNConnectionEvent read FOnReAuthenticate write FOnReAuthenticate;
    property OnAuthenticated: TVPNConnectionEvent read FOnAuthenticated write FOnAuthenticated;
    property OnPrepareForCallback: TVPNConnectionEvent read FOnPrepareForCallback write FOnPrepareForCallback;
    property OnWaitForModemReset: TVPNConnectionEvent read FOnWaitForModemReset write FOnWaitForModemReset;
    property OnInteractive: TVPNConnectionEvent read FOnInteractive write FOnInteractive;
    property OnRetryAuthentication: TVPNConnectionEvent read FOnRetryAuthentication write FOnRetryAuthentication;
    property OnPasswordExpired: TVPNConnectionEvent read FOnPasswordExpired write FOnPasswordExpired;
    property OnConnected: TVPNConnectionEvent read FOnConnected write FOnConnected;
    property OnDisconnected: TVPNConnectionEvent read FOnDisconnected write FOnDisconnected;
    property OnWaitForCallBack: TVPNConnectionEvent read FOnWaitForCallBack write FOnWaitForCallBack;
  end;

  TVPNConnection = class(TObject)
  private
    FOwner: TVPNManager;
    //FConn: TRASConn;
    FTitle: String;
    FUsername: String;
    FPassword: String;
    FDomain: String;
    FCallBackNumber: String;
    FPhoneNumber: String;

    FConnected: Boolean;
    procedure SetTitle(const Value: String);
    procedure SetConnected(const Value: Boolean);
    procedure GetInfo;
  public
    constructor Create(AOwner: TVPNManager);
    destructor Destroy; override;
    property Title: String read FTitle write SetTitle;
    property Connected: Boolean read FConnected write SetConnected;
  end;

implementation

const
  cUtilWindowExClass: TWndClass = (
    style: 0;
    lpfnWndProc: nil;
    cbClsExtra: 0;
    cbWndExtra: SizeOf(TMethod);
    hInstance: 0;
    hIcon: 0;
    hCursor: 0;
    hbrBackground: 0;
    lpszMenuName: nil;
    lpszClassName: 'TPUtilWindowEx');

function StdWndProc(Window: THandle; Message, WParam: WPARAM;
  LParam: LPARAM): LRESULT; stdcall;
var
  Msg: Winapi.Messages.TMessage;
  WndProc: TWndMethod;
begin
  TMethod(WndProc).Code := Pointer(GetWindowLongPtr(Window, 0));
  TMethod(WndProc).Data := Pointer(GetWindowLongPtr(Window, SizeOf(Pointer)));
  if Assigned(WndProc) then
  begin
    Msg.Msg := Message;
    Msg.WParam := WParam;
    Msg.LParam := LParam;
    Msg.Result := 0;
    WndProc(Msg);
    Result := Msg.Result;
  end
  else
    Result := DefWindowProc(Window, Message, WParam, LParam);
end;

function AllocateHWndEx(Method: TWndMethod; const AClassName: string = ''): THandle;
var
  TempClass: TWndClass;
  UtilWindowExClass: TWndClass;
  ClassRegistered: Boolean;
begin
  UtilWindowExClass := cUtilWindowExClass;
  UtilWindowExClass.hInstance := HInstance;
  UtilWindowExClass.lpfnWndProc := @DefWindowProc;
  if AClassName <> '' then
    UtilWindowExClass.lpszClassName := PChar(AClassName);

  ClassRegistered := Winapi.Windows.GetClassInfo(HInstance, UtilWindowExClass.lpszClassName,
    TempClass);
  if not ClassRegistered or (TempClass.lpfnWndProc <> @DefWindowProc) then
  begin
    if ClassRegistered then
      Winapi.Windows.UnregisterClass(UtilWindowExClass.lpszClassName, HInstance);
    Winapi.Windows.RegisterClass(UtilWindowExClass);
  end;
  Result := Winapi.Windows.CreateWindowEx(Winapi.Windows.WS_EX_TOOLWINDOW, UtilWindowExClass.lpszClassName,
    '', Winapi.Windows.WS_POPUP, 0, 0, 0, 0, 0, 0, HInstance, nil);

  if Assigned(Method) then
  begin
    SetWindowLongPtr(Result, 0, LONG_PTR(TMethod(Method).Code));
    SetWindowLongPtr(Result, SizeOf(TMethod(Method).Code), LONG_PTR(TMethod(Method).Data));
    SetWindowLongPtr(Result, GWLP_WNDPROC, LONG_PTR(@StdWndProc));
  end;
end;




{ TVPNManager }

constructor TVPNManager.Create(AOwner: TComponent);
begin
  inherited;
  FConnections:= TObjectList<TVPNConnection>.Create(True);
  FKeepConnected := False;
  FPhoneBookPath := '';

  //Acquire owner handle...
  if AOwner is TWinControl then
    FPHandle := (AOwner as TWinControl).Handle
  else
    FPHandle := GetForegroundWindow; //TODO: Is this safe?

  //Load Rasdial Library...
  FDll := SafeLoadLibrary(RADDIAL_DLL_FILENAME);
  if FDll <> 0 then begin

    //Acquire procedure addresses...
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

    //Prepare events...
    FHandle := AllocateHWndEx(WndProc);
    FRASEvent := RegisterWindowMessage(RASDialEvent);
    if FRASEvent = 0 then
      FRASEvent := WM_RASDialEvent;

  end;

  //Check if Ras is available at all...
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
  //TODO: Identify connection...
  for X := 0 to FConnections.Count-1 do begin


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
  if RasAvailable then begin
    FConnections.Clear;
    if Assigned(FRasEnumEntries) then begin
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
      //Populate list of VPN connections...
      for I := 0 to Entries-1 do begin
        if (RASEntryName[I].szEntryName[0] <> #0) then begin
          C:= TVPNConnection.Create(Self);
          try
            C.FTitle:= StrPas(RASEntryName[I].szEntryName);
            C.GetInfo;
          finally
            FConnections.Add(C);
          end;
        end;
      end;
    end;
  end;
end;

{ TVPNConnection }

constructor TVPNConnection.Create(AOwner: TVPNManager);
begin
  FOwner:= AOwner;

end;

destructor TVPNConnection.Destroy;
begin

  inherited;
end;

procedure TVPNConnection.SetConnected(const Value: Boolean);
begin
  //TODO: Connect or disconnect VPN...

  FConnected := Value;
end;

procedure TVPNConnection.SetTitle(const Value: String);
begin
  //TODO: Check if in edit mode.....
  FTitle := Value;
end;

procedure TVPNConnection.GetInfo;
var
  RasDialParams: TRASDialParams;
  Res: LongBool;
begin
  //Fetch detailed information about this VPN connection...
  FillChar(RasDialParams, SizeOf(TRASDialParams), #0);
  StrLCopy(RasDialParams.szEntryName, PChar(FTitle), RAS_MAXENTRYNAME);
  RasDialParams.dwSize := SizeOf(TRASDialParams);
  if Assigned(FOwner.FRasGetEntryDialParams) then
    if FOwner.FRasGetEntryDialParams(nil, RasDialParams, Res) = 0 then
      with RasDialParams do begin
        FUsername := StrPas(szUserName);
        FPassword := StrPas(szPassword);
        FDomain := StrPas(szDomain);
        FCallBackNumber := StrPas(szCallbackNumber);
        FPhoneNumber := StrPas(szPhoneNumber);
      end;

end;

end.
