//toconsider: provide log levels (debug/info/warning...) if using an actual logging library
unit iaRTL.SyncBucket.ToFolder;

interface

uses
  System.Classes,
  Data.Cloud.CloudAPI,
  FireDAC.Comp.Client,
  iaRTL.API.Keys,
  iaRTL.Cloud.S3Object,
  iaRTL.Cloud.S3Folder,
  iaRTL.Cloud.S3Bucket,
  iaRTL.SyncBucket.Config,
  iaRTL.SyncBucket.Items;


type

  TSyncAction = (DeleteLocalFile, DownloadChangedFile, DownloadNewFile);

  TOnPrepareSyncAction = procedure(const SyncItem:TSyncItem; const ActionToTake:TSyncAction; var SkipAction:Boolean) of object;
  TOnAfterSyncAction = procedure(const SyncItem:TSyncItem; const ActionTaken:TSyncAction; const LocalFileName:string) of object;
  TOnLog = procedure(const S: string) of object;

  TSyncBucketToFolder = class
  private
    fDB:TFDConnection;
    fConfig:TSyncBucketConfig;
    fLogProc:TOnLog;

    fOnPrepareSyncAction:TOnPrepareSyncAction;
    fOnAfterSyncAction:TOnAfterSyncAction;
    function FolderDisplayName(const FolderName:string):string;

    procedure DoOnGetBucketCall(const BucketName:string; const Parameters:TStrings);
    procedure DoOnGetBucketResult(const BucketName:string; const FolderName:string; const CloudResponseInfo:TCloudResponseInfo; const SubFolderCount:Integer; const ObjectCount:Integer);
  protected
    procedure Log(const LogText:string);
    procedure InitializeSync(LocalPath:string);
    procedure SyncS3FolderContents(const Bucket:TS3Bucket; const S3Folder:TS3Folder; const LocalPath:string);
    procedure FinalizeSync(LocalPath:string);
  public
    constructor Create(const Config:TSyncBucketConfig; const LogProc:TOnLog=nil);
    destructor Destroy; override;

    procedure SyncToFolder;

    property DB:TFDConnection read fDB;
    property Config:TSyncBucketConfig read fConfig;

    /// <summary> Receive notification for each item about to be synchronized (Download or Delete local copy) </summary>
    /// <remarks> Can cancel action for times when there is not enough space or if you want to keep the old item on file </remarks>
    property OnPrepareSyncAction:TOnPrepareSyncAction read fOnPrepareSyncAction write fOnPrepareSyncAction;

    /// <summary> Receive notification for each synchronized item after a Download or Delete local copy action has completed </summary>
    property OnAfterSyncAction:TOnAfterSyncAction read fOnAfterSyncAction write fOnAfterSyncAction;
  end;


implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.RTTI,
  iaRTL.SyncBucket.CreateDB;


constructor TSyncBucketToFolder.Create(const Config:TSyncBucketConfig; const LogProc:TOnLog=nil);
var
  NeedToCreateSchema:Boolean;
begin
  fConfig := Config;
  fLogProc := LogProc;

  fDB := TFDConnection.Create(nil);
  fDB.DriverName := 'SQLite';
  fDB.LoginPrompt := False;
  fDB.Params.Database := fConfig.DataBaseFileName;

  NeedToCreateSchema := TFile.GetSize(fDB.Params.Database) <= 0;
  fDB.Connected := True; // creates a zero length file if not found
  if NeedToCreateSchema then
  begin
    TSyncBucketDBCreator.CreateDatabase(fDB, fDB.Params.Database);
  end;
end;


destructor TSyncBucketToFolder.Destroy;
begin
  fDB.Free;
  inherited;
end;


procedure TSyncBucketToFolder.SyncToFolder;
var
  Bucket:TS3Bucket;
  LocalPath:string;
begin
  LocalPath := IncludeTrailingPathDelimiter(Config.LocalSyncFolder);
  InitializeSync(LocalPath);

  Bucket := TS3Bucket.Create(Config.BucketName, Config.Region, Config.APIKeys);
  try
    Bucket.OnGetBucketCall := DoOnGetBucketCall;
    Bucket.OnGetBucketResult := DoOnGetBucketResult;

    //populate the list of all objects/folders currently within the bucket
    Bucket.GetBucketObjectList(Config.StartingFolderPrefix);

    //sync bucket contents
    SyncS3FolderContents(Bucket, Bucket.BaseFolder, LocalPath);
  finally
    Bucket.Free;
  end;

  //remove any local items no longer in bucket
  FinalizeSync(LocalPath);
end;


procedure TSyncBucketToFolder.InitializeSync(LocalPath:string);
begin
  Log('Initialize: Will sync to local path: ' + LocalPath);
  ForceDirectories(LocalPath);

  Log('Initialize: Cleanup items marked as not found');  //should have been cleared during sync pass, but previous update could have been intentionally skipped
  fDB.ExecSQL(Format('DELETE FROM SyncItems WHERE SyncStatus=%d', [Ord(TSyncStatus.NotFound)]));

  // Set special status flag of all local items - any items with this special status after the first pass is completed can be assumed to be no longer in the bucket
  Log(Format('Initialize: setting status of all items to %s', [TRttiEnumerationType.GetName(TSyncStatus.StatusCleared)]));
  fDB.ExecSQL(Format('UPDATE SyncItems SET SyncStatus=%d', [Ord(TSyncStatus.StatusCleared)]));
end;


procedure TSyncBucketToFolder.FinalizeSync(LocalPath:string);
var
  SyncItemList:TSyncItemList;
  SyncItem:TSyncItem;
  LocalFileName:string;
  SkipAction:Boolean;
begin
  Log('Finalize: Perform second pass to find local items no longer in the bucket');
  SyncItemList := TSyncItemList.Create(fDB);
  try
    //find all items not touched by the first pass
    SyncItemList.GetSyncItemsFromDB(TSyncStatus.StatusCleared);

    for SyncItem in SyncItemList do
    begin
      SyncItem.SyncStatus := TSyncStatus.NotFound;

      if Assigned(OnPrepareSyncAction) then
      begin
        SkipAction := False;
        OnPrepareSyncAction(SyncItem, TSyncAction.DeleteLocalFile, SkipAction);
        if SkipAction then
        begin
          Log('Item no longer in bucket, but will intentionally skip local update: ' + SyncItem.ObjectKey);
          SyncItem.UpdateDBSyncStatus;  // Just for completeness sakes
          Continue;
        end;
      end;

      Log('Item no longer in bucket, removing from SyncItems table and deleting local copy: ' + SyncItem.ObjectKey);
      SyncItem.DeleteFromDB;
      LocalFileName := LocalPath + TS3Object.ObjectKeyUsingNativeDelimiter(SyncItem.ObjectKey);
      System.SysUtils.DeleteFile(LocalFileName);

      if Assigned(OnAfterSyncAction) then
      begin
        OnAfterSyncAction(SyncItem, TSyncAction.DeleteLocalFile, LocalFileName);
      end;
    end;
  finally
    SyncItemList.Free;
  end;
  Log('Sync completed!');
end;


function TSyncBucketToFolder.FolderDisplayName(const FolderName:string):string;
begin
  if FolderName.IsEmpty then
  begin
    Result := '{root}';
  end
  else
  begin
    Result := FolderName;
  end;
end;


procedure TSyncBucketToFolder.DoOnGetBucketCall(const BucketName:string; const Parameters:TStrings);
begin
  Log(Format('Contacting AWS to retrieve batch list of bucket objects, folder: %s', [FolderDisplayName(Parameters.Values['prefix'])]));
end;


procedure TSyncBucketToFolder.DoOnGetBucketResult(const BucketName:string; const FolderName:string; const CloudResponseInfo:TCloudResponseInfo; const SubFolderCount:Integer; const ObjectCount:Integer);
begin
  Log(Format('AWS batch result for folder %s contains %d subfolders and %d objects', [FolderName, SubFolderCount, ObjectCount]));
end;


procedure TSyncBucketToFolder.SyncS3FolderContents(const Bucket:TS3Bucket; const S3Folder:TS3Folder; const LocalPath:string);
var
  SyncItem:TSyncItem;
  LocalFileName:string;
  S3Object:TS3Object;
  ChildFolder:TS3Folder;
  SkipAction:Boolean;
begin
  Log('Attempting to sync all items currently in folder: ' + FolderDisplayName(S3Folder.FolderName));
  SyncItem := TSyncItem.Create(fDB);
  try
    for S3Object in S3Folder.ObjectList do
    begin
      SkipAction := False;
      LocalFileName := LocalPath + TS3Object.ObjectKeyUsingNativeDelimiter(S3Object.ObjectKey);

      if SyncItem.GetFromDB(S3Object.ObjectKey) then
      begin
        if (SyncItem.ETag = S3Object.ETag) and (TFile.GetSize(LocalFileName) = S3Object.Size) then
        begin
          SyncItem.SyncStatus := TSyncStatus.NoChangesDetected;
          SyncItem.UpdateDBSyncStatus;  // Must update status so item doesn't appear in second pass
        end
        else
        begin
          SyncItem.SetFromS3Object(S3Object, TSyncStatus.ChangedItem);

          if Assigned(OnPrepareSyncAction) then
          begin
            OnPrepareSyncAction(SyncItem, TSyncAction.DownloadChangedFile, SkipAction);
            if SkipAction then
            begin
              Log('Found changed item, but will intentionally skip local update: ' + SyncItem.ObjectKey);
              SyncItem.UpdateDBSyncStatus;  // Must update status so item doesn't appear in second pass
            end;
          end;

          if not SkipAction then
          begin
            Log('Item changed, need to download: ' + S3Object.ObjectKey);
            // toconsider: download to temp file and then copy over existing file instead of direct overwrite (in case of errors during download)
            Bucket.DownloadObjectToFile(SyncItem.ObjectKey, LocalFileName);
            SyncItem.UpdateDb;

            if Assigned(OnAfterSyncAction) then
            begin
              OnAfterSyncAction(SyncItem, TSyncAction.DownloadChangedFile, LocalFileName);
            end;
          end;
        end;
      end
      else
      begin
        SyncItem.SetFromS3Object(S3Object, TSyncStatus.NewItem);

        if Assigned(OnPrepareSyncAction) then
        begin
          OnPrepareSyncAction(SyncItem, TSyncAction.DownloadNewFile, SkipAction);
          if SkipAction then
          begin
            Log('Found new item, but will intentionally skip local update: ' + SyncItem.ObjectKey);
            //Note: not applicable as item is not on file.  SyncItem.UpdateDBSyncStatus
          end;
        end;

        if not SkipAction then
        begin
          Log(Format('Found new item, need to download %s, size %d', [S3Object.ObjectKey, S3Object.Size]));
          Bucket.DownloadObjectToFile(SyncItem.ObjectKey, LocalFileName);
          SyncItem.InsertIntoDB;

          if Assigned(OnAfterSyncAction) then
          begin
            OnAfterSyncAction(SyncItem, TSyncAction.DownloadNewFile, LocalFileName);
          end;
        end;
      end;
    end;
  finally
    SyncItem.Free;
  end;

  // recursively process child folders
  for ChildFolder in S3Folder.ChildFolders do
  begin
    SyncS3FolderContents(Bucket, ChildFolder, LocalPath);
  end;
end;


procedure TSyncBucketToFolder.Log(const LogText:string);
begin
  if Assigned(fLogProc) then
  begin
    fLogProc(LogText);
  end;
end;


end.
