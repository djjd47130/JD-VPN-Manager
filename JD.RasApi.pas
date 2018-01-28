unit JD.RasApi;

(*
  JD Ras Dial API Wrapper

  This unit is a custom implementation of the Windows Rasdial API.
  It encapsulates all possible Winapi calls to perform Rasdial operations.

  NOTE: For ease of use, you can use a TRasApi record type,
    create it using CreateRasApi and destroy it using DestroyRasApi.
    It takes care of loading the library, acquiring proc addresses,
    and setting up a handle to receive notification messages.


*)

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.Classes;

{$HPPEMIT '#include "ras.h"'}

const
  UNLEN = 256;
  {$EXTERNALSYM UNLEN}
  PWLEN = 256;
  {$EXTERNALSYM PWLEN}
  DNLEN = 15;
  {$EXTERNALSYM DNLEN}
  RAS_MaxEntryName = 256;
  {$EXTERNALSYM RAS_MaxEntryName}
  RAS_MaxDeviceName = 128;
  {$EXTERNALSYM RAS_MaxDeviceName}
  RAS_MaxDeviceType = 16;
  {$EXTERNALSYM RAS_MaxDeviceType}
  RAS_MaxParamKey = 32;
  {$EXTERNALSYM RAS_MaxParamKey}
  RAS_MaxParamValue = 128;
  {$EXTERNALSYM RAS_MaxParamValue}
  RAS_MaxPhoneNumber = 128;
  {$EXTERNALSYM RAS_MaxPhoneNumber}
  RAS_MaxCallbackNumber = RAS_MaxPhoneNumber;
  {$EXTERNALSYM RAS_MaxCallbackNumber}

type
  UINT = Word;
  {$EXTERNALSYM UINT}
  PHRASConn = ^HRASConn;
  HRASConn = DWORD;
  {$EXTERNALSYM HRASConn}

const
  RADDIAL_DLL_FILENAME = 'RASAPI32.DLL';
  RASDialEvent = 'RASDialEvent';
  WM_RASDialEvent = $0CCCD;
  RASCS_Paused = $1000;
  RASCS_Done = $2000;
  RASBase = 600;
  Success = 0;
  PENDING = (RASBase + 0);

  //Error Codes
  ERROR_INVALID_PORT_HANDLE = (RASBase + 1);
  ERROR_PORT_ALREADY_OPEN = (RASBase + 2);
  ERROR_BUFFER_TOO_SMALL = (RASBase + 3);
  ERROR_WRONG_INFO_SPECIFIED = (RASBase + 4);
  ERROR_CANNOT_SET_PORT_INFO = (RASBase + 5);
  ERROR_PORT_NOT_ConnECTED = (RASBase + 6);
  ERROR_EVENT_INVALID = (RASBase + 7);
  ERROR_DEVICE_DOES_NOT_EXIST = (RASBase + 8);
  ERROR_DEVICETYPE_DOES_NOT_EXIST = (RASBase + 9);
  ERROR_INVALID_BUFFER = (RASBase + 10);
  ERROR_ROUTE_NOT_AVAILABLE = (RASBase + 11);
  ERROR_ROUTE_NOT_ALLOCATED = (RASBase + 12);
  ERROR_INVALID_COMPRESSION_SPECIFIED = (RASBase + 13);
  ERROR_OUT_OF_BUFFERS = (RASBase + 14);
  ERROR_PORT_NOT_FOUND = (RASBase + 15);
  ERROR_ASYNC_REQUEST_PENDING = (RASBase + 16);
  ERROR_ALREADY_DISConnECTING = (RASBase + 17);
  ERROR_PORT_NOT_OPEN = (RASBase + 18);
  ERROR_PORT_DISConnECTED = (RASBase + 19);
  ERROR_NO_ENDPOINTS = (RASBase + 20);
  ERROR_CANNOT_OPEN_PHONEBOOK = (RASBase + 21);
  ERROR_CANNOT_LOAD_PHONEBOOK = (RASBase + 22);
  ERROR_CANNOT_FIND_PHONEBOOK_ENTRY = (RASBase + 23);
  ERROR_CANNOT_WRITE_PHONEBOOK = (RASBase + 24);
  ERROR_CORRUPT_PHONEBOOK = (RASBase + 25);
  ERROR_CANNOT_LOAD_string = (RASBase + 26);
  ERROR_KEY_NOT_FOUND = (RASBase + 27);
  ERROR_DISConnECTION = (RASBase + 28);
  ERROR_REMOTE_DISConnECTION = (RASBase + 29);
  ERROR_HARDWARE_FAILURE = (RASBase + 30);
  ERROR_USER_DISConnECTION = (RASBase + 31);
  ERROR_INVALID_SIZE = (RASBase + 32);
  ERROR_PORT_NOT_AVAILABLE = (RASBase + 33);
  ERROR_CANNOT_PROJECT_CLIENT = (RASBase + 34);
  ERROR_UNKNOWN = (RASBase + 35);
  ERROR_WRONG_DEVICE_ATTACHED = (RASBase + 36);
  ERROR_BAD_string = (RASBase + 37);
  ERROR_REQUEST_TIMEOUT = (RASBase + 38);
  ERROR_CANNOT_GET_LANA = (RASBase + 39);
  ERROR_NETBIOS_ERROR = (RASBase + 40);
  ERROR_SERVER_OUT_OF_RESOURCES = (RASBase + 41);
  ERROR_NAME_EXISTS_ON_NET = (RASBase + 42);
  ERROR_SERVER_GENERAL_NET_FAILURE = (RASBase + 43);
  WARNING_MSG_ALIAS_NOT_ADDED = (RASBase + 44);
  ERROR_AUTH_INTERNAL = (RASBase + 45);
  ERROR_RESTRICTED_LOGON_HOURS = (RASBase + 46);
  ERROR_ACCT_DISABLED = (RASBase + 47);
  ERROR_PASSWD_EXPIRED = (RASBase + 48);
  ERROR_NO_DIALIN_PERMISSION = (RASBase + 49);
  ERROR_SERVER_NOT_RESPONDING = (RASBase + 50);
  ERROR_FROM_DEVICE = (RASBase + 51);
  ERROR_UNRECOGNIZED_RESPONSE = (RASBase + 52);
  ERROR_MACRO_NOT_FOUND = (RASBase + 53);
  ERROR_MACRO_NOT_DEFINED = (RASBase + 54);
  ERROR_MESSAGE_MACRO_NOT_FOUND = (RASBase + 55);
  ERROR_DEFAULTOFF_MACRO_NOT_FOUND = (RASBase + 56);
  ERROR_FILE_COULD_NOT_BE_OPENED = (RASBase + 57);
  ERROR_DEVICENAME_TOO_LONG = (RASBase + 58);
  ERROR_DEVICENAME_NOT_FOUND = (RASBase + 59);
  ERROR_NO_RESPONSES = (RASBase + 60);
  ERROR_NO_COMMAND_FOUND = (RASBase + 61);
  ERROR_WRONG_KEY_SPECIFIED = (RASBase + 62);
  ERROR_UNKNOWN_DEVICE_TYPE = (RASBase + 63);
  ERROR_ALLOCATING_MEMORY = (RASBase + 64);
  ERROR_PORT_NOT_CONFIGURED = (RASBase + 65);
  ERROR_DEVICE_NOT_READY = (RASBase + 66);
  ERROR_READING_INI_FILE = (RASBase + 67);
  ERROR_NO_ConnECTION = (RASBase + 68);
  ERROR_BAD_USAGE_IN_INI_FILE = (RASBase + 69);
  ERROR_READING_SECTIONNAME = (RASBase + 70);
  ERROR_READING_DEVICETYPE = (RASBase + 71);
  ERROR_READING_DEVICENAME = (RASBase + 72);
  ERROR_READING_USAGE = (RASBase + 73);
  ERROR_READING_MAXConnECTBPS = (RASBase + 74);
  ERROR_READING_MAXCARRIERBPS = (RASBase + 75);
  ERROR_LINE_BUSY = (RASBase + 76);
  ERROR_VOICE_ANSWER = (RASBase + 77);
  ERROR_NO_ANSWER = (RASBase + 78);
  ERROR_NO_CARRIER = (RASBase + 79);
  ERROR_NO_DIALTONE = (RASBase + 80);
  ERROR_IN_COMMAND = (RASBase + 81);
  ERROR_WRITING_SECTIONNAME = (RASBase + 82);
  ERROR_WRITING_DEVICETYPE = (RASBase + 83);
  ERROR_WRITING_DEVICENAME = (RASBase + 84);
  ERROR_WRITING_MAXConnECTBPS = (RASBase + 85);
  ERROR_WRITING_MAXCARRIERBPS = (RASBase + 86);
  ERROR_WRITING_USAGE = (RASBase + 87);
  ERROR_WRITING_DEFAULTOFF = (RASBase + 88);
  ERROR_READING_DEFAULTOFF = (RASBase + 89);
  ERROR_EMPTY_INI_FILE = (RASBase + 90);
  ERROR_AUTHENTICATION_FAILURE = (RASBase + 91);
  ERROR_PORT_OR_DEVICE = (RASBase + 92);
  ERROR_NOT_BINARY_MACRO = (RASBase + 93);
  ERROR_DCB_NOT_FOUND = (RASBase + 94);
  ERROR_STATE_MACHINES_NOT_STARTED = (RASBase + 95);
  ERROR_STATE_MACHINES_ALREADY_STARTED = (RASBase + 96);
  ERROR_PARTIAL_RESPONSE_LOOPING = (RASBase + 97);
  ERROR_UNKNOWN_RESPONSE_KEY = (RASBase + 98);
  ERROR_RECV_BUF_FULL = (RASBase + 99);
  ERROR_CMD_TOO_LONG = (RASBase + 100);
  ERROR_UNSUPPORTED_BPS = (RASBase + 101);
  ERROR_UNEXPECTED_RESPONSE = (RASBase + 102);
  ERROR_INTERACTIVE_MODE = (RASBase + 103);
  ERROR_BAD_CALLBACK_NUMBER = (RASBase + 104);
  ERROR_INVALID_AUTH_STATE = (RASBase + 105);
  ERROR_WRITING_INITBPS = (RASBase + 106);
  ERROR_INVALID_WIN_HANDLE = (RASBase + 107);
  ERROR_NO_PASSWORD = (RASBase + 108);
  ERROR_NO_USERNAME = (RASBase + 109);
  ERROR_CANNOT_START_STATE_MACHINE = (RASBase + 110);
  ERROR_GETTING_COMMSTATE = (RASBase + 111);
  ERROR_SETTING_COMMSTATE = (RASBase + 112);
  ERROR_COMM_function = (RASBase + 113);
  ERROR_CONFIGURATION_PROBLEM = (RASBase + 114);
  ERROR_X25_DIAGNOSTIC = (RASBase + 115);
  ERROR_TOO_MANY_LINE_ERRORS = (RASBase + 116);
  ERROR_OVERRUN = (RASBase + 117);
  ERROR_ACCT_EXPIRED = (RASBase + 118);
  ERROR_CHANGING_PASSWORD = (RASBase + 119);
  ERROR_NO_ACTIVE_ISDN_LINES = (RASBase + 120);
  ERROR_NO_ISDN_CHANNELS_AVAILABLE = (RASBase + 121);

const
  //Windows Message Event Types
  RASCS_OpenPort = 0;
  RASCS_PortOpened = 1;
  RASCS_ConnectDevice = 2;
  RASCS_DeviceConnected = 3;
  RASCS_AllDevicesConnected = 4;
  RASCS_Authenticate = 5;
  RASCS_AuthNotify = 6;
  RASCS_AuthRetry = 7;
  RASCS_AuthCallback = 8;
  RASCS_AuthChangePassword = 9;
  RASCS_AuthProject = 10;
  RASCS_AuthLinkSpeed = 11;
  RASCS_AuthAck = 12;
  RASCS_ReAuthenticate = 13;
  RASCS_Authenticated = 14;
  RASCS_PrepareForCallback = 15;
  RASCS_WaiTFormodemReset = 16;
  RASCS_WaitForCallback = 17;

  RASCS_Interactive = RASCS_Paused;
  RASCS_RetryAuthentication = RASCS_Paused + 1;
  RASCS_CallbackSetByCaller = RASCS_Paused + 2;
  RASCS_PasswordExpired = RASCS_Paused + 3;

  RASCS_Connected = RASCS_Done;
  RASCS_Disconnected = RASCS_Done + 1;

type
  PRASConn = ^TRASConn;
  TRASConn = record
    dwSize: DWORD;
    rasConn: HRASConn;
    szEntryName: array [0..RAS_MaxEntryName] of Char;
    szDeviceType: array [0..RAS_MaxDeviceType] of Char;
    szDeviceName: array [0..RAS_MaxDeviceName] of Char;
    {$IFDEF NT_EXTNS}
    szPhonebook: array [0..MAX_PATH - 1] of Char;
    dwSubEntry: Longint;
    {$ENDIF NT_EXTNS}
  end;

  PRASConnStatus = ^TRASConnStatus;
  TRASConnStatus = record
    dwSize: Longint;
    rasConnstate: Word;
    dwError: Longint;
    szDeviceType: array [0..RAS_MaxDeviceType] of Char;
    szDeviceName: array [0..RAS_MaxDeviceName] of Char;
  end;

  PRASDIALEXTENSIONS = ^TRASDIALEXTENSIONS;
  TRASDIALEXTENSIONS = record
    dwSize: DWORD;
    dwfOptions: DWORD;
    hwndParent: HWND;
    reserved: DWORD;
  end;

  PRASDialParams = ^TRASDialParams;
  TRASDialParams = record
    dwSize: DWORD;
    szEntryName: array [0..RAS_MaxEntryName] of Char;
    szPhoneNumber: array [0..RAS_MaxPhoneNumber] of Char;
    szCallbackNumber: array [0..RAS_MaxCallbackNumber] of Char;
    szUserName: array [0..UNLEN] of Char;
    szPassword: array [0..PWLEN] of Char;
    szDomain: array [0..DNLEN] of Char;
  end;

  PRASEntryName = ^TRASEntryName;
  TRASEntryName = record
    dwSize: Longint;
    szEntryName: array [0..RAS_MaxEntryName] of Char;
  end;





  TRasDial = function(
    lpRasDialExtensions: PRASDIALEXTENSIONS; // Pointer to function extensions data
    lpszPhonebook: PChar; // Pointer to full path and FileName of phonebook file
    lpRasDialParams: PRASDIALPARAMS; // Pointer to calling parameters data
    dwNotifierType: DWORD; // specifies type of RasDial event handler
    lpvNotifier: DWORD; // specifies a handler for RasDial events
    var rasConn: HRASConn // Pointer to variable to receive connection Handle
    ): DWORD; stdcall;

  TRasEnumConnections = function(
    RASConn: PrasConn; // buffer to receive Connections data
    var BufSize: DWORD; // Size in bytes of buffer
    var Connections: DWORD // number of Connections written to buffer
    ): Longint; stdcall;

  TRasEnumEntries = function(
    reserved: PChar; // reserved, must be NULL
    lpszPhonebook: PChar; // Pointer to full path and FileName of phonebook file
    lprasentryname: PRASENTRYNAME; // buffer to receive phonebook entries
    var lpcb: DWORD; // Size in bytes of buffer
    var lpcEntries: DWORD // number of entries written to buffer
    ): DWORD; stdcall;

  TRasGetConnectStatus = function(
    RASConn: hrasConn; // Handle to Remote Access Connection of interest
    RASConnStatus: PRASConnStatus // buffer to receive status data
    ): Longint; stdcall;

  TRasGetErrorstring = function(
    ErrorCode: DWORD; // error code to get string for
    szErrorstring: PChar; // buffer to hold error string
    BufSize: DWORD // SizeOf buffer
    ): Longint; stdcall;

  TRasHangUp = function(
    RASConn: hrasConn // Handle to the Remote Access Connection to hang up }
    ): Longint; stdcall;

  TRasGetEntryDialParams = function(
    lpszPhonebook: PChar; // Pointer to the full path and FileName of the phonebook file
    var lprasdialparams: TRASDIALPARAMS; // Pointer to a structure that receives the connection parameters
    var lpfPassword: BOOL // indicates whether the user's password was retrieved
    ): DWORD; stdcall;

  TRasValidateEntryName = function(
    lpszPhonebook: PChar; // Pointer to full path and FileName of phone-book file
    lpszEntry: PChar // Pointer to the entry name to validate
    ): DWORD; stdcall;

  TRasCreatePhonebookEntry = function(
    Handle: HWND; // Handle to the Parent window of the dialog box
    lpszPhonebook: PChar // Pointer to the full path and FileName of the phone-book file
    ): DWORD; stdcall;

  TRasEditPhonebookEntry = function(
    Handle: HWND; // Handle to the Parent window of the dialog box
    lpszPhonebook: PChar; // Pointer to the full path and FileName of the phone-book file
    lpszEntryName: PChar // Pointer to the phone-book entry name
    ): DWORD; stdcall;

  TRasApi = record
    Available: Boolean;
    Dll: THandle;
    Handle: THandle;
    PHandle: THandle;
    RASEvent: Word;
    Dial: TRasDial;
    EnumConnections: TRasEnumConnections;
    EnumEntries: TRasEnumEntries;
    GetConnectStatus: TRasGetConnectStatus;
    GetErrorstring: TRasGetErrorstring;
    HangUp: TRasHangUp;
    GetEntryDialParams: TRasGetEntryDialParams;
    ValidateEntryName: TRasValidateEntryName;
    CreatePhonebookEntry: TRasCreatePhonebookEntry;
    EditPhonebookEntry: TRasEditPhonebookEntry;
  end;

function CreateRasApi(AOwner: TComponent; AWndProc: TWndMethod): TRasApi;
procedure DestroyRasApi(var ARasApi: TRasApi);

implementation

uses
  System.SysUtils,
  Vcl.Controls;

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

procedure DeallocateHWndEx(Wnd: THandle);
begin
  Winapi.Windows.DestroyWindow(Wnd);
end;

function CreateRasApi(AOwner: TComponent; AWndProc: TWndMethod): TRasApi;
begin
  //Acquire owner handle...
  if AOwner is TWinControl then
    Result.PHandle := (AOwner as TWinControl).Handle
  else
    Result.PHandle := GetForegroundWindow; //TODO: Is this safe?

  //Load Rasdial Library...
  Result.Dll := SafeLoadLibrary(RADDIAL_DLL_FILENAME);
  if Result.Dll <> 0 then begin

    //Acquire procedure addresses...
    Result.Dial := GetProcAddress(Result.Dll, {$IFDEF UNICODE}'RasDialW'{$ELSE}'RasDialA'{$ENDIF UNICODE});
    Result.EnumConnections := GetProcAddress(Result.Dll, {$IFDEF UNICODE}'RasEnumConnectionsW'{$ELSE}'RasEnumConnectionsA'{$ENDIF UNICODE});
    Result.EnumEntries := GetProcAddress(Result.Dll, {$IFDEF UNICODE}'RasEnumEntriesW'{$ELSE}'RasEnumEntriesA'{$ENDIF UNICODE});
    Result.GetConnectStatus := GetProcAddress(Result.Dll, {$IFDEF UNICODE}'RasGetConnectStatusW'{$ELSE}'RasGetConnectStatusA'{$ENDIF UNICODE});
    Result.GetErrorstring := GetProcAddress(Result.Dll, {$IFDEF UNICODE}'RasGetErrorstringW'{$ELSE}'RasGetErrorstringA'{$ENDIF UNICODE});
    Result.HangUp := GetProcAddress(Result.Dll, {$IFDEF UNICODE}'RasHangUpW'{$ELSE}'RasHangUpA'{$ENDIF UNICODE});
    Result.GetEntryDialParams := GetProcAddress(Result.Dll, {$IFDEF UNICODE}'RasGetEntryDialParamsW'{$ELSE}'RasGetEntryDialParamsA'{$ENDIF UNICODE});
    Result.ValidateEntryName := GetProcAddress(Result.Dll, {$IFDEF UNICODE}'RasValidateEntryNameW'{$ELSE}'RasValidateEntryNameA'{$ENDIF UNICODE});
    Result.CreatePhonebookEntry := GetProcAddress(Result.Dll, {$IFDEF UNICODE}'RasCreatePhonebookEntryW'{$ELSE}'RasCreatePhonebookEntryA'{$ENDIF UNICODE});
    Result.EditPhonebookEntry := GetProcAddress(Result.Dll, {$IFDEF UNICODE}'RasEditPhonebookEntryW'{$ELSE}'RasEditPhonebookEntryA'{$ENDIF UNICODE});

    //Prepare events...
    Result.Handle := AllocateHWndEx(AWndProc);
    Result.RASEvent := RegisterWindowMessage(RASDialEvent);
    if Result.RASEvent = 0 then
      Result.RASEvent := WM_RASDialEvent;

  end;

  //Check if Ras is available at all...
  Result.Available := (Result.Dll <> 0) and Assigned(Result.Dial);

end;

procedure DestroyRasApi(var ARasApi: TRasApi);
begin
  if ARasApi.Available then begin
    FreeLibrary(ARasApi.Dll);
    DeallocateHWndEx(ARasApi.Handle);
  end;
  ARasApi.Dll := 0;
end;

end.
