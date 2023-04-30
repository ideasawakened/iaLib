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
procedure TSimpleExample.Run;
var
  TempWorkVar:Extended;
  SleepTime:Integer;
begin
  TempWorkVar := 0;
  Log(ThreadNameForDebugger + ' - work loop in process');

  while (not ShouldWorkTerminate) do // Check to see if something outside this thread has requested us to terminate
  begin

    TempWorkVar := Cos(TempWorkVar); // simulate some work

    if (Random(100) mod 7 = 0) then
    begin
      if Odd(Random(100)) then
      begin
        Log(Format('%s - random early exit', [ThreadNameForDebugger]));
      end
      else
      begin
        ReportProgress(Format('%s - random early exit', [ThreadNameForDebugger]));
      end;
      Break;
    end;

    if (Random(100) mod 4 = 0) then
    begin
      SleepTime := Random(1000);
      ReportProgress(Format('%s - random extra sleep %d', [ThreadNameForDebugger, SleepTime])); // simulate occasional wait on Input/Output
      if ShouldWorkTerminate(SleepTime) then Exit; // use an abortable sleep  (if parent wants to cancel thread, sleep will be interrupted)
    end;

  end;
end;


initialization

Randomize;


end.
