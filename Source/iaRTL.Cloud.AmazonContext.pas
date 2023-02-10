unit iaRTL.Cloud.AmazonContext;

interface

uses
  iaRTL.API.Keys,
  iaRTL.Cloud.AmazonRegions;

type

  TAmazonConfigSettings = record
    ConfigFileName:string;
    CredentialsFileName:string;
    ProfileName:string;
  end;


  /// <summary> Attempt to retrieve AWS keys+region from environment variables, shared credentials file, or AWS CLI config file
  /// https://docs.aws.amazon.com/cli/latest/topic/config-vars.html
  TAmazonContext = record
  private const
    defProfile = 'default';
    defRegion = DEFAULT_AMAZON_REGION;
  private
    procedure GetEnvironmentVariables;
    function HomeDirectory:string;
  public
    APIKeys:TAPIKeys;
    Region:string;
    Config:TAmazonConfigSettings;
    procedure Init;
    procedure LoadProfile(const ProfileName:string);
  end;


implementation

uses
  System.SysUtils,
  System.IniFiles,
  System.IOUtils,
  iaRTL.SysUtils;


procedure TAmazonContext.Init;
begin
  // environment variables higher priority than config files
  GetEnvironmentVariables;

  if (APIKeys.AccessKey.Length = 0) or (APIKeys.SecretKey.Length = 0) or (Region.Length = 0) then
  begin
    LoadProfile(Config.ProfileName);
  end;
end;


procedure TAmazonContext.LoadProfile(const ProfileName:string);
var
  IniFile:TIniFile;
begin
  APIKeys.AccessKey := '';
  APIKeys.SecretKey := '';
  Region := '';

  if ProfileName.IsEmpty then
  begin
    Config.ProfileName := defProfile;
  end
  else
  begin
    Config.ProfileName := ProfileName;
  end;

  if FileExists(Config.ConfigFileName) then
  begin
    IniFile := TIniFile.Create(Config.ConfigFileName);
    try
      if SameText(Config.ProfileName, defProfile) then
      begin
        Region := IniFile.ReadString(defProfile, 'region', defRegion); // [default]
      end
      else
      begin
        Region := IniFile.ReadString('profile ' + Config.ProfileName, 'region', defRegion); // [profile user1]
      end;
    finally
      IniFile.Free;
    end;
  end;

  if FileExists(Config.CredentialsFileName) then
  begin
    IniFile := TIniFile.Create(Config.CredentialsFileName);
    try
      APIKeys.AccessKey := IniFile.ReadString(Config.ProfileName, 'aws_access_key_id', '');
      APIKeys.SecretKey := IniFile.ReadString(Config.ProfileName, 'aws_secret_access_key', '');
    finally
      IniFile.Free;
    end;
  end;
end;


// https://docs.aws.amazon.com/sdkref/latest/guide/file-location.html
function TAmazonContext.HomeDirectory:string;
begin
  Result := TPath.Combine(TPathUtils.GetUserHomePath, '.aws');
end;


// https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html
procedure TAmazonContext.GetEnvironmentVariables;
begin
  APIKeys.AccessKey := TEnvironmentUtils.Get('AWS_ACCESS_KEY_ID');
  APIKeys.SecretKey := TEnvironmentUtils.Get('AWS_SECRET_ACCESS_KEY');

  Region := TEnvironmentUtils.Get('AWS_REGION', defRegion);
  Config.ProfileName := TEnvironmentUtils.Get('AWS_PROFILE', defProfile);

  Config.ConfigFileName := TEnvironmentUtils.Get('AWS_CONFIG_FILE', HomeDirectory + PathDelim + 'config');
  Config.CredentialsFileName := TEnvironmentUtils.Get('AWS_SHARED_CREDENTIALS_FILE', HomeDirectory + PathDelim + 'credentials');
end;


end.
