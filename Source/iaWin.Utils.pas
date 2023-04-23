{
  Copyright 2019 Ideas Awakened Inc.
  Part of the "iaLib" shared code library for Delphi
  For more detail, see: https://github.com/ideasawakened/iaLib

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


Module History
1.0 2019-Dec-30 Darian Miller: Unit created for Universal Markup Editor project
}
unit iaWin.Utils;

interface
uses
  WinAPI.Windows,
  WinAPI.Messages;

type

  TiaWinUtils = class
  public
    class procedure CloseHandle(var h:THandle);
    class function CreateFileIfNotExists(const pFullPathName:string):Boolean;
    class function GetAbsolutePath(const pFileName:string; const pBaseDirectory:string):string;
    class function GetFileSize(const pFileName:string):Int64;
    class function GetTempFileName(const pThreeCharPrefix:string='tmp'):string;
    class function GetTempFilePath():string;
    class function GetWindowsFolder():string;
    class function GetWindowsSystemRoot():string;
    class function IsValidHandle(const h:THandle):Boolean;
    class procedure ShellOpenDocument(const pDoc:string);
    class function ShowFileInExplorer(const pFileName:string):Boolean;
  end;


implementation
uses
  System.SysUtils,
  WinAPI.ShellApi,
  WinAPI.ShLwApi,
  WinAPI.ShlObj;


class procedure TiaWinUtils.CloseHandle(var h:THandle);
begin
  if TiaWinUtils.IsValidHandle(h) then
  begin
    WinAPI.Windows.CloseHandle(h);
  end;
  h := INVALID_HANDLE_VALUE;
end;

class function TiaWinUtils.IsValidHandle(const h:THandle):Boolean;
begin
  Result := (h <> INVALID_HANDLE_VALUE) and (h <> 0);
end;


class function TiaWinUtils.GetFileSize(const pFileName:string):Int64;
var
  vFileInfo:TWin32FileAttributeData;
begin
  Result := -1;
  if GetFileAttributesEx(PWideChar(pFileName), GetFileExInfoStandard, @vFileInfo) then
  begin
    Int64Rec(Result).Lo := vFileInfo.nFileSizeLow;
    Int64Rec(Result).Hi := vFileInfo.nFileSizeHigh;
  end;
end;


class function TiaWinUtils.GetWindowsFolder():string;
var
  vLen:Integer;
begin
  Result := '';
  SetLength(Result, MAX_PATH);
  //https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getwindowsdirectoryw
  vLen := WinAPI.Windows.GetWindowsDirectory(PChar(Result), MAX_PATH);
  if vLen > 0 then
  begin
    SetLength(Result, vLen);
  end
  else
  begin
    RaiseLastOSError();
  end;
end;


class function TiaWinUtils.GetWindowsSystemRoot():string;
var
  vLen:Integer;
begin
  Result := '';
  SetLength(Result, MAX_PATH);
  //https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getsystemdirectoryw
  vLen := WinAPI.Windows.GetSystemDirectory(PChar(Result), MAX_PATH);
  if vLen > 0 then
  begin
    SetLength(Result, vLen);
  end
  else
  begin
    RaiseLastOSError();
  end;
end;


class function TiaWinUtils.GetTempFilePath():string;
var
  vLen:Integer;
begin
  Result := '';
  SetLength(Result, MAX_PATH);
  //https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-gettemppathw
  vLen := WinAPI.Windows.GetTempPath(MAX_PATH, PChar(Result));
  if vLen > 0 then
  begin
    SetLength(Result, vLen);
  end
  else
  begin
    RaiseLastOSError();
  end;
end;

class function TiaWinUtils.GetTempFileName(const pThreeCharPrefix:string='tmp'):string;
var
  vDirectory:String;
  vFileName:array[0..MAX_PATH] of char;
begin
  Result := '';
  vDirectory := TiaWinUtils.GetTempFilePath();
  SetLength(Result, MAX_PATH);
  //https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-gettempfilenamew
  if WinAPI.Windows.GetTempFileName(PChar(vDirectory), PChar(pThreeCharPrefix), 0, vFileName) <> 0 then
  begin
    Result := vFileName;
  end
  else
  begin
    RaiseLastOSError();
  end;
end;


//From David Hefferman: https://stackoverflow.com/a/5330691/35696
class function TiaWinUtils.GetAbsolutePath(const pFileName:string; const pBaseDirectory:string):string;
var
  Buffer: array [0..MAX_PATH-1] of Char;
begin
  //https://docs.microsoft.com/en-us/windows/win32/api/shlwapi/nf-shlwapi-pathisrelativew
  if PathIsRelative(PChar(pFileName)) then
  begin
    Result := IncludeTrailingPathDelimiter(pBaseDirectory)+pFileName;
  end
  else
  begin
    Result := pFileName;
  end;
  //https://docs.microsoft.com/en-us/windows/win32/api/shlwapi/nf-shlwapi-pathcanonicalizew
  if PathCanonicalize(@Buffer[0], PChar(Result)) then
  begin
    Result := Buffer;
  end;
end;

class procedure TiaWinUtils.ShellOpenDocument(const pDoc:string);
begin
  ShellExecute(0, 'open', PChar(pDoc), nil, nil, SW_SHOWNORMAL);
end;

class function TiaWinUtils.ShowFileInExplorer(const pFileName:string):Boolean;
var
  IIDL: PItemIDList;
begin
  Result := False;
  if FileExists(pFileName) then
  begin
    IIDL := ILCreateFromPath(PChar(pFileName));
    if IIDL <> nil then
    begin
      try
        Result := (SHOpenFolderAndSelectItems(IIDL, 0, nil, 0) = S_OK);
      finally
        ILFree(IIDL);
      end;
    end;
  end;
end;


class function TiaWinUtils.CreateFileIfNotExists(const pFullPathName:string):Boolean;
var
  h:THandle;
begin
  Result := False;  //check GetLastError if fail
  //https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilew
  h := CreateFile(PChar(pFullPathName), FILE_APPEND_DATA, 0, nil, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, 0);
  if IsValidHandle(h) then
  begin
    CloseHandle(h);
    Result := True;
  end;
end;



end.
