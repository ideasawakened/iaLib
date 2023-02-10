unit iaRTL.SyncBucket.Items;

interface

uses
  System.Generics.Collections,
  Data.DB,
  FireDAC.Comp.Client,
  iaRTL.Cloud.S3Object;

type

  TSyncStatus = (Unknown, StatusCleared, NoChangesDetected, ChangedItem, NewItem, NotFound);


  TSyncItem = class
  private
    fDB:TFDConnection;
    fObjectKey:string;
    fETag:string;
    fSize:Int64;
    fSyncStatus:TSyncStatus;
  protected
    procedure SetFromDataSet(const DataSet:TDataSet);
  public
    constructor Create(const FDConnection:TFDConnection);

    property ObjectKey:string read fObjectKey write fObjectKey;
    property ETag:string read fETag write fETag;
    property SyncStatus:TSyncStatus read fSyncStatus write fSyncStatus;
    property Size:Int64 read fSize write fSize;

    procedure Clear;
    procedure SetFromS3Object(const SourceObject:TS3Object; const NewSyncStatus:TSyncStatus);

    function GetFromDB(const ObjectKeyToFind:string):Boolean;
    procedure InsertIntoDB;
    procedure UpdateDB;
    procedure UpdateDBSyncStatus;
    procedure DeleteFromDB;
  end;


  TSyncItemList = class(TObjectList<TSyncItem>)
  private
    fDB:TFDConnection;
  public
    constructor Create(const FDConnection:TFDConnection);

    procedure GetSyncItemsFromDB(const SyncStatusToFind:TSyncStatus);
  end;


implementation

uses
  System.SysUtils;


constructor TSyncItem.Create(const FDConnection:TFDConnection);
begin
  fDB := FDConnection;
end;


procedure TSyncItem.Clear;
begin
  ObjectKey := '';
  ETag := '';
  Size := 0;
  SyncStatus := TSyncStatus.Unknown;
end;


procedure TSyncItem.SetFromDataSet(const DataSet:TDataSet);
begin
  ObjectKey := DataSet.FieldByName('ObjectKey').AsString;
  ETag := DataSet.FieldByName('ETag').AsString;
  Size := DataSet.FieldByName('Size').AsLargeInt;
  SyncStatus := TSyncStatus(DataSet.FieldByName('SyncStatus').AsInteger);
end;


procedure TSyncItem.SetFromS3Object(const SourceObject:TS3Object; const NewSyncStatus:TSyncStatus);
begin
  ObjectKey := SourceObject.ObjectKey;
  ETag := SourceObject.ETag;
  Size := SourceObject.Size;
  SyncStatus := NewSyncStatus;
end;


procedure TSyncItem.InsertIntoDB;
begin
  fDB.ExecSQL('INSERT INTO SyncItems (ObjectKey, ETag, Size, SyncStatus) VALUES (:ObjectKey, :ETag, :Size, :SyncStatus)', [ObjectKey, ETag, Size, Ord(SyncStatus)]);
end;


procedure TSyncItem.UpdateDB;
begin
  fDB.ExecSQL('UPDATE SyncItems SET ETag=:ETag, Size=:Size, SyncStatus=:Status WHERE ObjectKey=:ObjectKey', [ETag, Size, Ord(SyncStatus), ObjectKey])
end;


procedure TSyncItem.UpdateDBSyncStatus;
begin
  fDB.ExecSQL('UPDATE SyncItems SET SyncStatus=:Status WHERE ObjectKey=:ObjectKey', [Ord(SyncStatus), ObjectKey])
end;

procedure TSyncItem.DeleteFromDB;
begin
  fDB.ExecSQL('DELETE FROM SyncItems WHERE ObjectKey=:ObjectKey', [ObjectKey]);
end;


function TSyncItem.GetFromDB(const ObjectKeyToFind:string):Boolean;
var
  Query:TFDQuery;
begin
  Result := False;

  Self.Clear;
  ObjectKey := ObjectKeyToFind;
  SyncStatus := TSyncStatus.NewItem;

  Query := TFDQuery.Create(nil);
  try
    Query.Connection := fDB;
    Query.Open('SELECT * FROM SyncItems WHERE ObjectKey=:ObjectKey', [ObjectKeyToFind]);
    if not Query.IsEmpty then
    begin
      SetFromDataSet(Query);
      Result := True;
    end;
  finally
    Query.Free;
  end;
end;


constructor TSyncItemList.Create(const FDConnection:TFDConnection);
begin
  inherited Create;
  fDB := FDConnection;
end;


procedure TSyncItemList.GetSyncItemsFromDB(const SyncStatusToFind:TSyncStatus);
var
  Query:TFDQuery;
  SyncItem:TSyncItem;
begin
  Self.Clear;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := fDB;
    Query.Open('SELECT * FROM SyncItems WHERE SyncStatus=:SyncStatus ORDER BY ObjectKey', [Ord(SyncStatusToFind)]);
    while not Query.Eof do
    begin
      SyncItem := TSyncItem.Create(fDB);
      SyncItem.SetFromDataSet(Query);
      Self.Add(SyncItem);

      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;


end.
