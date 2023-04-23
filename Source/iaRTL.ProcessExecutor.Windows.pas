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
1.4 2023-Apr-20 Darian Miller: Removed API - no current plans of supporting other Operating Systems, but do have plans on more features for MS Windows
1.3 2023-Apr-20 Darian Miller: WaitForInputIdleMaxMS no longer used unless waiting for process completion as there's no need to slow down the StartProcess completion
1.2 2023-Apr-19 Darian Miller: Added ShowWindowState+ProcessCreationFlags
1.1 2019-Dec-26 Darian Miller: ASL-2.0 applied, complete refactor
1.0 2019-Dec-26 Darian Miller: Unit created using Delphi Dabbler's Public Domain code.
}
unit iaRTL.ProcessExecutor.Windows;

interface
uses
  WinAPI.Windows;

type

  TiaWindowsLaunchContext = record
    CommandLine:String;
    StartupInfo:TStartupInfo;
    ProcessInfo:TProcessInformation;
    ExitCode:DWord;
    ErrorCode:DWord;
    ErrorMessage:String;
  end;


  TiaWindowsProcessExecutor = class
  private const
    defWaitForInputIdleMaxMS = 750;
  private
    fContext:TiaWindowsLaunchContext;
    fWaitForInputIdleMaxMS:Integer;
    fShowWindowState:Word;
    fProcessCreationFlags:DWord;
  protected
    function DoCreateProcess(const pWorkingFolder:string):Boolean;
    procedure WaitForProcessStabilization;
    function WaitForProcessCompletion:Boolean;
    function GetExitCode:Boolean;
    procedure CleanUpProcess;
    procedure CaptureSystemError;
  public
    constructor Create;

    /// <summary>
    /// Executes the given command line and waits for the program started by the
    /// command line to exit. Returns true if the programf returns a zero exit code and
    /// false if the program doesn't start or returns a non-zero error code.
    /// </summary>
    /// <remarks>Implements IAProcessExecutor</remarks>
    function LaunchProcess(const pCommandLine:string):Boolean; overload;

    /// <summary>
    /// Executes the given command line and optionally waits for the program started by the
    /// command line to exit. If not waiting for the process to complete this returns True if
    /// the process was started, false otherwise.
    /// </summary>
    function LaunchProcess(const pCommandLine:string; const pWaitForCompletion:Boolean; const pWorkingFolder:string=''):Boolean; overload;

    /// <summary>
    /// Context of the child application process for inspection/logging purposes
    /// </summary>
    property Context:TiaWindowsLaunchContext read fContext;

    /// <summary>
    /// Delay passed to WaitForInputIdle after launching a new process, granting the process time to startup and become idle
    /// </summary>
    /// <remarks>
    /// Value not used unless waiting for process completion.
    /// Current default is 750ms
    /// </remarks>
    property WaitForInputIdleMaxMS:Integer read fWaitForInputIdleMaxMS write fWaitForInputIdleMaxMS;

    /// <summary>
    /// The initial window state can be customized to one of the SW_xxx values used by ShowWindow calls.
    /// For list of valid values, see: https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-showwindow
    /// </summary>
    property ShowWindowState:Word read fShowWindowState write fShowWindowState;

    /// <summary>
    /// This is the dwCreationFlags parameter to CreateProcess which control the priority class and the creation of the process
    /// For list of valid values, see: https://learn.microsoft.com/en-us/windows/win32/procthread/process-creation-flags
    /// </summary>
    property ProcessCreationFlags:DWord read fProcessCreationFlags write fProcessCreationFlags;
  end;


  /// <summary>
  /// Executes the given command line and waits for the program started by the
  /// command line to exit. Returns true if the program returns a zero exit code and
  /// false if the program doesn't start or returns a non-zero error code.
  /// </summary>
  function ExecAndWait(const pCommandLine:string; const pWorkingFolder:string=''):Boolean;


  /// <summary>
  /// Executes the given command line and does not wait for it to finish runing before returning
  /// </summary>
  function StartProcess(const pCommandLine:string; const pWorkingFolder:string=''):Boolean;


implementation
uses
  System.SysUtils;


constructor TiaWindowsProcessExecutor.Create;
begin
  inherited;
  fWaitForInputIdleMaxMS := defWaitForInputIdleMaxMS;
  fShowWindowState := SW_SHOWDEFAULT;
  fProcessCreationFlags := 0;  //Default: The process inherits both the error mode of the caller and the parent's console.  The environment block for the new process is assumed to contain ANSI characters (see lpEnvironment parameter for additional information).
end;


function TiaWindowsProcessExecutor.LaunchProcess(const pCommandLine:string):Boolean;
const
  WaitForCompletion = True;
begin
  Result := LaunchProcess(pCommandLine, WaitForCompletion);
end;


function TiaWindowsProcessExecutor.LaunchProcess(const pCommandLine:string; const pWaitForCompletion:Boolean; const pWorkingFolder:string=''):Boolean;
begin
  Result := False;

  fContext := Default(TiaWindowsLaunchContext);
  fContext.CommandLine := pCommandLine;
  fContext.StartupInfo.cb := SizeOf(fContext.StartupInfo);

  if ShowWindowState <> SW_SHOWDEFAULT then
  begin
    fContext.StartupInfo.dwFlags := fContext.StartupInfo.dwFlags or STARTF_USESHOWWINDOW;
    fContext.StartupInfo.wShowWindow := ShowWindowState;  //SW_HIDE, SW_SHOWNORMAL...
  end;

  if DoCreateProcess(pWorkingFolder) then
  begin
    try
      if pWaitForCompletion then
      begin
        WaitForProcessStabilization;

        if WaitForProcessCompletion and GetExitCode then
        begin
          Result := (fContext.ExitCode = 0);
        end;
      end
      else
      begin
        Result := True;
      end;
    finally
      CleanUpProcess;
    end;
  end;
end;


function TiaWindowsProcessExecutor.DoCreateProcess(const pWorkingFolder:string):Boolean;
var
  CurrentDirectory:PChar;
  CmdLine:string;
begin
  if pWorkingFolder = '' then
  begin
    CurrentDirectory := nil;
  end
  else
  begin
    CurrentDirectory := PChar(pWorkingFolder);
  end;

  // see: http://edn.embarcadero.com/article/38693
  // The Unicode version of this function, CreateProcessW, can modify the contents of this string.
  // Therefore, this parameter cannot be a pointer to read-only memory (such as a const variable or a literal string).
  // If this parameter is a constant string, the function may cause an access violation
  // also: https://stackoverflow.com/questions/6705532/access-violation-in-function-createprocess-in-delphi-2009
  // which references using UniqueString
  CmdLine := fContext.CommandLine;
  UniqueString(CmdLine);   //https://stackoverflow.com/a/6707533

  //API: https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createprocessw
  Result := CreateProcess(nil, PChar(CmdLine), nil, nil, False, ProcessCreationFlags, nil, CurrentDirectory, fContext.StartupInfo, fContext.ProcessInfo);

  if not Result then
  begin
    CaptureSystemError;
  end;
end;

procedure TiaWindowsProcessExecutor.WaitForProcessStabilization;
begin
  //If immediately inspecting a newly launched child process, should give it time to stabilize
  //ex: https://www.tek-tips.com/viewthread.cfm?qid=1443661
  if WaitForInputIdleMaxMS > 0 then
  begin

    {MS: WaitForInputIdle can be useful for synchronizing a parent process and a newly created child process.
    When a parent process creates a child process, the CreateProcess function returns without waiting
    for the child process to finish its initialization. Before trying to communicate with the child
    process, the parent process can use the WaitForInputIdle function to determine when the child's
    initialization has been completed. For example, the parent process should use the WaitForInputIdle
    function before trying to find a window associated with the child process.

    Note: can be used at any time, not just during application startup. However, WaitForInputIdle waits
    only once for a process to become idle; subsequent calls return immediately, whether the process is idle or busy.

    Note: If this process is a console application or does not have a message queue, WaitForInputIdle returns immediately.
    }
    //API: https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-waitforinputidle?redirectedfrom=MSDN
    WaitForInputIdle(fContext.ProcessInfo.hProcess, WaitForInputIdleMaxMS);
  end;
end;


function TiaWindowsProcessExecutor.WaitForProcessCompletion:Boolean;
var
  vRetVal:DWORD;
  vError:String;
begin
  //API: https://docs.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-waitforsingleobject
  vRetVal := WaitForSingleObject(fContext.ProcessInfo.hProcess, INFINITE);

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
        //shouldn't get here
        vError := Format('Unhandled return from WaitForSingleObject %d', [vRetVal]);
        Assert(false, vError);
        raise Exception.Create(vError);
      end;
  end;
end;


function TiaWindowsProcessExecutor.GetExitCode:Boolean;
begin
  //API: https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-getexitcodeprocess
  Result := GetExitCodeProcess(fContext.ProcessInfo.hProcess, fContext.ExitCode);

  if not Result then
  begin
    CaptureSystemError;
  end;
end;


procedure TiaWindowsProcessExecutor.CleanUpProcess;
begin
  CloseHandle(fContext.ProcessInfo.hProcess);
  CloseHandle(fContext.ProcessInfo.hThread);
end;


procedure TiaWindowsProcessExecutor.CaptureSystemError;
begin
  //API: https://docs.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-getlasterror
  fContext.ErrorCode := GetLastError;
  fContext.ErrorMessage := SysErrorMessage(fContext.ErrorCode);
end;


function ExecAndWait(const pCommandLine:string; const pWorkingFolder:string=''):Boolean;
const
  WaitForCompletion = True;
var
  vProcessLauncher:TiaWindowsProcessExecutor;
begin
  vProcessLauncher := TiaWindowsProcessExecutor.Create;
  try
    Result := vProcessLauncher.LaunchProcess(pCommandLine, WaitForCompletion, pWorkingFolder);
  finally
    vProcessLauncher.Free;
  end;
end;


function StartProcess(const pCommandLine:string; const pWorkingFolder:string=''):Boolean;
const
  WaitForCompletion = False;
var
  vProcessLauncher:TiaWindowsProcessExecutor;
begin
  vProcessLauncher := TiaWindowsProcessExecutor.Create;
  try
    Result := vProcessLauncher.LaunchProcess(pCommandLine, WaitForCompletion, pWorkingFolder);
  finally
    vProcessLauncher.Free;
  end;
end;


//reminder
//WaitForInputIdle shouldn't use INFINITE
//https://stackoverflow.com/questions/46221282/c-builder-10-2-thread-blocks-waitforinputidle
//may block for 25 days :)
//https://stackoverflow.com/questions/10711070/can-process-waitforinputidle-return-false

end.
