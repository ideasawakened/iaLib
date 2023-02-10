unit iaRTL.Cloud.S3Folder;

interface

uses
  System.Classes,
  System.Generics.Collections,
  iaRTL.Cloud.S3Object;

type

  TS3Folder = class;


  TS3FolderList = class(TObjectList<TS3Folder>)
  public
    function AddFolderName(const FolderName:string):Integer;
    procedure AddFolderList(const FolderNames:TStrings);
  end;


  TS3Folder = class
  private
    fFolderName:string;
    fObjectList:TS3ObjectList;
    fChildFolders:TS3FolderList;
  public
    constructor Create(const FolderName:string = '');
    destructor Destroy; override;

    procedure Clear;
    procedure ToStrings(const Destination:TStrings; const Recursive:Boolean = True);

    property FolderName:string read fFolderName write fFolderName;
    property ObjectList:TS3ObjectList read fObjectList write fObjectList;
    property ChildFolders:TS3FolderList read fChildFolders write fChildFolders;
  end;


implementation

uses
  System.SysUtils;


constructor TS3Folder.Create(const FolderName:string = '');
begin
  fFolderName := FolderName;
  fObjectList := TS3ObjectList.Create;
  fChildFolders := TS3FolderList.Create;
end;


destructor TS3Folder.Destroy;
begin
  fChildFolders.Free;
  fObjectList.Free;
  inherited;
end;


procedure TS3Folder.Clear;
begin
  FolderName := '';
  ObjectList.Clear;
  ChildFolders.Clear;
end;


procedure TS3Folder.ToStrings(const Destination:TStrings; const Recursive:Boolean = True);
var
  BucketObject:TS3Object;
  SubDirectory:TS3Folder;
begin
  for BucketObject in ObjectList do
  begin
    Destination.Add(BucketObject.ObjectKey);
  end;
  for SubDirectory in ChildFolders do
  begin
    Destination.Add(SubDirectory.FolderName);
    if Recursive then
    begin
      SubDirectory.ToStrings(Destination, Recursive);
    end;
  end;
end;


function TS3FolderList.AddFolderName(const FolderName:string):Integer;
begin
  Result := Self.Add(TS3Folder.Create(FolderName));
end;


procedure TS3FolderList.AddFolderList(const FolderNames:TStrings);
var
  FolderName:string;
begin
  for FolderName in FolderNames do
  begin
    AddFolderName(FolderName);
  end;
end;


end.
