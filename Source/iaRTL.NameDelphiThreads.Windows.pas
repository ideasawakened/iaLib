{
  Copyright 2023 Ideas Awakened Inc.
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


  Related blog post: https://www.ideasawakened.com/post/name-your-threads-even-the-ones-auto-created-by-delphi
  Also see: https://en.delphipraxis.net/topic/2677-do-you-name-your-threads-for-debugging/
}

unit iaRTL.NameDelphiThreads.Windows;

interface
uses
  WinAPI.Windows;

  procedure NameDelphiThreads;

implementation
uses
  System.SysUtils,
  System.Classes,
  WinAPI.TlHelp32;

type
  TGetThreadDescription = function(hThread: THandle; var ppszThreadDescription: PWideChar): HRESULT; stdcall;
  TSetThreadDescription = function(hThread: THandle; lpThreadDescription: PWideChar): HRESULT; stdcall;

  function OpenThread(dwDesiredAccess: DWORD; bInheritHandle: BOOL; dwThreadId: DWORD): THandle; stdcall; external 'kernel32.dll';

const //from winnt.h
  THREAD_TERMINATE                 = $0001;
  THREAD_SUSPEND_RESUME            = $0002;
  THREAD_GET_CONTEXT               = $0008;
  THREAD_SET_CONTEXT               = $0010;
  THREAD_QUERY_INFORMATION         = $0040;
  THREAD_SET_INFORMATION           = $0020;
  THREAD_SET_THREAD_TOKEN          = $0080;
  THREAD_IMPERSONATE               = $0100;
  THREAD_DIRECT_IMPERSONATION      = $0200;
  THREAD_SET_LIMITED_INFORMATION   = $0400;  // winnt
  THREAD_QUERY_LIMITED_INFORMATION = $0800;  // winnt
  THREAD_RESUME                    = $1000;  // winnt
  THREAD_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or SYNCHRONIZE or $FFFF;


procedure NameDelphiThreads;
var
  hSnapshot:THandle;
  hProcessId:THandle;
  hThread:THandle;
  hKernel32:THandle;
  ThreadDetails:TThreadEntry32;
  i:Integer;
  GetThreadDescription:TGetThreadDescription;
  SetThreadDescription:TSetThreadDescription;
  pDescription:PWideChar;
  ResultCode:HRESULT;
  ThreadName:String;
begin
  hProcessId := GetCurrentProcessId;
  hKernel32 := GetModuleHandle('Kernel32.dll');
  @GetThreadDescription := GetProcAddress(hKernel32, 'GetThreadDescription');
  @SetThreadDescription := GetProcAddress(hKernel32, 'SetThreadDescription');


  hSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, hProcessId);
  if hSnapshot <> INVALID_HANDLE_VALUE then
  begin
    try
      ThreadDetails := Default(TThreadEntry32);
      ThreadDetails.dwSize := SizeOf(TThreadEntry32); //If you do not initialize dwSize, Thread32First fails.
      if Thread32First(hSnapshot, ThreadDetails) then
      begin
        i := 1;
        repeat
          if ThreadDetails.th32OwnerProcessID = hProcessId then
          begin
            if Assigned(GetThreadDescription) and Assigned(SetThreadDescription) then //Windows 10, version 1607 or later; Windows Server 2016; Windows 10 LTSB 2016
            begin
              hThread := OpenThread(THREAD_QUERY_INFORMATION or THREAD_SET_LIMITED_INFORMATION, False, ThreadDetails.th32ThreadID);
              if hSnapshot <> INVALID_HANDLE_VALUE then
              begin
                ResultCode := GetThreadDescription(hThread, pDescription);
                if Succeeded(ResultCode) and Assigned(pDescription) then
                begin
                  try
                    if Length(pDescription) = 0 then
                    begin
                      if ThreadDetails.th32ThreadID = MainThreadId then
                      begin
                        ThreadName := 'DelphiCreated_MainThread';
                        SetThreadDescription(hThread, PWideChar(ThreadName));
                        TThread.NameThreadForDebugging(ThreadName, MainThreadId);
                      end
                      else
                      begin
                        ThreadName := 'DelphiCreated_Worker';
                        SetThreadDescription(hThread, PWideChar(ThreadName));
                        TThread.NameThreadForDebugging(ThreadName, ThreadDetails.th32ThreadID);
                      end;
                    end;
                  finally
                    LocalFree(HLOCAL(pDescription));
                  end;
                end;
              end;
            end
            else
            begin
              if ThreadDetails.th32ThreadID = MainThreadId then
              begin
                TThread.NameThreadForDebugging('DelphiCreated_Main', MainThreadId);
              end
              else
              begin
                TThread.NameThreadForDebugging('DelphiCreated_' + IntToStr(i), ThreadDetails.th32ThreadID);
                Inc(i);
              end;
            end;
          end;
        until not Thread32Next(hSnapshot, ThreadDetails);
      end;
    finally
      CloseHandle(hSnapshot);
    end;
  end;
end;

{$IFDEF DEBUG}
initialization
TThread.ForceQueue(nil,
    procedure
    begin
      NameDelphiThreads;
    end, 100);
{$ENDIF}

end.
