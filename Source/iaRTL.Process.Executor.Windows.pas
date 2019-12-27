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
1.1 2019-Dec-26 Darian Miller: ASL-2.0 applied, refactored
1.0 2019-Dec-26 Darian Miller: Unit created using Delphi Dabbler's Public Domain code.
}
unit iaRTL.Process.Executor.Windows;

interface
uses
  WinAPI.Windows,
  iaRTL.Process.Executor.API;

type

  TiaWindowsLaunchContext = record
    CommandLine:String;
    ProcessInfo:TProcessInformation;
    StartupInfo:TStartupInfo;
    ExitCode:DWord;
    ErrorCode:DWord;
    ErrorMessage:String;
  end;

  TiaWindowsProcessExecutor = class(TInterfacedObject, IAProcessExecutor)
  protected
    fLaunchContext:TiaWindowsLaunchContext;
    function StartProcess:Boolean;
    function WaitForProcess:Boolean;
    function GetExitCode:Boolean;
    procedure CleanUpProcess;
    procedure CaptureSystemError;
  public
    /// <summary>
    /// Executes the given command line and waits for the program started by the
    /// command line to exit. Returns true if the program returns a zero exit code and
    /// false if the program doesn't start or returns a non-zero error code.
    /// </summary>
    /// <remarks>IAProcessExecutor</remarks>
    function LaunchProcess(const pCommandLine:string):Boolean;

    property LaunchContext:TiaWindowsLaunchContext read fLaunchContext;
  end;

  /// <summary>
  /// Executes the given command line and waits for the program started by the
  /// command line to exit. Returns true if the program returns a zero exit code and
  /// false if the program doesn't start or returns a non-zero error code.
  /// </summary>
  function ExecAndWait(const pCommandLine:string):Boolean;


implementation
uses
  System.SysUtils;


function TiaWindowsProcessExecutor.LaunchProcess(const pCommandLine:string):Boolean;
begin
  Result := False;

  fLaunchContext := Default(TiaWindowsLaunchContext);
  fLaunchContext.StartupInfo.cb := SizeOf(fLaunchContext.StartupInfo);

  // see: http://edn.embarcadero.com/article/38693
  // The Unicode version of this function, CreateProcessW, can modify the contents of this string.
  // Therefore, this parameter cannot be a pointer to read-only memory (such as a const variable or a literal string).
  // If this parameter is a constant string, the function may cause an access violation
  // also: https://stackoverflow.com/questions/6705532/access-violation-in-function-createprocess-in-delphi-2009
  fLaunchContext.CommandLine := pCommandLine;
  UniqueString(fLaunchContext.CommandLine);

  //todo: Event for customizing StartupInfo
  if StartProcess then
  begin
    try
      if WaitForProcess and GetExitCode then
      begin
        Result := (fLaunchContext.ExitCode = 0);
      end;
    finally
      CleanUpProcess;
    end;
  end;

end;

function TiaWindowsProcessExecutor.StartProcess:Boolean;
begin
  //API: https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createprocessw
  Result := CreateProcess(nil, PChar(fLaunchContext.CommandLine), nil, nil, False, 0, nil, nil, fLaunchContext.StartupInfo, fLaunchContext.ProcessInfo);

  if not Result then
  begin
    CaptureSystemError;
  end;
end;


function TiaWindowsProcessExecutor.WaitForProcess:Boolean;
var
  vRetVal:DWORD;
begin
  //API: https://docs.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-waitforsingleobject
  vRetVal := WaitForSingleObject(fLaunchContext.ProcessInfo.hProcess, INFINITE);

  case vRetVal of
    WAIT_OBJECT_0:
      begin
        Result := True;
      end;
    WAIT_FAILED:
      begin
        Result := False;
        CaptureSystemError;
      end;
    else
      begin
        raise Exception.Create('WaitForSingleObject unknown failure #' + IntToStr(vRetVal));
      end;
  end;
end;


function TiaWindowsProcessExecutor.GetExitCode:Boolean;
begin
  //API: https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-getexitcodeprocess
  Result := GetExitCodeProcess(fLaunchContext.ProcessInfo.hProcess, fLaunchContext.ExitCode);

  if not Result then
  begin
    CaptureSystemError;
  end;
end;


procedure TiaWindowsProcessExecutor.CleanUpProcess;
begin
  CloseHandle(fLaunchContext.ProcessInfo.hProcess);
  CloseHandle(fLaunchContext.ProcessInfo.hThread);
end;


procedure TiaWindowsProcessExecutor.CaptureSystemError;
begin
  fLaunchContext.ErrorCode := GetLastError;
  fLaunchContext.ErrorMessage := SysErrorMessage(fLaunchContext.ErrorCode);
end;


function ExecAndWait(const pCommandLine:string):Boolean;
var
  vProcessLauncher:TiaWindowsProcessExecutor;
begin
  vProcessLauncher := TiaWindowsProcessExecutor.Create;
  try
    Result := vProcessLauncher.LaunchProcess(pCommandLine);
  finally
    vProcessLauncher.Free;
  end;
end;


end.
