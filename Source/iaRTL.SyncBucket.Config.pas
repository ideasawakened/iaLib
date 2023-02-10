unit iaRTL.SyncBucket.Config;

interface

uses
  iaRTL.API.Keys;

type

  TSyncBucketConfig = record
  private const
    defBaseName = 'SyncBucket';
    defDatabaseName = defBaseName + '.db3';
    defINIFileName = defBaseName + '.ini';
    INISection = defBaseName + 'Config';
  private
    AppPath:string;
    AWSConfigProfile:string;
    procedure SetDefaults;
  public
    BucketName:string;
    Region:string;
    APIKeys:TAPIKeys;
    DataBaseFileName:string;
    LocalSyncFolder:string;
    StartingFolderPrefix:string;

    procedure LoadFromINI;
  end;

implementation

uses
  System.SysUtils,
  System.IniFiles,
  iaRTL.SysUtils,
  iaRTL.Cloud.AmazonContext;



procedure TSyncBucketConfig.SetDefaults;
var
  AmazonContext:TAmazonContext;
begin
  AppPath := IncludeTrailingPathDelimiter(ExtractFilePath(TSysUtils.GetApplicationFileName));
  LocalSyncFolder := AppPath;
  DataBaseFileName := AppPath + defDatabaseName;
  BucketName := TEnvironmentUtils.Get('SOURCE_SYNC_BUCKET_NAME');

  // Follow external AWS CLI configuration, but allow Region/Keys to be overriden by this custom INI file
  AmazonContext := Default(TAmazonContext);
  AmazonContext.Init;

  Region := AmazonContext.Region;
  AWSConfigProfile := AmazonContext.Config.ProfileName;
  APIKeys.AccessKey := AmazonContext.APIKeys.AccessKey;
  APIKeys.SecretKey := AmazonContext.APIKeys.SecretKey;
  StartingFolderPrefix := ''; // default to sync from the root of the bucket
end;


procedure TSyncBucketConfig.LoadFromINI;
var
  INIFile:TIniFile;
  DefaultProfile:string;
  AmazonContext:TAmazonContext;
begin
  SetDefaults;

  //All defaults can be overriden by INI settings
  if FileExists(AppPath + defINIFileName) then
  begin
    INIFile := TIniFile.Create(AppPath + defINIFileName);
    try
      DataBaseFileName := INIFile.ReadString(INISection, 'DatabaseFileName', DataBaseFileName);
      if SameText(ExtractFileName(DataBaseFileName), DataBaseFileName) then
      begin
        // no path specified, default to same as executable
        DataBaseFileName := AppPath + DataBaseFileName;
      end;
      LocalSyncFolder := INIFile.ReadString(INISection, 'LocalSyncFolder', LocalSyncFolder);
      BucketName := INIFile.ReadString(INISection, 'BucketName', BucketName);
      StartingFolderPrefix := INIFile.ReadString(INISection, 'StartingFolderPrefix', StartingFolderPrefix);

      // Check optional custom AWS config profile which can override defaults
      DefaultProfile := AWSConfigProfile;
      AWSConfigProfile := INIFile.ReadString(INISection, 'AWS_PROFILE', DefaultProfile);
      if not SameText(AWSConfigProfile, DefaultProfile) then
      begin
        AmazonContext := Default(TAmazonContext);
        AmazonContext.Init;
        AmazonContext.LoadProfile(AWSConfigProfile);
        APIKeys.AccessKey := AmazonContext.APIKeys.AccessKey;
        APIKeys.SecretKey := AmazonContext.APIKeys.SecretKey;
      end;

      // if not otherwise set, must be set by this config file
      Region := INIFile.ReadString(INISection, 'Region', Region);
      APIKeys.AccessKey := INIFile.ReadString(INISection, 'aws_access_key_id', APIKeys.AccessKey);
      APIKeys.SecretKey := INIFile.ReadString(INISection, 'aws_secret_access_key', APIKeys.SecretKey);
    finally
      INIFile.Free;
    end;
  end;
end;

end.
