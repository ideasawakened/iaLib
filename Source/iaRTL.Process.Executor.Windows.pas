(*
1.0 Unit created: 2019-Dec-26 Darian Miller from Delphi Dabbler's Public Domain code.
*)
unit iaRTL.Process.Executor.Windows;

interface

  function ExecAndWait(const CommandLine: string) : Boolean;

implementation

function ExecAndWait(const CommandLine: string) : Boolean;
  {Executes the given command line and waits for the program started by the
  command line to exit. Returns true if the program returns a zero exit code and
  false if the program doesn't start or returns a non-zero error code.}
var
  StartupInfo: Windows.TStartupInfo;        // start-up info passed to process
  ProcessInfo: Windows.TProcessInformation; // info about the process
  ProcessExitCode: Windows.DWord;           // process's exit code
  SafeCommandLine: string;                  // unique copy of CommandLine
begin
  // Modification to work round "feature" in CreateProcessW API function used
  // by Unicode Delphis. See http://bit.ly/adgQ8H.
  SafeCommandLine := CommandLine;
  UniqueString(SafeCommandLine);
  // Set default error result
  Result := False;
  // Initialise startup info structure to 0, and record length
  FillChar(StartupInfo, SizeOf(StartupInfo), 0);
  StartupInfo.cb := SizeOf(StartupInfo);
  // Execute application commandline
  if Windows.CreateProcess(nil, PChar(SafeCommandLine),
    nil, nil, False, 0, nil, nil,
    StartupInfo, ProcessInfo) then
  begin
    try
      // Now wait for application to complete
      if Windows.WaitForSingleObject(ProcessInfo.hProcess, INFINITE)
        = WAIT_OBJECT_0 then
        // It's completed - get its exit code
        if Windows.GetExitCodeProcess(ProcessInfo.hProcess,
          ProcessExitCode) then
          // Check exit code is zero => successful completion
          if ProcessExitCode = 0 then
            Result := True;
    finally
      // Tidy up
      Windows.CloseHandle(ProcessInfo.hProcess);
      Windows.CloseHandle(ProcessInfo.hThread);
    end;
  end;
end;
// End
end.
