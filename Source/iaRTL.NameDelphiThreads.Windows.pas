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

  procedure NameDelphiThreads(const MainThreadId:THandle);

implementation
uses
  System.SysUtils,
  System.Classes,
  WinAPI.TlHelp32;


procedure NameDelphiThreads(const MainThreadId:THandle);
var
  hSnapshot:THandle;
  hProcessId:THandle;
  ThreadDetails:TThreadEntry32;
  i:Integer;
begin
  hProcessId := GetCurrentProcessId;

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
        until not Thread32Next(hSnapshot, ThreadDetails);
      end;
    finally
      CloseHandle(hSnapshot);
    end;
  end;
end;

{$IFDEF DEBUG}
initialization
  NameDelphiThreads(GetCurrentThreadId);
{$ENDIF}

end.
