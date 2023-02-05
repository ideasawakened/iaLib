unit iaRTL.Cloud.S3Bucket;

interface

uses
  System.Classes,
  Data.Cloud.CloudAPI,
  Data.Cloud.AmazonAPI,
  iaRTL.API.Keys,
  iaRTL.Cloud.S3Object,
  iaRTL.Cloud.S3Folder;

type

  TOnGetBucketCall = procedure(const BucketName:string; const Parameters:TStrings) of object;
  TOnGetBucketResult = procedure(const BucketName:string; const FolderName:string; const CloudResponseInfo:TCloudResponseInfo; const SubFolderCount:Integer; const ObjectCount:Integer) of object;
  TOnGetBucketObjectInfo = procedure(const BucketName:string; const S3Object:TS3Object) of object;
  TOnDownloadObjectResult = procedure(const Result:Boolean; const ObjectKey:string; const CloudResponseInfo:TCloudResponseInfo) of object;


  TS3Bucket = class
  private
    fAmazonConnectionInfo:TAmazonConnectionInfo;
    fBaseFolder:TS3Folder;

    fBucketName:string;
    fRegion:string;
    fAPIKeys:TAPIKeys;

    fOnGetBucketCall:TOnGetBucketCall;
    fOnGetBucketResult:TOnGetBucketResult;
    fOnGetBucketObjectInfo:TOnGetBucketObjectInfo;
    fOnDownloadObjectResult:TOnDownloadObjectResult;
  protected
    procedure GetFolderDetails(const AmazonStorageService:TAmazonStorageService; const StartingFolder:TS3Folder; const Recursive:Boolean = True);
  public
    constructor Create(const ABucketName:string; const ABucketRegion:string; AKeys:TAPIKeys);
    destructor Destroy; override;

    /// <summary> Bucket name is globally unique within each of the three partitions. (Public, China, US-Gov)</summary>
    property BucketName:string read fBucketName;
    /// <summary> AWS region (short form), such as us-east-2</summary>
    property Region:string read fRegion;
    /// <summary> Populated by GetBucketObjectList where BaseFolder is the root folder of the bucket by default, but a "StartingFolderPrefix" could be specified for a partial copy</summary>
    property BaseFolder:TS3Folder read fBaseFolder;
    /// <summary> IAM Keys with appropriate S3 list/get permissions</summary>
    property APIKeys:TAPIKeys read fAPIKeys;

    /// <summary> Optionally called for each execution of "GetBucket" which is called recursively to retrieve the full list of objects (max 1000 results per call throttled by AWS)</summary>
    property OnGetBucketCall:TOnGetBucketCall read fOnGetBucketCall write fOnGetBucketCall;
    /// <summary> Optionally called for each completion of "GetBucket" to obtain access to TCloudResponseInfo and item counts related to the last call</summary>
    property OnGetBucketResult:TOnGetBucketResult read fOnGetBucketResult write fOnGetBucketResult;
    /// <summary> Optionally called for each object found by the "GetBucket" call. Can be used to optionally process objects before the full list is received</summary>
    property OnGetBucketObjectInfo:TOnGetBucketObjectInfo read fOnGetBucketObjectInfo write fOnGetBucketObjectInfo;
    /// <summary> Optionally called for each completion of "GetObject", mainly to get access to TCloudResponseInfo if desired</summary>
    property OnDownloadObjectResult:TOnDownloadObjectResult read fOnDownloadObjectResult write fOnDownloadObjectResult;

    /// <summary> Retrieve the list of bucket Object names and Folder names with the results stored in "BaseFolder"</summary>
    /// <param name="StartingFolderPrefix"> Can optionally set the starting folder, defaults to '' to start at the bucket root.  If specified, include the trailing S3 path delimiter, such as "salesdata/january2023/" to start retrieving objects in that folder</param>
    /// <param name="Recursive"> Child folders are recursively searched by default</param>
    procedure GetBucketObjectList(const StartingFolderPrefix:string = ''; const Recursive:Boolean = True);

    /// <summary> Download the binary contents of a S3 Object to a local file</summary>
    function DownloadObjectToFile(const ObjectKey:string; const LocalFileName:string):Boolean;

    /// <summary> Download the binary contents of a S3 Object to the target stream</summary>
    function DownloadObjectToStream(const ObjectKey:string; const DestinationStream:TStream):Boolean;
  end;


implementation

uses
  System.SysUtils,
  System.Rtti;


constructor TS3Bucket.Create(const ABucketName:string; const ABucketRegion:string; AKeys:TAPIKeys);
begin
  fBucketName := ABucketName;
  fRegion := ABucketRegion;
  fAPIKeys := AKeys;

  fBaseFolder := TS3Folder.Create;
  fAmazonConnectionInfo := TAmazonConnectionInfo.Create(nil);
  fAmazonConnectionInfo.Protocol := 'https'; // override old default of 'http'

  //toconsider: Make bucketname/region/apikeys properties read/write, but then need to set these before each AmazonStorageService call
  fAmazonConnectionInfo.Region := ABucketRegion;
  fAmazonConnectionInfo.AccountName := APIKeys.AccessKey;
  fAmazonConnectionInfo.AccountKey := APIKeys.SecretKey;
end;


destructor TS3Bucket.Destroy;
begin
  fAmazonConnectionInfo.Free;
  fBaseFolder.Free;
  inherited;
end;


function TS3Bucket.DownloadObjectToFile(const ObjectKey:string; const LocalFileName:string):Boolean;
var
  FileStream:TFileStream;
  LocalPath:string;
begin
  LocalPath := ExtractFilePath(LocalFileName);
  if not LocalPath.IsEmpty then
  begin
    ForceDirectories(LocalPath);
  end;

  FileStream := TFileStream.Create(LocalFileName, fmCreate);
  try
    Result := DownloadObjectToStream(ObjectKey, FileStream);
  finally
    FileStream.Free;
  end;
end;


function TS3Bucket.DownloadObjectToStream(const ObjectKey:string; const DestinationStream:TStream):Boolean;
var
  AmazonStorageService:TAmazonStorageService;
  CloudResponseInfo:TCloudResponseInfo;
begin
  AmazonStorageService := TAmazonStorageService.Create(fAmazonConnectionInfo);
  CloudResponseInfo := TCloudResponseInfo.Create;
  try

    Result := AmazonStorageService.GetObject(BucketName, ObjectKey, DestinationStream, CloudResponseInfo, Region);

    if Assigned(OnDownloadObjectResult) then
    begin
      OnDownloadObjectResult(Result, ObjectKey, CloudResponseInfo);
    end;

  finally
    CloudResponseInfo.Free;
    AmazonStorageService.Free;
  end;
end;


procedure TS3Bucket.GetBucketObjectList(const StartingFolderPrefix:string = ''; const Recursive:Boolean = True);
var
  AmazonStorageService:TAmazonStorageService;
begin
  BaseFolder.Clear;

  AmazonStorageService := TAmazonStorageService.Create(fAmazonConnectionInfo);
  try
    BaseFolder.FolderName := StartingFolderPrefix;
    GetFolderDetails(AmazonStorageService, BaseFolder, Recursive);
  finally
    AmazonStorageService.Free;
  end;
end;


procedure TS3Bucket.GetFolderDetails(const AmazonStorageService:TAmazonStorageService; const StartingFolder:TS3Folder; const Recursive:Boolean = True);
var
  AmazonBucketResult:TAmazonBucketResult;
  CloudResponseInfo:TCloudResponseInfo;
  BucketParameters:TStringList;
  i:Integer;
  IsTruncated:Boolean;
  S3Object:TS3Object;
  ChildFolder:TS3Folder;
begin
  BucketParameters := TStringList.Create;
  try
    BucketParameters.Values['prefix'] := StartingFolder.FolderName;
    BucketParameters.Values['delimiter'] := TS3Object.S3PathDelimiter; // used to create a list of objects recognized as folders and stored in 'prefixes'
    repeat

      if Assigned(OnGetBucketCall) then
      begin
        OnGetBucketCall(BucketName, BucketParameters);
      end;

      CloudResponseInfo := TCloudResponseInfo.Create;
      AmazonBucketResult := AmazonStorageService.GetBucket(BucketName, BucketParameters, CloudResponseInfo, Region);
      try

        if Assigned(OnGetBucketResult) then
        begin
          OnGetBucketResult(BucketName, StartingFolder.FolderName, CloudResponseInfo, AmazonBucketResult.Prefixes.Count, AmazonBucketResult.Objects.Count);
        end;

        for i := 0 to AmazonBucketResult.Objects.Count - 1 do
        begin
          S3Object := TS3Object.Create;
          S3Object.SetFromAmazonObjectResult(AmazonBucketResult.Objects[i]);
          StartingFolder.ObjectList.Add(S3Object);

          if Assigned(OnGetBucketObjectInfo) then
          begin
            // can possibly start processing objects before full bucket list is retrieved
            OnGetBucketObjectInfo(BucketName, S3Object);
          end;
        end;

        StartingFolder.ChildFolders.AddFolderList(AmazonBucketResult.Prefixes);
        BucketParameters.Values['marker'] := AmazonBucketResult.Marker;   //used in next call, if truncated
        IsTruncated := AmazonBucketResult.IsTruncated;
      finally
        CloudResponseInfo.Free;
        AmazonBucketResult.Free;
      end;
    until not IsTruncated;


    if Recursive then
    begin
      for ChildFolder in StartingFolder.ChildFolders do
      begin
        GetFolderDetails(AmazonStorageService, ChildFolder, Recursive);
      end;
    end;

  finally
    BucketParameters.Free;
  end;

end;


initialization

{$IFDEF CONSOLE}
{$IF defined(MSWINDOWS)}
// Note: this fixes the error "Microsoft MSXML is not installed" within a console project
// Source: https://wiert.me/2021/03/31/delphi-got-eoleexception-with-message-microsoft-msxml-is-not-installed-in-a-console-or-test-project/
// Archive: https://web.archive.org/web/20211017034226/https://wiert.me/2021/03/31/delphi-got-eoleexception-with-message-microsoft-msxml-is-not-installed-in-a-console-or-test-project/
if InitProc <> nil then
begin
  TProcedure(InitProc);
end;
{$ENDIF}
{$ENDIF}

end.
