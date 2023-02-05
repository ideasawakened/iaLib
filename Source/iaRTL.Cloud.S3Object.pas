unit iaRTL.Cloud.S3Object;

interface

uses
  System.Generics.Collections,
  Data.Cloud.AmazonAPI;

type

  TS3Object = class
  public const
    // There is no native support for 'folders' in S3...the normal convention is to create a zero length object with its object key name ending in / to act as a folder
    S3PathDelimiter = '/';
  private
    fObjectKey:string;
    fETag:string;
    fSize:Int64;
    fServerSideModified:string;
    fOwnerId:string;
    fOwnerDisplayName:string;
    fVersionId:string;
    fIsLatest:Boolean;
    fIsDeleted:Boolean;
    fStorageClass:string;
  public
    property ObjectKey:string read fObjectKey write fObjectKey;
    property ETag:string read fETag write fETag;
    property Size:Int64 read fSize write fSize;
    property ServerSideModified:string read fServerSideModified write fServerSideModified;
    property OwnerId:string read fOwnerId write fOwnerId;
    property OwnerDisplayName:string read fOwnerDisplayName write fOwnerDisplayName;
    property VersionId:string read fVersionId write fVersionId;
    property IsLatest:Boolean read fIsLatest write fIsLatest;
    property IsDeleted:Boolean read fIsDeleted write fIsDeleted;
    property StorageClass:string read fStorageClass write fStorageClass;

    procedure SetFromAmazonObjectResult(const Rec:TAmazonObjectResult);

    class function ObjectKeyUsingNativeDelimiter(const ObjectKey:string):string;
  end;


  TS3ObjectList = TObjectList<TS3Object>;


implementation
uses
  System.SysUtils;


procedure TS3Object.SetFromAmazonObjectResult(const Rec:TAmazonObjectResult);
begin
  ObjectKey := Rec.Name;
  ETag := Rec.ETag;
  Size := Rec.Size;
  ServerSideModified := Rec.LastModified;
  OwnerId := Rec.OwnerId;
  OwnerDisplayName := Rec.OwnerDisplayName;
  VersionId := Rec.VersionId;
  IsLatest := Rec.IsLatest;
  IsDeleted := Rec.IsDeleted;
  StorageClass := Rec.StorageClass;
end;


class function TS3Object.ObjectKeyUsingNativeDelimiter(const ObjectKey:string):string;
begin
  if TS3Object.S3PathDelimiter = System.SysUtils.PathDelim then
  begin
    Result := ObjectKey;
  end
  else
  begin
    //On Windows, replace the S3 object name "myfolder/myobject" with "myfolder\myobject" for working with local file system
    Result := StringReplace(ObjectKey, TS3Object.S3PathDelimiter, System.SysUtils.PathDelim, [rfReplaceAll]);
  end;
end;

end.
