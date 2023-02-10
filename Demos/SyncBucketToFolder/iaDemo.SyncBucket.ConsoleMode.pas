//https://github.com/ideasawakened/iaLib
//For upcoming blog article at: https://www.ideasawakened.com/blog
unit iaDemo.SyncBucket.ConsoleMode;

interface
uses
  System.Classes,
  Data.Cloud.CloudAPI,
  iaRTL.SyncBucket.Items,
  iaRTL.SyncBucket.ToFolder;


type

  TConsoleModeSyncBucketToFolder = class
  private
    fSyncBucketToFolder:TSyncBucketToFolder;
    procedure ConsoleLog(const LogText:string);
    procedure DoOnPrepareSyncAction(const SyncItem:TSyncItem; const ActionToTake:TSyncAction; var SkipAction:Boolean);
    procedure DoOnAfterSyncAction(const SyncItem:TSyncItem; const ActionTaken:TSyncAction; const LocalFileName:string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure PerformSync;
  end;


implementation
uses
  System.SysUtils,
  System.RTTI,
  iaRTL.Syncbucket.Config;


constructor TConsoleModeSyncBucketToFolder.Create;
var
  BucketConfig:TSyncBucketConfig;
begin
  BucketConfig.LoadFromINI;

  fSyncBucketToFolder := TSyncBucketToFolder.Create(BucketConfig, ConsoleLog);
  fSyncBucketToFolder.OnPrepareSyncAction := DoOnPrepareSyncAction;
  fSyncBucketToFolder.OnAfterSyncAction := DoOnAfterSyncAction;
end;


destructor TConsoleModeSyncBucketToFolder.Destroy;
begin
  fSyncBucketToFolder.Free;
  inherited;
end;


procedure TConsoleModeSyncBucketToFolder.PerformSync;
begin
  fSyncBucketToFolder.SyncToFolder;
end;


procedure TConsoleModeSyncBucketToFolder.ConsoleLog(const LogText: string);
begin
  //toconsider: Multi-thread protection, if desired
  WriteLn(LogText);
end;


procedure TConsoleModeSyncBucketToFolder.DoOnPrepareSyncAction(const SyncItem:TSyncItem; const ActionToTake:TSyncAction; var SkipAction:Boolean);
begin
  ConsoleLog(Format('PrepareSync action triggered for bucket item "%s". Will take action: "%s"', [SyncItem.ObjectKey, TRttiEnumerationType.GetName(ActionToTake)]));
end;


procedure TConsoleModeSyncBucketToFolder.DoOnAfterSyncAction(const SyncItem:TSyncItem; const ActionTaken:TSyncAction; const LocalFileName:string);
begin
  ConsoleLog(Format('AfterSync action triggered for bucket item "%s". Action taken: "%s" on local filename "%s"', [SyncItem.ObjectKey, TRttiEnumerationType.GetName(ActionTaken), LocalFileName]));
end;


end.
