(*
Copyright 2019 Ideas Awakened Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

For more detail, see: https://github.com/ideasawakened/iaLib

1.1 2019-Dec-26 Darian Miller: ASL-2.0 applied, refactored
1.0 2019-Dec-26 Darian Miller: Unit created using Delphi Dabbler's Public Domain code.
*)
unit iaRTL.Process.Executor.Windows;

interface

  /// <summary>
  /// Executes the given command line and waits for the program started by the
  /// command line to exit. Returns true if the program returns a zero exit code and
  /// false if the program doesn't start or returns a non-zero error code.
  /// </summary>
  function ExecAndWait(const aCommandLine:string):Boolean;

implementation
uses
  WinAPI.Windows;

function ExecAndWait(const aCommandLine:string):Boolean;
var
  vStartupInfo:TStartupInfo;
  vProcessInfo:TProcessInformation;
  vProcessExitCode:DWord;
  vSafeCommandLine:string;
begin
  Result := False;

  // Modification to work round "feature" in CreateProcessW API function used by Unicode Delphis.
  vSafeCommandLine := aCommandLine;
  UniqueString(vSafeCommandLine);

  FillChar(vStartupInfo, SizeOf(vStartupInfo), 0);
  vStartupInfo.cb := SizeOf(vStartupInfo);

  //https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createprocessw
  if CreateProcess(nil, PChar(vSafeCommandLine), nil, nil, False, 0, nil, nil, vStartupInfo, vProcessInfo) then
  begin
    try
      // Now wait for application to complete
      if WaitForSingleObject(vProcessInfo.hProcess, INFINITE) = WAIT_OBJECT_0 then
      begin
        if GetExitCodeProcess(vProcessInfo.hProcess, vProcessExitCode) then
        begin
          Result := (vProcessExitCode = 0);
        end;
      end;
    finally
      CloseHandle(vProcessInfo.hProcess);
      CloseHandle(vProcessInfo.hThread);
    end;
  end;
  //todo: GetLastError
end;

end.
