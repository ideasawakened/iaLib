program iaDemo.SyncBucket.ToFolder;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  iaRTL.API.Keys in '..\..\Source\iaRTL.API.Keys.pas',
  iaRTL.Cloud.AmazonContext in '..\..\Source\iaRTL.Cloud.AmazonContext.pas',
  iaRTL.Cloud.AmazonRegions in '..\..\Source\iaRTL.Cloud.AmazonRegions.pas',
  iaRTL.Cloud.S3Bucket in '..\..\Source\iaRTL.Cloud.S3Bucket.pas',
  iaRTL.Cloud.S3Folder in '..\..\Source\iaRTL.Cloud.S3Folder.pas',
  iaRTL.Cloud.S3Object in '..\..\Source\iaRTL.Cloud.S3Object.pas',
  iaRTL.SysUtils in '..\..\Source\iaRTL.SysUtils.pas',
  iaRTL.SyncBucket.Config in '..\..\Source\iaRTL.SyncBucket.Config.pas',
  iaRTL.SyncBucket.CreateDB in '..\..\Source\iaRTL.SyncBucket.CreateDB.pas',
  iaRTL.SyncBucket.ToFolder in '..\..\Source\iaRTL.SyncBucket.ToFolder.pas',
  iaRTL.SyncBucket.Items in '..\..\Source\iaRTL.SyncBucket.Items.pas',
  iaDemo.SyncBucket.ConsoleMode in 'iaDemo.SyncBucket.ConsoleMode.pas';

var
  BucketSync:TConsoleModeSyncBucketToFolder;
begin
  try

    BucketSync := TConsoleModeSyncBucketToFolder.Create;
    try
      BucketSync.PerformSync;
    finally
      BucketSync.Free;
    end;

  except
    on E: Exception do
    begin
      ExitCode := 1;
      Writeln(E.ClassName, ': ', E.Message);
    end;
  end;

  {$IFDEF DEBUG}
  Readln;
  {$ENDIF}
end.
