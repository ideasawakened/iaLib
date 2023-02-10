unit iaRTL.SyncBucket.CreateDB;

interface

uses
  FireDAC.Comp.Client;

type

  TSyncBucketDBCreator = class
  public
    class procedure CreateDatabase(FDConnection:TFDConnection; const DataBaseFileName:string);
  end;

implementation

uses
  System.Classes,
  FireDAC.Phys.SQLite,
  FireDAC.Stan.Def,
  FireDAC.Comp.ScriptCommands,
  FireDAC.Phys.SQLiteWrapper.Stat, // static, no DLLs needed
  FireDAC.Comp.Script;


class procedure TSyncBucketDBCreator.CreateDatabase(FDConnection:TFDConnection; const DataBaseFileName:string);
var
  ScriptText:TStringList;
  FDScript:TFDScript;
begin

  ScriptText := TStringList.Create;
  try
    ScriptText.Add('CREATE TABLE SyncItems (ObjectKey TEXT PRIMARY KEY NOT NULL, ETag TEXT NOT NULL, Size INTEGER NOT NULL, SyncStatus INTEGER NOT NULL)');
    FDScript := TFDScript.Create(nil);
    try
      FDScript.Connection := FDConnection;
      FDScript.ExecuteScript(ScriptText);
    finally
      FDScript.Free;
    end;
  finally
    ScriptText.Free;
  end;
end;

end.
