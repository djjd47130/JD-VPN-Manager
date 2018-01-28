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

type
  TVPNManager = class;
  TVPNConnection = class;

  TVPNConnectionEvent = procedure(Sender: TObject; Connection: TVPNConnection) of object;

  TVPNManager = class(TComponent)
  private
    FRasApi: TRasApi;

    FConnections: TObjectList<TVPNConnection>;
    FPhoneBookPath: TFilename;
    FKeepConnected: Boolean;

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
    function GetAvailable: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RefreshConnections;
    function ConnectionCount: Integer;
    property RasAvailable: Boolean read GetAvailable;
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
    FConn: TRASConn;
    FTitle: String;
    FUsername: String;
    FPassword: String;
    FDomain: String;
    FCallBackNumber: String;
    FPhoneNumber: String;
    procedure SetTitle(const Value: String);
    procedure SetConnected(const Value: Boolean);
    procedure GetInfo;
    function GetConnected: Boolean;
    function GetStatus: TRASConnStatus;
    function GetDialParams: TRASDialParams;
  public
    constructor Create(AOwner: TVPNManager);
    destructor Destroy; override;
    property Title: String read FTitle write SetTitle;
    property Connected: Boolean read GetConnected write SetConnected;
  end;

implementation

{ TVPNManager }

constructor TVPNManager.Create(AOwner: TComponent);
begin
  inherited;
  FConnections:= TObjectList<TVPNConnection>.Create(True);
  FKeepConnected := False;
  FPhoneBookPath := '';

  FRasApi:= CreateRasApi(Self, WndProc);

end;

destructor TVPNManager.Destroy;
begin
  if FRasApi.Available then begin
    try
      if not KeepConnected then begin
        //HangUp;
        //TODO: Hang up all connections...???
        //  Actually this should be implemented on each one.

      end;
    except
    end;
  end;
  DestroyRasApi(FRasApi);
  FreeAndNil(FConnections);
  inherited;
end;

function TVPNManager.GetAvailable: Boolean;
begin
  Result:= FRasApi.Available;
end;

function TVPNManager.ConnectionCount: Integer;
begin
  Result:= FConnections.Count;
end;

procedure TVPNManager.SetPhoneBookPath(const Value: TFilename);
begin
  FPhoneBookPath := Value;
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
    Msg.Result := DefWindowProc(FRasApi.Handle, Msg.Msg, Msg.WParam, Msg.LParam);
end;

procedure TVPNManager.RefreshConnections;
const
  GROW_SIZE = 50;
var
  RASEntryName: array of TRasEntryName;
  Ret, I, BufSize, Entries: DWORD;
  C: TVPNConnection;
begin
  if RasAvailable then begin
    FConnections.Clear;
    if Assigned(FRasApi.EnumEntries) then begin
      repeat
        SetLength(RASEntryName, Length(RASEntryName) + GROW_SIZE);
        BufSize := Length(RASEntryName) * SizeOf(RASEntryName[0]);
        RASEntryName[0].dwSize := SizeOf(RASEntryName[0]);
        if FPhoneBookPath <> '' then
          Ret := FRasApi.EnumEntries(nil, PChar(FPhoneBookPath), @RASEntryName[0], BufSize, Entries)
        else
          Ret := FRasApi.EnumEntries(nil, nil, @RASEntryName[0], BufSize, Entries);
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
  if Value then begin
    //Connect...

  end else begin
    //Disconnect...

  end;
end;

procedure TVPNConnection.SetTitle(const Value: String);
begin
  //TODO: Check if in edit mode.....

  FTitle := Value;
end;

function TVPNConnection.GetConnected: Boolean;
begin
  Result:= GetStatus.rasConnstate = RASCS_Connected;
end;

procedure TVPNConnection.GetInfo;
var
  P: TRASDialParams;
begin
  P:= GetDialParams;
  FUsername:= StrPas(P.szUserName);
  FPassword:= StrPas(P.szPassword);
  FDomain:= StrPas(P.szDomain);
  FCallbackNumber:= StrPas(P.szCallbackNumber);
  FPhoneNumber:= StrPas(P.szPhoneNumber);
end;

function TVPNConnection.GetDialParams: TRASDialParams;
var
  R: Word;
  Res: LongBool;
begin
  if FOwner.RasAvailable and Assigned(FOwner.FRasApi.GetEntryDialParams) then begin
    FillChar(Result, SizeOf(TRASDialParams), #0);
    StrLCopy(Result.szEntryName, PChar(FTitle), RAS_MAXENTRYNAME);
    Result.dwSize := SizeOf(TRASDialParams);
    R:= FOwner.FRasApi.GetEntryDialParams(nil, Result, Res);
    case R of
      ERROR_SUCCESS: ;
      else begin
        raise Exception.Create('Failed to get dial params: Error code '+IntToStr(R));
      end;
    end;
  end;
end;

function TVPNConnection.GetStatus: TRASConnStatus;
var
  R: Word;
begin
  if FOwner.RasAvailable and Assigned(FOwner.FRasApi.GetConnectStatus) then begin
    FillChar(Result, SizeOf(TRASConnStatus), #0);
    Result.dwSize:= SizeOf(TRASConnStatus);
    R:= FOwner.FRasApi.GetConnectStatus(FConn.rasConn, @Result);
    if R <> ERROR_SUCCESS then begin
      case R of
        ERROR_NOT_ENOUGH_MEMORY: begin
          raise Exception.Create('Failed to get status: Not enough memory.');
        end;
        else begin
          raise Exception.Create('Failed to get status: Error code '+IntToStr(R));
        end;
      end;
    end;
  end;
end;

end.
