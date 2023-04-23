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
1.5 2023-Apr-23 Darian Miller: Add optional output capture for console applications
1.4 2023-Apr-20 Darian Miller: Removed API - no current plans of supporting other Operating Systems, but do have plans on more features for MS Windows
1.3 2023-Apr-20 Darian Miller: WaitForInputIdleMaxMS no longer used unless waiting for process completion as there's no need to slow down the StartProcess completion
1.2 2023-Apr-19 Darian Miller: Added ShowWindowState+ProcessCreationFlags
1.1 2019-Dec-26 Darian Miller: ASL-2.0 applied, complete refactor
1.0 2019-Dec-26 Darian Miller: Unit created using Delphi Dabbler's Public Domain code.
}
unit iaRTL.ProcessExecutor.Windows;

interface

uses
  System.Classes,
  System.SysUtils,
  WinAPI.Windows;

type
  TReadPipeResult = (APIFailure, Success, BrokenPipe);

  TiaPipeHandles = record
    OurRead:THandle;
    ChildWrite:THandle;
  end;


  TiaCapture = record
    StdOutput:TiaPipeHandles;
    StdError:TiaPipeHandles;
  end;


  TiaLaunchContext = record
    CommandLine:string;
    StartupInfo:TStartupInfo;
    ProcessInfo:TProcessInformation;
    ExitCode:DWord;
    ErrorCode:DWord;
    ErrorMessage:string;
    IPC:TiaCapture;
    OutputCaptured:Boolean;

    procedure Finalize;
  end;


  TOnCaptureProc = reference to procedure(const Value:string);


  TiaWindowsProcessExecutor = class
  private const
    defWaitForCompletion = False;
    defWaitForInputIdleMaxMS = 750;
    defInheritHandles = False;
    defInheritParentEnvironmentVariables = True;
  private
    fContext:TiaLaunchContext;
    fEnvironmentVariables:TStringList;
    fInheritHandles:Boolean;
    fInheritParentEnvironmentVariables:Boolean;
    fProcessCreationFlags:DWord;
    fShowWindowState:Word;
    fWaitForInputIdleMaxMS:Integer;
    fOnStandardOutputCapture:TOnCaptureProc;
    fOnStandardErrorCapture:TOnCaptureProc;
    fCaptureEncoding:TEncoding;
  protected
    procedure CaptureSystemError(const aExtendedDescription:string);
    function CreateEnvironmentVariables(var aCustomList:TStringList):PChar;
    function DoCreateProcess(const aWorkingFolder:string; const aEnvironmentVarPtr:PChar):Boolean;
    function GetExitCode:Boolean;
    function TryReadFromPipes:TReadPipeResult;
    function SetupRedirectedIO(const CurrentProcess:THandle):Boolean;
    function WaitForProcessCompletion:Boolean;
    procedure WaitForProcessStabilization;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    /// Executes the given command line and optionally waits for the program started by the
    /// command line to exit. If not waiting for the process to complete this returns True if
    /// the process was started, false otherwise.
    /// </summary>
    /// <remarks>
    /// WaitForCompletion is ignored if waiting on output capture
    /// </remarks>
    function LaunchProcess(const aCommandLine:string; const aWaitForCompletionFlag:Boolean = defWaitForCompletion; const aWorkingFolder:string = ''):Boolean; overload;

    /// <summary>
    /// Context of the child application process for inspection/logging purposes
    /// </summary>
    property Context:TiaLaunchContext read fContext;

    /// <summary>
    /// The initial window state can be customized to one of the SW_xxx values used by ShowWindow calls.
    /// For list of valid values, see: https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-showwindow
    /// </summary>
    /// <remarks>
    /// You may want to set to SW_HIDE when waiting for console apps to complete to prevent the console window from appearing
    /// </remarks>
    property ShowWindowState:Word read fShowWindowState write fShowWindowState;

    /// <summary>
    /// Optionally used to set environment variables available to the launched process (in the style of Name=Value, non-duplicate/sorted list)
    /// </summary>
    property EnvironmentVariables:TStringList read fEnvironmentVariables write fEnvironmentVariables;

    /// <summary>
    /// Can customize the use of parent environment variables
    /// </summary>
    /// <remarks>
    /// Current default is True
    /// </remarks>
    property InheritParentEnvironmentVariables:Boolean read fInheritParentEnvironmentVariables write fInheritParentEnvironmentVariables;

    /// <summary>
    /// Can optionally capture the hStdOutput content of a child process
    /// </summary>
    property OnStandardOutputCapture:TOnCaptureProc read fOnStandardOutputCapture write fOnStandardOutputCapture;

    /// <summary>
    /// Can optionally capture the hStdError content of a child process
    /// </summary>
    property OnStandardErrorCapture:TOnCaptureProc read fOnStandardErrorCapture write fOnStandardErrorCapture;

    /// <summary>
    /// If capturing output of a child process, can optionally customize the TEncoding.ANSI default
    /// </summary>
    property CaptureEncoding:TEncoding read fCaptureEncoding write fCaptureEncoding;

    /// <summary>
    /// This is the dwCreationFlags parameter to CreateProcess which control the priority class and the creation of the process
    /// For list of valid values, see: https://learn.microsoft.com/en-us/windows/win32/procthread/process-creation-flags
    /// </summary>
    /// <remarks>
    /// The CREATE_UNICODE_ENVIRONMENT flag is automatically added if custom environment variables are used
    /// The CREATE_NEW_CONSOLE flag is automatically added if capturing output
    /// </remarks>
    property ProcessCreationFlags:DWord read fProcessCreationFlags write fProcessCreationFlags;

    /// <summary>
    /// Delay passed to WaitForInputIdle after launching a new process, granting the process time to startup and become idle
    /// </summary>
    /// <remarks>
    /// Value not used unless waiting for process completion.
    /// Current default is 750ms
    /// </remarks>
    property WaitForInputIdleMaxMS:Integer read fWaitForInputIdleMaxMS write fWaitForInputIdleMaxMS;

    /// <summary>
    /// By default, passing TRUE as the value of the bInheritHandles parameter causes all inheritable handles to be inherited by the new process.
    /// If the parameter is FALSE, the handles are not inherited. Note that inherited handles have the same value and access rights as the original handles.
    /// This can be problematic for applications which create processes from multiple threads simultaneously yet desire each process to inherit different handles.
    /// Applications can use the UpdateProcThreadAttributeList function with the PROC_THREAD_ATTRIBUTE_HANDLE_LIST parameter to provide a list of handles to be inherited by a particular process.
    /// </summary>
    /// <remarks>
    /// Current default is False
    /// The bInheritHandles parameter is automatically set to true if capturing output of a Console process
    /// </remarks>
    property InheritHandles:Boolean read fInheritHandles write fInheritHandles;
  end;


  /// <summary>
  /// Executes the given command line and waits for the program started by the
  /// command line to exit. Returns true if the program returns a zero exit code and
  /// false if the program doesn't start or returns a non-zero error code.
  /// </summary>
function ExecAndWait(const aCommandLine:string; const aWorkingFolder:string = ''):Boolean;

/// <summary>
/// Executes the given command line and waits for it to complete while redirecting the output to the provided events (and the console window is hidden)
/// By default, the captured text is assumed to be ANSI. If your launched applications outputs Unicode to StdOut then pass in TEncoding.Unicode;
/// By default, your CommandLine will be prefixed with 'CMD /C ' which is required for commands like "dir *.txt" (The COMSPEC environment variable used to determine CMD)
/// </summary>
function ExecAndCaptureOutuput(const aCommandLine:string; const aOnStandardOutput:TOnCaptureProc; const aOnStandardError:TOnCaptureProc; const aCaptureEncoding:TEncoding = nil; const aAddCommandPrefix:Boolean = True; const aWorkingFolder:string = ''):Boolean;

/// <summary>
/// Executes the given command line and does not wait for it to finish runing before returning
/// </summary>
function StartProcess(const aCommandLine:string; const aWorkingFolder:string = ''):Boolean;


implementation

uses
  iaRTL.EnvironmentVariables.Windows,
  iaWin.Utils;


function ExecAndWait(const aCommandLine:string; const aWorkingFolder:string = ''):Boolean;
var
  ProcessExecutor:TiaWindowsProcessExecutor;
begin
  ProcessExecutor := TiaWindowsProcessExecutor.Create;
  try
    Result := ProcessExecutor.LaunchProcess(aCommandLine, { WaitForCompletion= } True, aWorkingFolder);
  finally
    ProcessExecutor.Free;
  end;
end;


function StartProcess(const aCommandLine:string; const aWorkingFolder:string = ''):Boolean;
var
  ProcessExecutor:TiaWindowsProcessExecutor;
begin
  ProcessExecutor := TiaWindowsProcessExecutor.Create;
  try
    Result := ProcessExecutor.LaunchProcess(aCommandLine, { WaitForCompletion = } False, aWorkingFolder);
  finally
    ProcessExecutor.Free;
  end;
end;


function ExecAndCaptureOutuput(const aCommandLine:string; const aOnStandardOutput:TOnCaptureProc; const aOnStandardError:TOnCaptureProc; const aCaptureEncoding:TEncoding=nil; const aAddCommandPrefix:Boolean=True; const aWorkingFolder:string = ''):Boolean;
var
  ProcessExecutor:TiaWindowsProcessExecutor;
  CmdLine:String;
begin
  ProcessExecutor := TiaWindowsProcessExecutor.Create;
  try
    ProcessExecutor.ShowWindowState := SW_HIDE;
    ProcessExecutor.OnStandardOutputCapture := aOnStandardOutput;
    ProcessExecutor.OnStandardErrorCapture := aOnStandardError;
    if Assigned(aCaptureEncoding) then
    begin
      ProcessExecutor.CaptureEncoding := aCaptureEncoding;
    end;
    if aAddCommandPrefix then
    begin
      CmdLine := GetEnvironmentVariable('COMSPEC') + ' /C ' + aCommandLine;
    end
    else
    begin
      CmdLine := aCommandLine;
    end;

    Result := ProcessExecutor.LaunchProcess(CmdLine, { WaitForCompletion= } True, aWorkingFolder);
  finally
    ProcessExecutor.Free;
  end;
end;


constructor TiaWindowsProcessExecutor.Create;
begin
  inherited;
  fEnvironmentVariables := TStringList.Create;
  fEnvironmentVariables.Sorted := True;
  fEnvironmentVariables.Duplicates := TDuplicates.dupIgnore;
  fInheritParentEnvironmentVariables := defInheritParentEnvironmentVariables;
  fInheritHandles := defInheritHandles;
  // Process creation flags default of 0: The process inherits both the error mode of the caller and the parent's console
  // And the environment block for the new process is assumed to contain ANSI characters
  fProcessCreationFlags := 0;
  fShowWindowState := SW_SHOWDEFAULT;
  fWaitForInputIdleMaxMS := defWaitForInputIdleMaxMS;
  fCaptureEncoding := TEncoding.ANSI;
end;


destructor TiaWindowsProcessExecutor.Destroy;
begin
  fEnvironmentVariables.Free;
  inherited;
end;


function TiaWindowsProcessExecutor.LaunchProcess(const aCommandLine:string; const aWaitForCompletionFlag:Boolean = defWaitForCompletion; const aWorkingFolder:string = ''):Boolean;
var
  EnvironmentListForChildProcess:TStringList;
  EnvironmentVars:PChar;
begin
  Result := False;

  fContext := Default(TiaLaunchContext);
  fContext.StartupInfo.cb := SizeOf(fContext.StartupInfo);
  fContext.CommandLine := aCommandLine;
  if ShowWindowState <> SW_SHOWDEFAULT then
  begin
    fContext.StartupInfo.dwFlags := fContext.StartupInfo.dwFlags or STARTF_USESHOWWINDOW;
    fContext.StartupInfo.wShowWindow := ShowWindowState; // SW_HIDE, SW_SHOWNORMAL...
  end;

  EnvironmentVars := CreateEnvironmentVariables(EnvironmentListForChildProcess);
  try

    if Assigned(OnStandardOutputCapture) or Assigned(OnStandardErrorCapture) then
    begin
      if not SetupRedirectedIO(GetCurrentProcess) then Exit(False);
      fContext.OutputCaptured := True;
    end;

    if DoCreateProcess(aWorkingFolder, EnvironmentVars) then
    begin
      try

        if fContext.OutputCaptured then
        begin
          // These are no longer used in this parent process
          // "You need to make sure that no handles to the write end of the
          // output pipe are maintained in this process or else the pipe will
          // not close when the child process exits and the ReadFile will hang."
          TiaWinUtils.CloseHandle(fContext.IPC.StdOutput.ChildWrite);
          TiaWinUtils.CloseHandle(fContext.IPC.StdError.ChildWrite);
        end;

        if aWaitForCompletionFlag or fContext.OutputCaptured then
        begin
          WaitForProcessStabilization;

          if WaitForProcessCompletion and GetExitCode then
          begin
            if fContext.ExitCode = 0 then
            begin
              Result := True;
            end
            else
            begin
              fContext.ErrorCode := fContext.ExitCode;
              fContext.ErrorMessage := 'Child process completed with ExitCode ' + fContext.ExitCode.ToString;
            end;
          end;
        end
        else
        begin
          Result := True;
        end;

      finally
        fContext.Finalize;
      end;
    end;
  finally
    EnvironmentListForChildProcess.Free;
  end;
end;


// Note: When adding custom environment variables, the parent's variables are not inherited by CreateProcess which may, or may not, be desired. Use InheritParentEnvironmentVariables to decide.
function TiaWindowsProcessExecutor.CreateEnvironmentVariables(var aCustomList:TStringList):PChar;
begin
  aCustomList := nil;

  if EnvironmentVariables.Count > 0 then
  begin
    ProcessCreationFlags := ProcessCreationFlags or CREATE_UNICODE_ENVIRONMENT; // by default, environment assumes ANSI, since we're using Unicode strings (assuming D2009+), need to tell Windows to expect Unicdoe characters

    if InheritParentEnvironmentVariables then
    begin
      aCustomList := TStringList.Create;
      aCustomList.Sorted := True; // list must be sorted
      aCustomList.Duplicates := TDuplicates.dupIgnore; // and the list should only contain unique names

      aCustomList.Assign(EnvironmentVariables); // our custom list takes priority
      GetEnvironmentVariables(aCustomList); // then add any other unique variables from parent (duplicates ignored)
      Result := CreateEnvironmentBlock(aCustomList);
    end
    else
    begin
      Result := CreateEnvironmentBlock(EnvironmentVariables); // will only use our custom list, no parent variables inherited
    end;
  end
  else
  begin
    if InheritParentEnvironmentVariables then
    begin
      Result := nil; // if a custom list is not provided, then CreateProcess automatically inherits environment from parent
    end
    else
    begin
      // A special case - we aren't specifying a list of custom environment variables, but we don't want the parent's environment either
      ProcessCreationFlags := ProcessCreationFlags or CREATE_UNICODE_ENVIRONMENT;
      aCustomList := TStringList.Create; // empty list
      Result := CreateEnvironmentBlock(aCustomList);
    end;
  end;
end;


// https://learn.microsoft.com/en-us/windows/win32/api/namedpipeapi/nf-namedpipeapi-createpipe
// https://learn.microsoft.com/en-us/windows/win32/api/handleapi/nf-handleapi-sethandleinformation
function TiaWindowsProcessExecutor.SetupRedirectedIO(const CurrentProcess:THandle):Boolean;

  function SetupPipe(var PipeHandles:TiaPipeHandles; sa:TSecurityAttributes; const Description:string):Boolean;
  begin
    // Create a pair of handles - one for reading from the pipe and another for writing to the pipe.
    // Final param is the size of the buffer for the pipe, in bytes.
    // The size is only a suggestion; the system uses the value to calculate an appropriate buffering mechanism.
    // If this parameter is zero, the system uses the default buffer size.
    if CreatePipe(PipeHandles.OurRead, PipeHandles.ChildWrite, @sa, 0) then
    begin
      if SetHandleInformation(PipeHandles.OurRead, HANDLE_FLAG_INHERIT, 0) then // Other examples call DuplicateHandle on a temp handle used in CreatePipe, with Inherited property set to False
      begin
        Result := True;
      end
      else
      begin
        CaptureSystemError(Description + ' SetHandleInformation on read handle failed');
        Result := False;
      end;
    end
    else
    begin
      CaptureSystemError(Description + ' CreatePipe failed');
      Result := False;
    end;
  end;


var
  PipeSA:TSecurityAttributes;
begin
  Result := True;

  PipeSA := Default(TSecurityAttributes);
  PipeSA.nLength := SizeOf(TSecurityAttributes);
  PipeSA.lpSecurityDescriptor := nil;
  PipeSA.bInheritHandle := True;


  if Assigned(OnStandardOutputCapture) then
  begin
    if not SetupPipe(fContext.IPC.StdOutput, PipeSA, 'hStdOutput') then Exit(False);
    fContext.StartupInfo.hStdOutput := fContext.IPC.StdOutput.ChildWrite;
  end
  else
  begin
    fContext.StartupInfo.hStdOutput := GetStdHandle(STD_OUTPUT_HANDLE);
  end;


  if Assigned(fOnStandardErrorCapture) then
  begin
    if not SetupPipe(fContext.IPC.StdError, PipeSA, 'hStdError') then Exit(False);
    fContext.StartupInfo.hStdError := fContext.IPC.StdError.ChildWrite;
  end
  else
  begin
    fContext.StartupInfo.hStdError := GetStdHandle(STD_ERROR_HANDLE);
  end;


  fContext.StartupInfo.dwFlags := fContext.StartupInfo.dwFlags or STARTF_USESTDHANDLES; // ***  When capturing, STARTF_USESTDHANDLES must be set AND the bInheritHandles parameter to CreateProcess must be set True
  fContext.StartupInfo.hStdInput := GetStdHandle(STD_INPUT_HANDLE);

  // If this flag is not specified when a console process is created, both processes are attached to the same console,
  // and there is no guarantee that the correct process will receive the input intended for it
  ProcessCreationFlags := ProcessCreationFlags or CREATE_NEW_CONSOLE;
end;


// https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createprocessw
function TiaWindowsProcessExecutor.DoCreateProcess(const aWorkingFolder:string; const aEnvironmentVarPtr:PChar):Boolean;
var
  CurrentDirectoryPtr:PChar;
  ShouldInheritHandles:Boolean;
  CmdLine:string;
begin
  if aWorkingFolder = '' then
  begin
    CurrentDirectoryPtr := nil;
  end
  else
  begin
    CurrentDirectoryPtr := PChar(aWorkingFolder);
  end;

  ShouldInheritHandles := InheritHandles or fContext.OutputCaptured; // *** When capturing, STARTF_USESTDHANDLES must be set AND the bInheritHandles parameter to CreateProcess must be set True

  // see: http://edn.embarcadero.com/article/38693
  // The Unicode version of this function, CreateProcessW, can modify the contents of this string.
  // Therefore, this parameter cannot be a pointer to read-only memory (such as a const variable or a literal string).
  // If this parameter is a constant string, the function may cause an access violation
  // also: https://stackoverflow.com/questions/6705532/access-violation-in-function-createprocess-in-delphi-2009
  CmdLine := fContext.CommandLine;
  UniqueString(CmdLine);

  Result := CreateProcess(nil, PChar(CmdLine), nil, nil, ShouldInheritHandles, ProcessCreationFlags, aEnvironmentVarPtr, CurrentDirectoryPtr, fContext.StartupInfo, fContext.ProcessInfo);

  if not Result then
  begin
    CaptureSystemError('CreateProcess failed');
  end;
end;


// https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-waitforinputidle?redirectedfrom=MSDN
// ex: https://www.tek-tips.com/viewthread.cfm?qid=1443661
procedure TiaWindowsProcessExecutor.WaitForProcessStabilization;
begin
  // If immediately inspecting a newly launched child process, should give it time to stabilize
  if WaitForInputIdleMaxMS > 0 then
  begin

    { MS: WaitForInputIdle can be useful for synchronizing a parent process and a newly created child process.
      When a parent process creates a child process, the CreateProcess function returns without waiting
      for the child process to finish its initialization. Before trying to communicate with the child
      process, the parent process can use the WaitForInputIdle function to determine when the child's
      initialization has been completed. For example, the parent process should use the WaitForInputIdle
      function before trying to find a window associated with the child process.

      Note: can be used at any time, not just during application startup. However, WaitForInputIdle waits
      only once for a process to become idle; subsequent calls return immediately, whether the process is idle or busy.

      Note: If this process is a console application or does not have a message queue, WaitForInputIdle returns immediately.
    }
    WaitForInputIdle(fContext.ProcessInfo.hProcess, WaitForInputIdleMaxMS);
  end;
end;


// NOTE: neither method handles windows messages - if called by main thread, it will be blocked while waiting
// https://learn.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-waitforsingleobject
function TiaWindowsProcessExecutor.WaitForProcessCompletion:Boolean;
var
  WaitResult:DWord;
  PipeResult:TReadPipeResult;
  BrokenPipe:Boolean;
begin

  if fContext.OutputCaptured then // Poll pipes while waiting for process to exit
  begin
    BrokenPipe := False;

    repeat
      WaitResult := WaitForSingleObject(fContext.ProcessInfo.hProcess, 200);
      if (WaitResult = WAIT_TIMEOUT) and (not BrokenPipe) then
      begin
        PipeResult := TryReadFromPipes;
        if PipeResult = TReadPipeResult.APIFailure then
        begin
          Exit(False);
        end
        else if PipeResult = TReadPipeResult.BrokenPipe then
        begin
          BrokenPipe := True;
          WaitResult := WAIT_OBJECT_0;  //usually caught by WaitForSingleObject, but pipe is down so process is finished
        end;
      end;
    until WaitResult <> WAIT_TIMEOUT;

    if WaitResult = WAIT_OBJECT_0 then
    begin
      if not BrokenPipe then // try to read any remaining data left in the buffer
      begin
        Result := TryReadFromPipes <> TReadPipeResult.APIFailure;
      end
      else // process complete + no data left in buffer to read
      begin
        Result := True;
      end;
    end
    else
    begin
      Result := False;
      CaptureSystemError('Polling WaitForProcessCompletion failed');
    end;

  end
  else // Simply wait for process to exit
  begin

    if WaitForSingleObject(fContext.ProcessInfo.hProcess, INFINITE) = WAIT_OBJECT_0 then
    begin
      Result := True;
    end
    else
    begin
      Result := False;
      CaptureSystemError('WaitForProcessCompletion failed');
    end;

  end;
end;


// https://learn.microsoft.com/en-us/windows/win32/api/namedpipeapi/nf-namedpipeapi-peeknamedpipe
// https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-readfile
function TiaWindowsProcessExecutor.TryReadFromPipes:TReadPipeResult;

  function PeekRead(const hOurRead:THandle; const EventToCall:TOnCaptureProc):TReadPipeResult;
  var
    BytesAvailable:DWord;
    BytesRead:DWord;
    PipeData:TBytes;
  begin
    Result := TReadPipeResult.BrokenPipe;

    if PeekNamedPipe(hOurRead, nil, 0, nil, @BytesAvailable, nil) then
    begin
      if BytesAvailable = 0 then Exit(TReadPipeResult.Success);

      SetLength(PipeData, BytesAvailable);
      if ReadFile(hOurRead, PipeData[0], BytesAvailable, BytesRead, nil) then
      begin
        Result := TReadPipeResult.Success;

        if BytesRead < BytesAvailable then
        begin
          SetLength(PipeData, BytesRead);
        end;

        if Assigned(EventToCall) then
        begin
          EventToCall(CaptureEncoding.GetString(PipeData));
        end;
      end
      else
      begin
        Result := TReadPipeResult.APIFailure;
        CaptureSystemError('ReadFile after PeekNamedPipe failed');
      end;
    end
    else if GetLastError <> ERROR_BROKEN_PIPE then
    begin
      Result := TReadPipeResult.APIFailure;
      CaptureSystemError('PeekNamedPipe failed');
    end;
  end;

begin
  Result := TReadPipeResult.Success;

  if Assigned(OnStandardOutputCapture) then
  begin
    Result := PeekRead(fContext.IPC.StdOutput.OurRead, OnStandardOutputCapture);
  end;
  if (Result = TReadPipeResult.Success) and Assigned(OnStandardErrorCapture) then
  begin
    Result := PeekRead(fContext.IPC.StdError.OurRead, OnStandardErrorCapture);
  end;
end;


// https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-getexitcodeprocess
function TiaWindowsProcessExecutor.GetExitCode:Boolean;
begin
  Result := GetExitCodeProcess(fContext.ProcessInfo.hProcess, fContext.ExitCode);

  if not Result then
  begin
    CaptureSystemError('GetExitCode failed');
  end;
end;


// https://learn.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-getlasterror
procedure TiaWindowsProcessExecutor.CaptureSystemError(const aExtendedDescription:string);
begin
  fContext.ErrorCode := GetLastError;
  fContext.ErrorMessage := '[' + aExtendedDescription + '] ' + SysErrorMessage(fContext.ErrorCode);
end;


procedure TiaLaunchContext.Finalize;
begin
  TiaWinUtils.CloseHandle(ProcessInfo.hProcess);
  TiaWinUtils.CloseHandle(ProcessInfo.hThread);
  if OutputCaptured then
  begin
    TiaWinUtils.CloseHandle(IPC.StdOutput.OurRead);
    TiaWinUtils.CloseHandle(IPC.StdOutput.ChildWrite);
    TiaWinUtils.CloseHandle(IPC.StdError.OurRead);
    TiaWinUtils.CloseHandle(IPC.StdError.ChildWrite);
  end;
end;

// reminder
// WaitForInputIdle shouldn't use INFINITE
// https://stackoverflow.com/questions/46221282/c-builder-10-2-thread-blocks-waitforinputidle
// may block for 25 days :)
// https://stackoverflow.com/questions/10711070/can-process-waitforinputidle-return-false

end.
