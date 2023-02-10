unit iaRTL.SysUtils;

interface

type

  TPathUtils = class
  private const
    {$IFDEF MSWINDOWS}
    HomePathEnvironmentVariable = 'UserProfile';
    {$ELSE}
    HomePathEnvironmentVariable = 'HOME';
    {$ENDIF}
  public
    class function GetUserHomePath:string;
  end;


  TEnvironmentUtils = class
  public
    class function Get(const VariableName:string; const DefaultValue:string = ''):string;
  end;

  TSysUtils = class
  public
    class function GetApplicationFileName:string;
  end;

implementation

uses
  {$IFDEF MSWINDOWS}
  WinAPI.Windows, //max_path
  {$ENDIF}
  System.SysUtils;


class function TPathUtils.GetUserHomePath:string;
begin
  Result := GetEnvironmentVariable(HomePathEnvironmentVariable);
end;

{$IFDEF MSWINDOWS}
class function TSysUtils.GetApplicationFileName:string;
var
  Buffer:Array[0..MAX_PATH] of Char;
begin
  if IsLibrary then
  begin
    SetString(Result, Buffer, GetModuleFileName(HInstance, Buffer, SizeOf(Buffer)));
  end
  else
  begin
    Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  end;
end;
{$ELSE}
class function TSysUtils.GetApplicationFileName:string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;
{$ENDIF}

class function TEnvironmentUtils.Get(const VariableName:string; const DefaultValue:string = ''):string;
begin
  Result := GetEnvironmentVariable(VariableName);
  if Result.Length = 0 then
  begin
    Result := DefaultValue;
  end;
end;


end.
