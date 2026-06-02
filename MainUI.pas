unit MainUI;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Winapi.WebView2, Winapi.ActiveX,
  Vcl.ExtCtrls, Vcl.Menus, Vcl.StdCtrls, Vcl.Imaging.pngimage, Cod.Types,
  {Vcl.Edge, } Edge2, Cod.SysUtils, Cod.Files, Cod.Windows, Cod.Internet,
  Cod.IniSettings, Winapi.ShlObj, DateUtils, Cod.Version, Cod.StringUtils,
  SettingsUI, UITypes, IOUtils, System.SyncObjs, System.TimeSpan, JSON, Winapi.EdgeUtils,
  System.Win.TaskbarCore, Vcl.Taskbar, System.Actions, Vcl.ActnList,
  System.ImageList, Vcl.ImgList, System.Generics.Collections, Math,
  Cod.WindowsRT.AppRegistration, Cod.WindowsRT.NotificationManager,
  Cod.WindowsRT, Cod.CodrutSoftware.API.Update;

const
    WM_RESTOREAPPFROMTRAY = WM_USER + 100;

type
  // Define custom class
  TMainBrowser = class(TCustomEdgeBrowser)
  private
    type TScriptCallback = reference to procedure (Status: HResult; ResultObjectJSON: string);

    procedure HandleCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HResult);
  protected
    procedure OpenDevTools;

    // Scripts
    procedure ExecuteScript(const JavaScript: string; Callback: TScriptCallback=nil); overload;
    function ExecuteScriptAwait(const JavaScript: string; out Output: string; Timeout: cardinal=1000): boolean; overload;

  public
    constructor Create(AOwner: TComponent); override;
  end;

  TMainForm = class(TForm)
    TrayIcon: TTrayIcon;
    TrayMenu: TPopupMenu;
    Show1: TMenuItem;
    MinimizetoTray1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    N3: TMenuItem;
    Givefeedback1: TMenuItem;
    StartupLogo: TImage;
    DelayedUpdateCheck: TTimer;
    DebugPanel: TPanel;
    Label5: TLabel;
    Label6: TLabel;
    Button4: TButton;
    Button5: TButton;
    Label7: TLabel;
    Button6: TButton;
    Label8: TLabel;
    Edit1: TEdit;
    Button7: TButton;
    DebugStat: TTimer;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    Panel2: TPanel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    StartURLLoader: TTimer;
    Settings1: TMenuItem;
    N4: TMenuItem;
    PeriodicUpdaterTask: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure TrayIconDblClick(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure MinimizetoTray1Click(Sender: TObject);
    procedure Show1Click(Sender: TObject);
    procedure YourLibrary1Click(Sender: TObject);
    procedure Givefeedback1Click(Sender: TObject);
    procedure DelayedUpdateCheckTimer(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure DebugStatTimer(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure StartURLLoaderTimer(Sender: TObject);
    procedure Settings1Click(Sender: TObject);
    procedure PeriodicUpdaterTaskTimer(Sender: TObject);
  protected
    procedure WMSysCommand(var Message: TWMSysCommand); message WM_SYSCOMMAND;
    procedure WMRestoreAppFromTray(var Message: TMessage); message WM_RESTOREAPPFROMTRAY;

    procedure WMActivate(var Msg: TWMActivate); message WM_ACTIVATE;

  private
    procedure CloseProgram;

    // Tray
    procedure MinimizeToTray;
    procedure RestoreFromTray;

    // Update procs
    procedure UpdateNetworkState;

    // Window
    procedure CreateSystemMenu;

    // Forms
    procedure OpenSettingsForm;

    // Utils
    procedure ReloadWebViewBase;

    // Notifications
    procedure FetchNotificationsFromClient;

    // Audio
    procedure InjectAudioHook;
    function GetPlayedAudios: TArray<string>;

    // Browser
    procedure InitializeSite(FirstLoad: boolean=false);
    procedure WaitBrowserNavigation;
    procedure WaitBrowserInitialization;

    // Main
    procedure NavigateHome;

    // Events
    procedure BrowserExecuteScript(Sender: TCustomEdgeBrowser; AResult: HResult; const AResultObjectAsJson: string);
    procedure BrowserNavigationStarting(Sender: TCustomEdgeBrowser; Args: TNavigationStartingEventArgs);
    procedure BrowserNavigationCompleted(Sender: TCustomEdgeBrowser;
      IsSuccess: Boolean; WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);

    procedure NotifActivated(Sender: TNotification; Arguments: string; UserInput: TUserInputMap);

    procedure CreatingWebViewFinalized(Sender: TCustomEdgeBrowser; AResult: HResult);
  public
    Browser: TMainBrowser;

    { Public declarations }
    InTray: boolean;

    // Update
    procedure DoUpdateCheck(NotifyStatus: boolean);
  end;

const
  VERSION: TVersion = (Major: 1; Minor: 0; Maintenance: 0);
  FLUFFYCHAT_CLIENT_VERSION: TVersion = (Major: 2; Minor: 6; Maintenance: 0);

  APP_NAME = 'FluffyChat Desktop';

  DEVELOPER_URL = 'https://www.codrutsoft.com/';
  SUPPORT_URL = 'https://go.codrutsoft.com/support/';
  FEEDBACK_URL = 'https://github.com/Codrax/FluffyChat-Windows-Desktop';
  WEBSITE_APP_LINK = 'https://www.codrutsoft.com/apps/fluffy-chat-desktop/';

  API_APP_NAME = 'fluffy-chat-desktop';

  APP_USER_MODEL_ID = 'com.codrutsoft.fluffychatdesktop';

  // Menu (titlebar)
  MENU_ACTION = 999;
  MENU_ACTION_RELOAD = MENU_ACTION+1;
  MENU_ACTION_TRAY = MENU_ACTION+2;
  MENU_ACTION_SETTINGS = MENU_ACTION+3;

  // Links
  SOURCE_BASE = 'source\';
  APP_BASE_FILE = SOURCE_BASE+'web\index.html';

  HOME_URL = 'https://app.local/web/index.html';

var
  MainForm: TMainForm;

  // Update
  VersionCheck: TStandardVersionCheckerUpdateUrl;

  // System
  AppData: string;
  AppDir: string;
  Settings: TSettingsManager;
  Status: TSectionSettingsManager;

  DebugMode: boolean;
  AppInitialized: boolean;

  TaskbarPlayingState: boolean = false;

  // Notifications
  Manager: TNotificationManager;
  NotificationNotifications: TNotification;
    KnownMissedNotificationCount: integer;
  NotificationCall: TNotification;

  // Browser
  BrowserInitialized: boolean;
  BrowserNavigating: boolean;

  ActionInjectAudioHook: boolean;
  AudioHookInjected: boolean;

  // Utils
  StartURL: string;
  ShowWhenLoaded: boolean;
  InitializeWhenLoaded: boolean;

  // App state
  CurrentState: string;
  LastNetworkConnectedState: boolean = true;

implementation

{$R *.dfm}

procedure TMainForm.BrowserExecuteScript(Sender: TCustomEdgeBrowser;
  AResult: HResult; const AResultObjectAsJson: string);
begin
  //
end;

procedure TMainForm.BrowserNavigationCompleted(Sender: TCustomEdgeBrowser;
  IsSuccess: Boolean; WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
begin
  CurrentState := 'Navigation done';

  BrowserNavigating := false;

  // Hidden
  if ShowWhenLoaded then begin
    Browser.Align := alClient;

    //
    ShowWhenLoaded := false;
  end;

  // Init
  if InitializeWhenLoaded then begin
    AppInitialized := true;
    StartupLogo.Hide;

    // Fix fluffy chat not loaded when starting minimized in the system tray
    if InTray and not Application.ShowMainForm then begin
      AlphaBlend := true;
      AlphaBlendValue := 0;
      Show;

      Hide;
      AlphaBlend := false;
      AlphaBlendValue := 255;
    end;


    //
    InitializeWhenLoaded := false;
  end;

  // Error
  if not (WebErrorStatus in [COREWEBVIEW2_WEB_ERROR_STATUS_UNKNOWN, COREWEBVIEW2_WEB_ERROR_STATUS_CONNECTION_ABORTED]) then begin
    var S := '';
    case WebErrorStatus of
      COREWEBVIEW2_WEB_ERROR_STATUS_CERTIFICATE_COMMON_NAME_IS_INCORRECT: S := 'CERTIFICATE_COMMON_NAME_IS_INCORRECT';
      COREWEBVIEW2_WEB_ERROR_STATUS_CERTIFICATE_EXPIRED: S := 'CERTIFICATE_EXPIRED';
      COREWEBVIEW2_WEB_ERROR_STATUS_CLIENT_CERTIFICATE_CONTAINS_ERRORS: S := 'CLIENT_CERTIFICATE_CONTAINS_ERRORS';
      COREWEBVIEW2_WEB_ERROR_STATUS_CERTIFICATE_REVOKED: S := 'CERTIFICATE_REVOKED';
      COREWEBVIEW2_WEB_ERROR_STATUS_CERTIFICATE_IS_INVALID: S := 'CERTIFICATE_IS_INVALID';
      COREWEBVIEW2_WEB_ERROR_STATUS_SERVER_UNREACHABLE: S := 'SERVER_UNREACHABLE';
      COREWEBVIEW2_WEB_ERROR_STATUS_TIMEOUT: S := 'TIMEOUT';
      COREWEBVIEW2_WEB_ERROR_STATUS_ERROR_HTTP_INVALID_SERVER_RESPONSE: S := 'ERROR_HTTP_INVALID_SERVER_RESPONSE';
      //COREWEBVIEW2_WEB_ERROR_STATUS_CONNECTION_ABORTED: S := 'CONNECTION_ABORTED';
      COREWEBVIEW2_WEB_ERROR_STATUS_CONNECTION_RESET: S := 'CONNECTION_RESET';
      COREWEBVIEW2_WEB_ERROR_STATUS_DISCONNECTED: S := 'DISCONNECTED';
      COREWEBVIEW2_WEB_ERROR_STATUS_CANNOT_CONNECT: S := 'CANNOT_CONNECT';
      COREWEBVIEW2_WEB_ERROR_STATUS_HOST_NAME_NOT_RESOLVED: S := 'HOST_NAME_NOT_RESOLVED';
      COREWEBVIEW2_WEB_ERROR_STATUS_OPERATION_CANCELED: S := 'OPERATION_CANCELED';
      COREWEBVIEW2_WEB_ERROR_STATUS_REDIRECT_FAILED: S := 'REDIRECT_FAILED';
      COREWEBVIEW2_WEB_ERROR_STATUS_UNEXPECTED_ERROR: S := 'UNEXPECTED_ERROR';
      COREWEBVIEW2_WEB_ERROR_STATUS_VALID_AUTHENTICATION_CREDENTIALS_REQUIRED: S := 'VALID_AUTHENTICATION_CREDENTIALS_REQUIRED';
      COREWEBVIEW2_WEB_ERROR_STATUS_VALID_PROXY_AUTHENTICATION_REQUIRED: S := 'VALID_PROXY_AUTHENTICATION_REQUIRED';
      else S := 'An unknown error has occured';
    end;
    MessageDLG('Browser error:'#13+S+#13#13'Please report this problem to the developers.', mtError, [mbClose], 0);

    // Error panel
    Browser.Hide;
  end else begin
    Browser.Show;

    if ActionInjectAudioHook then begin
      InjectAudioHook;
      AudioHookInjected := true;
      //
      ActionInjectAudioHook := false;
    end;
  end;
end;

procedure TMainForm.BrowserNavigationStarting(Sender: TCustomEdgeBrowser;
  Args: TNavigationStartingEventArgs);
begin
  CurrentState := 'Navigating';

  BrowserNavigating := true;
end;

procedure TMainForm.Button10Click(Sender: TObject);
begin
  Browser.Navigate('about:blank');
end;

procedure TMainForm.Button4Click(Sender: TObject);
begin
  Browser.Show;

  // Align
  Browser.Align := alClient;
end;

procedure TMainForm.Button5Click(Sender: TObject);
begin
  Browser.Hide;
end;

procedure TMainForm.Button6Click(Sender: TObject);
begin
  StartupLogo.Hide;
end;

procedure TMainForm.Button7Click(Sender: TObject);
begin
  Browser.Navigate(Edit1.Text);
end;

procedure TMainForm.Button8Click(Sender: TObject);
begin
  NavigateHome;
end;

procedure TMainForm.Button9Click(Sender: TObject);
begin
  Browser.Refresh;
end;

procedure TMainForm.CloseProgram;
begin
  InTray := true; // to prevent mimimizing
  Close;
end;

function TMainForm.GetPlayedAudios: TArray<string>;
var
  JSResult, Clean: string;
  Json: TJSONArray;
  I: Integer;
begin
  Result := [];
  if not AudioHookInjected then
    Exit;

  SetLength(Result, 0);

  if not Browser.ExecuteScriptAwait(
    'JSON.stringify(window.__getAndClearPlayedAudios() ?? [])',
    JSResult
  ) then
    Exit;

  // JS returns JSON string like: ["file1.mp3","file2.ogg"]
  Clean := JSResult.Trim;
  try
    const JS = TJSONString.ParseJSONValue(Clean);
    Clean := JS.Value;
    JS.Free;
  except
    Exit;
  end;
  if (Clean = '') or (Clean = 'null') then
    Exit;

  try
    Json := TJSONObject.ParseJSONValue(Clean) as TJSONArray;
  except
    Exit;
  end;
  try
    SetLength(Result, Json.Count);

    for I := 0 to Json.Count - 1 do
      Result[I] := Json.Items[I].Value;

  finally
    Json.Free;
  end;
end;

procedure TMainForm.Givefeedback1Click(Sender: TObject);
begin
  ShellRun(FEEDBACK_URL, true);
end;

procedure TMainForm.InitializeSite;
begin
  CurrentState := 'Initializing browser...';

  // UI
  if not DebugMode then
    StartupLogo.Show;

  Browser.Show;

  // Align
  if not DebugMode then begin
    Browser.Align := alNone;
    Browser.Width := ClientWidth;
    Browser.Height := ClientHeight;
    Browser.Top := -Browser.Height;
  end;

  BrowserInitialized := false;

  // Init
  Browser.ReinitializeWebView;
  Application.ProcessMessages;

  // Wait for initializaiton
  WaitBrowserInitialization;

  // Set host mapping
  Browser.SetVirtualHostNameToFolderMapping(
    'app.local',
    AppDir + SOURCE_BASE,
    COREWEBVIEW2_HOST_RESOURCE_ACCESS_KIND_ALLOW
  );

  // Navigate
  Browser.Navigate('about:blank');
  WaitBrowserNavigation;
end;

procedure TMainForm.InjectAudioHook;
begin
  Browser.ExecuteScript(
    '(function(){' +
    'if(window.__audioHookInstalled) return;' +
    'window.__audioHookInstalled = true;' +

    'window.__playedAudios = [];' +

    'const originalPlay = HTMLMediaElement.prototype.play;' +

    'HTMLMediaElement.prototype.play = function() {' +
    '  try {' +
    '    let src = this.currentSrc || this.src || "";' +
    '    if(src) {' +
    '      window.__playedAudios.push(src);' +
    '      console.log("AUDIO_PLAYED_FULLPATH:" + src);' +
    '    }' +
    '  } catch(e) {}' +
    '  return originalPlay.apply(this, arguments);' +
    '};' +

    'window.__getAndClearPlayedAudios = function() {' +
    '  const copy = window.__playedAudios.slice();' +
    '  window.__playedAudios.length = 0;' +
    '  return copy;' +
    '};' +
    '})();'
  , nil);
end;

procedure TMainForm.CreateSystemMenu;
var
  HhMenu: HMENU;
procedure AddSeparator;
begin
  InsertMenu(HhMenu, 999   , MF_BYPOSITION or MF_SEPARATOR, 0, nil);
end;
procedure AddMenu(Name: string; id: integer);
begin
  InsertMenu(HhMenu, 999, MF_BYPOSITION, id, PChar(Name));
end;
begin
  // Get the handle to the system menu
  HhMenu := GetSystemMenu(Handle, False);

  // Item
  AddSeparator;
  AddMenu('Reload web view', MENU_ACTION_RELOAD);
  AddSeparator;
  AddMenu('Minimize to tray', MENU_ACTION_TRAY);
  AddMenu('Settings', MENU_ACTION_SETTINGS);
end;

procedure TMainForm.CreatingWebViewFinalized(Sender: TCustomEdgeBrowser;
  AResult: HResult);
begin
  // Initialized
  BrowserInitialized := true;

  // Context menu
  if not DebugMode then begin
    Browser.DefaultContextMenusEnabled := false;
    Browser.BuiltInErrorPageEnabled := false;
    Browser.DevToolsEnabled := false;
    Browser.StatusBarEnabled := false;
    Browser.ZoomControlEnabled := false;
  end else
    Browser.OpenDevTools;

  // Get settings
  Browser.ZoomFactor := Settings.Get<double>('zoom', 'accessibility', 1);
end;

procedure TMainForm.Exit1Click(Sender: TObject);
begin
  CloseProgram;
end;

procedure TMainForm.FetchNotificationsFromClient;
var
  Items: TArray<string>;

  CountNotifications: integer;
  CountCalls: integer;
begin
  Items := GetPlayedAudios;

  // Is the window open
  try
    if not InTray and (GetForegroundWindow = Handle) then begin
      KnownMissedNotificationCount := 0;
      Manager.DestroyNotification(NotificationNotifications);
      Manager.DestroyNotification(NotificationCall);

      Exit;
    end;
  except
    Exit;
  end;


  // Count them
  CountNotifications := 0;
  CountCalls := 0;
  for var I := 0 to High(Items) do
    if Items[I].EndsWith('phone.ogg') or Items[I].StartsWith('data:audio/ogg;base64,T2dnUwACAAAAAAAAAAAko0mQAAAAAAben9YBHgF2b3JiaXMAAAAAAkSsAAAAAAAAgLUBAAAAAAC4AU9nZ1MAAAAAAAAAAAAAJKNJkAEAAAAu7GtSEUD') then
      Inc(CountCalls)
      else
    if Items[I].EndsWith('notification.ogg') then
      Inc(CountNotifications)
    else
      ShowMessage(Items[I]);

  // Remove notifications that belong to the calls
  if (CountCalls > 0) then
    CountNotifications := Max(0, CountNotifications-CountCalls);

  // Notifications
  if (CountNotifications > 0) then begin
    KnownMissedNotificationCount := KnownMissedNotificationCount + CountNotifications;

    // Create notification
    Manager.DestroyNotification(NotificationNotifications);
    TToastContentBuilder.Create
      .AddText( TToastValueString.Create(Format('You have %d new notifications', [KnownMissedNotificationCount])) )
      .AddText( TToastValueString.Create(Format('There are %d more notifications than last time.'#13#13'Click here to open FluffyChat', [CountNotifications])) )
      .AddButton('View', TActivationType.Foreground, 'view')
      .AddButton('Ignore', TActivationType.Foreground, 'ignore')

      .CreateNotificationAndFree(NotificationNotifications);
    // Set tag
    NotificationNotifications.Tag := 'notif-notifications';
    // Events
    NotificationNotifications.OnActivated := NotifActivated;

    Manager.ShowNotification(NotificationNotifications);
  end;

  // Calls
  if (CountCalls > 0) then begin
    // Create notification
    Manager.DestroyNotification(NotificationCall);
    TToastContentBuilder.Create
      .AddText( TToastValueString.Create('Someone is calling you') )
      .AddAppLogoOverride(TToastValueString.Create(AppDir+'call.png'), TImageCrop.Circle, 'Call')
      .AddText( TToastValueString.Create('Click here to open FluffyChat and answer this call') )
      .AddButton('Open', TActivationType.Foreground, 'view')
      .AddAudio(TSoundEventValue.NotificationDefault, WinFalse, WinTrue)
      .CreateNotificationAndFree(NotificationCall);
    // Set tag
    NotificationCall.Tag := 'notif-call';
    // Events
    NotificationCall.OnActivated := NotifActivated;

    Manager.ShowNotification(NotificationCall);
  end;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if AppInitialized and not InTray and not DebugMode and Settings.Get<boolean>('minimize-to-tray', 'general', true) then begin
    MinimizeToTray;

    CanClose := false;
    Exit;
  end;

  // Save positions
  SaveFormPositions(Self, AppData+'form-pos.ini');
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Caption := APP_NAME;
  TrayIcon.Hint := APP_NAME;

  // Dirs
  AppData := GetPathInAppData(APP_NAME, TAppDataType.Roaming, true);
  AppDir := IncludeTrailingPathDelimiter(ExtractFileDir(Application.ExeName));

  // UI
  FixDelphiXDialogs;

  // Settings
  Settings := TSettingsManager.Create(AppData + 'settings.ini');
  Status := TSectionSettingsManager.Create(AppData + 'status.ini', 'status');

  // Create system menu
  CreateSystemMenu;

  // Load form
  LoadFormPositions(Self, AppData+'form-pos.ini');

  // Theme (must be after loading position)
  DarkModeApplyToWindow(Handle, true);

  // Debug Mode
  if DebugMode then begin
    DebugPanel.BringToFront;
    DebugPanel.Show;
    DebugStat.Enabled := true;
    Label15.Caption := VERSION.ToString;
  end else begin
    DebugPanel.Destroy;
    DebugStat.Destroy;
  end;

  // Tasks
  DelayedUpdateCheck.Enabled := Settings.Get<boolean>('app', 'check-updates', true);

  // Player
  SetCurrentProcessExplicitAppUserModelID( APP_USER_MODEL_ID );

  // Browser
  Browser := TMainBrowser.Create(Self);

  Browser.Parent := Self;
  Browser.Align := alClient;
  Browser.SendToBack; // dev

  Browser.AreBrowserExtensionsEnabled := false;

  Browser.OnExecuteScript := BrowserExecuteScript;
  Browser.OnNavigationStarting := BrowserNavigationStarting;
  Browser.OnNavigationCompleted := BrowserNavigationCompleted;
  Browser.OnCreateWebViewCompleted := CreatingWebViewFinalized;

  const AppDataBrowser = AppData + 'Browser\';
  Browser.UserDataFolder := AppDataBrowser;

  // Init
  InitializeSite;

  // Init - Updates
  UpdateNetworkState;

  // Start URL
  StartURL := HOME_URL;

  if not GetNetworkConnected then // offline mode
    StartURL := HOME_URL;

  // Begin loading
  StartURLLoader.Enabled := true;
end;

procedure TMainForm.MinimizeToTray;
begin
  if InTray then
    Exit;
  InTray := true;

  // Set
  Hide;

  Show1.Visible := true;
  MinimizetoTray1.Visible := false;
end;

procedure TMainForm.MinimizetoTray1Click(Sender: TObject);
begin
  MinimizeToTray;
end;

procedure TMainForm.NavigateHome;
begin
  // Navigate
  Browser.Navigate( HOME_URL );
end;

procedure TMainForm.NotifActivated(Sender: TNotification; Arguments: string;
  UserInput: TUserInputMap);
begin
  if Arguments = 'ignore' then
    Exit;

  RestoreFromTray;
  BringToTopAndFocusWindow(Handle);
end;

procedure TMainForm.OpenSettingsForm;
begin
  if SettingsForm <> nil then begin
    try
      BringToTopAndFocusWindow(SettingsForm.Handle);
    except
    end;
    Exit;
  end;

  SettingsForm := TSettingsForm.Create(Self);
  with SettingsForm do
    try
      // Show
      ShowModal;
    finally
      Free;

      SettingsForm := nil;
    end;
end;

procedure TMainForm.ReloadWebViewBase;
begin
  InitializeSite;

  //
  StartURL := HOME_URL;
  StartURLLoader.Enabled := true;
end;

procedure TMainForm.RestoreFromTray;
begin
  if not InTray then
    Exit;
  InTray := false;

  // Set
  Show;

  Show1.Visible := false;
  MinimizetoTray1.Visible := true;
end;

procedure TMainForm.Settings1Click(Sender: TObject);
begin
  RestoreFromTray;

  // Settings
  OpenSettingsForm;
end;

procedure TMainForm.Show1Click(Sender: TObject);
begin
  RestoreFromTray;
end;

procedure TMainForm.StartURLLoaderTimer(Sender: TObject);
begin
  TTimer(Sender).Enabled := false;

  // Default page
  InitializeWhenLoaded := true;
  ShowWhenLoaded := true;

  // Navigate
  ActionInjectAudioHook := true;
  AudioHookInjected := false;
  Browser.Navigate( StartURL );
end;

procedure TMainForm.DebugStatTimer(Sender: TObject);
begin
  Label11.Caption := BooleanToString( BrowserNavigating );
  Label13.Caption := Browser.LocationURL;
  Label17.Caption := int64(Browser.LastErrorCode).ToString;
end;

procedure TMainForm.DelayedUpdateCheckTimer(Sender: TObject);
begin
  // Is in tray
  if InTray then
    Exit;

  // Disable self
  TTimer(Sender).Enabled := false;

  // Last check < a day ago
  const LastUpdateCheck = Status.Get<double>('last-update-check', 0);
  if (LastUpdateCheck <> 0) and (DaysBetween(Now, LastUpdateCheck) < 1) then
    Exit;

  // Write last update check
  Status.Put<double>('last-update-check', Now);

  // Update
  DoUpdateCheck(false);
end;

procedure TMainForm.DoUpdateCheck(NotifyStatus: boolean);
procedure DoDownloadFailed;
begin
  if MessageDLG('The download failed. Open the website?', mtWarning, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  ShellRun(WEBSITE_APP_LINK, true);
end;
begin
  // Start update check
  VersionCheck.Load;

  if not VersionCheck.Loaded then
    Exit; // failed

  // New version?
  if not VersionCheck.ServerVersion.NewerThan(VersionCheck.ClientVersion) then begin
    if NotifyStatus then
      MessageDLG('There are no new updates avalabile.', mtWarning, [mbOk], 0);
    Exit;
  end;

  // Alert user
  if MessageDLG('There is a new version of '+APP_NAME+' avalabile on the server. Do you wish to download It now? The app will close to update',
    mtWarning, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  // Validate url
  if VersionCheck.UpdateUrl = '' then begin
    DoDownloadFailed;
    Exit;
  end;

  // Start download
  try
    const OutputFile = ReplaceWinPath(Format('%%TEMP%%\updateinstall_%S.exe', [
      GenerateString(8, [TStrGenFlag.UppercaseLetters, TStrGenFlag.LowercaseLetters, TStrGenFlag.Numbers])
      ]));
    DownloadFile(VersionCheck.UpdateUrl, OutputFile);

    // Run
    ShellRun( OutputFile, true, '-ad' );

    // Close
    Application.Terminate;
  except
    DoDownloadFailed;
    Exit;
  end;
end;

procedure TMainForm.PeriodicUpdaterTaskTimer(Sender: TObject);
begin
  //if not Visible then Exit;

  // Reset interval
  TTimer(sender).Interval := 2000;

  // Fetch notifications
  FetchNotificationsFromClient;

  // Check internet connectivity
  UpdateNetworkState;
end;

procedure TMainForm.TrayIconDblClick(Sender: TObject);
begin
  if InTray then
    RestoreFromTray
  else
    BringToTopAndFocusWindow(Handle);
end;

procedure TMainForm.UpdateNetworkState;
begin
  const State = GetNetworkConnected;
  if State <> LastNetworkConnectedState then begin
    if State then
      Caption := APP_NAME
    else
      Caption := APP_NAME + ' (Offline)';

    LastNetworkConnectedState := State;
  end;
end;

procedure TMainForm.WaitBrowserInitialization;
begin
  var I: integer; I := 0;
  while not BrowserInitialized and (I < 5000) do begin
      Sleep(1);
      Application.ProcessMessages;
  end;
end;

procedure TMainForm.WaitBrowserNavigation;
begin
  var I: integer; I := 0;
  while not BrowserNavigating and (I < 5000) do begin
      Sleep(1);
      Application.ProcessMessages;
  end;
end;

procedure TMainForm.WMActivate(var Msg: TWMActivate);
begin
  inherited;

  if (Msg.Active in [WA_ACTIVE, WA_CLICKACTIVE]) and not Msg.Minimized then
    try
      // Select webview
      if Browser.Visible then
        Browser.DoEnter;
        //Browser.SetFocus;
    except
    end;
end;

procedure TMainForm.WMRestoreAppFromTray(var Message: TMessage);
begin
  RestoreFromTray;
end;

procedure TMainForm.WMSysCommand(var Message: TWMSysCommand);
begin
  // Handle menus
  case Message.CmdType of
    MENU_ACTION_RELOAD: ReloadWebViewBase;
    MENU_ACTION_TRAY: MinimizeToTray;
    MENU_ACTION_SETTINGS: OpenSettingsForm;
  end;

  // Done
  inherited;
end;

procedure TMainForm.YourLibrary1Click(Sender: TObject);
begin

end;

{ TMainBrowser }

constructor TMainBrowser.Create(AOwner: TComponent);
begin
  inherited;
  OnCreateWebViewCompleted := HandleCreateWebViewCompleted;

  // Args
  AdditionalBrowserArguments := '--autoplay-policy=no-user-gesture-required'; // tried:  --disable-features=MediaControls,GlobalMediaControls - does not work!!
end;

procedure TMainBrowser.ExecuteScript(const JavaScript: string;
  Callback: TScriptCallback);
begin
  if DefaultInterface <> nil then
    DefaultInterface.ExecuteScript(PChar(JavaScript),
      Callback<HResult, PChar>.CreateAs<ICoreWebView2ExecuteScriptCompletedHandler>(
        function(ErrorCode: HResult; ResultObjectAsJson: PWideChar): HResult stdcall
        begin
          Result := S_OK;

          if Assigned(Callback) then
            Callback(ErrorCode, string(ResultObjectAsJson));
        end));
end;

function TMainBrowser.ExecuteScriptAwait(const JavaScript: string; out Output: string; Timeout: cardinal=1000): boolean;
var
  FWaiting: boolean;
  FResult: string;
begin
  const StartTime = Now;
  FWaiting := true;
  if DefaultInterface <> nil then
    DefaultInterface.ExecuteScript(PChar(JavaScript),
      Callback<HResult, PChar>.CreateAs<ICoreWebView2ExecuteScriptCompletedHandler>(
        function(ErrorCode: HResult; ResultObjectAsJson: PWideChar): HResult stdcall
        begin
          Result := S_OK;

          FResult := string(ResultObjectAsJson);
          FWaiting := false;
        end));

  // Wait
  while FWaiting do begin
    Sleep(10);
    Application.ProcessMessages;

    if MilliSecondsBetween(StartTime, Now) >= Timeout then
      Exit(false);
  end;

  // Done
  Output := FResult;
  Result := true;
end;

procedure TMainBrowser.HandleCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HResult);
var
  View3: ICoreWebView2_13;
  Profile: ICoreWebView2Profile;
begin
  // Set dark mode
  if Assigned(DefaultInterface) then
    if Succeeded(DefaultInterface.QueryInterface(ICoreWebView2_13, View3)) then
      if Succeeded(View3.Get_Profile(Profile)) and Assigned(Profile) then
        if not Succeeded(Profile.Set_PreferredColorScheme( COREWEBVIEW2_PREFERRED_COLOR_SCHEME_DARK )) then
          OutputDebugString('Failed to set profile.');
end;

procedure TMainBrowser.OpenDevTools;
begin
  if Assigned(DefaultInterface) then
    DefaultInterface.OpenDevToolsWindow;
end;

initialization
  // Register app
  AppRegistration.AppUserModelID := APP_USER_MODEL_ID;

  VersionCheck := TStandardVersionCheckerUpdateUrl.Create(API_APP_NAME, VERSION);

  Manager := TNotificationManager.Create;
finalization
  VersionCheck.Free;
end.
