unit ExampleWorker;

interface

type

  TExampleWorker = class
  public
    class procedure SimulateWork(const pBusyMS:Integer=1000);
  end;


implementation
uses
  System.Diagnostics;


class procedure  TExampleWorker.SimulateWork(const pBusyMS:Integer=1000);
var
  vStopWatch:TStopwatch;
  x:Extended;
begin
  x := 0;
  vStopWatch := TStopWatch.StartNew;
  while vStopWatch.ElapsedMilliseconds < pBusyMS do
  begin
    x := Cos(x);
  end;
end;

end.
