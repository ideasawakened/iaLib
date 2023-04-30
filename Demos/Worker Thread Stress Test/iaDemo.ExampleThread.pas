unit iaDemo.ExampleThread;

interface

uses
  iaRTL.Threading.LoggedWorker;

type

  TSimpleExample = class(TiaLoggedWorkerThread)
  protected
    procedure Run; override;
  end;

implementation

uses
  System.SysUtils;


// repeatedly do some work that eats time..
// WorkerThreads can use Log or ReportProgress methods depending on how worker updates are desired
procedure TSimpleExample.Run;
var
  TempWorkVar:Extended;
  SleepTime:Integer;
begin
  TempWorkVar := 0;
  Log(Format('%s - work loop in process [%d]', [ThreadNameForDebugger, GetTickCount]));

  while (not ShouldWorkTerminate) do // Check to see if something outside this thread has requested us to terminate
  begin

    TempWorkVar := Cos(TempWorkVar); // simulate some work

    if (Random(100) mod 4 = 0) then
    begin
      SleepTime := Random(10000);
      Log(Format('%s - random extra sleep %dms [%d]', [ThreadNameForDebugger, SleepTime, GetTickCount])); // simulate occasional wait on Input/Output

      //if ShouldWorkTerminate(SleepTime) then  // Similar outcome to next line
      if not self.Sleep(SleepTime) then
      begin
        Log(Format('%s - Aborted sleep to exit [%d]', [ThreadNameForDebugger, GetTickCount]));  //Examine logs to see how fast this is received
        Exit;
      end;
    end;

    if (Random(100) mod 7 = 0) then
    begin
      // We're in a worker thread execution loop (until ShouldWorkTerminate)
      // We'll exit this Run, but look in the logs for this thread to be restarted after PauseBetweenWorkMS
      Log(Format('%s - random early work exit [%d]', [ThreadNameForDebugger, GetTickCount]));
      Break;
    end;

  end;
end;


initialization

Randomize;


end.
