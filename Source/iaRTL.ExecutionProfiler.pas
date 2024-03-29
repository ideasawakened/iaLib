unit iaRTL.ExecutionProfiler;

interface

uses
  System.Diagnostics,
  System.Generics.Collections,
  System.Classes,
  System.SyncObjs;

type

  TiaTimerStats = record
    TimerName:string;
    TotalExecutions:Int64;
    ElapsedTicks:Int64;
    MinTicks:Int64;
    MaxTicks:Int64;
    function AverageTicks:Int64;
    function ElapsedMS:Int64;
    function AverageMS:Int64;
    function MinMS:Int64;
    function MaxMS:Int64;
  end;
  PiaTimerStats = ^TiaTimerStats;

  TiaTimerStatsArray = array of TiaTimerStats;
  TiaExportResolution = (Ticks, Milliseconds);

  TiaThreadWatch = class
  private
    fStopWatch:TStopwatch;
  End;

  TiaNamedTimer = class
  private
    fThreadWatches:TObjectDictionary<Cardinal, TiaThreadWatch>;
    fStats:TiaTimerStats;
    function GetStats:PiaTimerStats;
    procedure SetStats(const Value:PiaTimerStats);
  protected
    procedure StartNew;
    procedure Stop;
    property Stats:PiaTimerStats read GetStats write SetStats;
  public
    constructor Create;
    destructor Destroy; override;
  end;


  TiaProfiler = class
  private class var
    ActiveTimers:TObjectDictionary<string, TiaNamedTimer>;
    TickFrequency:Double;
    ThreadLock:TCriticalSection;
  private
    class constructor CreateClass;
    class destructor DestroyClass;
  protected
    class function TicksToMS(const pTicks:Int64):Int64;
  public
    class procedure StartTimer(const pTimerName:string);
    class procedure StopTimer(const pTimerName:string);
    class function ExportStats(const pDestination:TStrings; const pResolution:TiaExportResolution = TiaExportResolution.Ticks):Integer;

    class procedure ClearTimers;
    class function GetAllTimerStats:TiaTimerStatsArray;
  public
    class var TimersAreEnabled:boolean;
  end;


resourcestring
  CSVHeaderLine = 'Timer, Total Executions, Total Elapsed, Average, Min, Max';


implementation

uses
  System.SysUtils,
  System.TimeSpan;


class constructor TiaProfiler.CreateClass;
begin
  ActiveTimers := TObjectDictionary<string, TiaNamedTimer>.Create([doOwnsValues]);
  TimersAreEnabled := True;
  ThreadLock := TCriticalSection.Create;

  if TStopwatch.IsHighResolution then
  begin
    TickFrequency := 10000000.0 / TStopwatch.Frequency;
  end
  else
  begin
    TickFrequency := 1.0;
  end;
end;


class destructor TiaProfiler.DestroyClass;
begin
  TimersAreEnabled := False;
  ThreadLock.Free;
  ActiveTimers.Free;
end;


class procedure TiaProfiler.StartTimer(const pTimerName:string);
var
  vNamedTimer:TiaNamedTimer;
begin
  if not TimersAreEnabled then
    Exit;

  ThreadLock.Acquire;
  try
    if not ActiveTimers.TryGetValue(pTimerName, vNamedTimer) then
    begin
      vNamedTimer := TiaNamedTimer.Create;
      vNamedTimer.Stats.TimerName := pTimerName;
      ActiveTimers.Add(pTimerName, vNamedTimer);
    end;
    vNamedTimer.StartNew;
  finally
    ThreadLock.Release;
  end;
end;


class procedure TiaProfiler.StopTimer(const pTimerName:string);
var
  vNamedTimer:TiaNamedTimer;
begin
  if not TimersAreEnabled then
    Exit;

  ThreadLock.Acquire;
  try
    if ActiveTimers.TryGetValue(pTimerName, vNamedTimer) then
    begin
      vNamedTimer.Stop;
    end;
  finally
    ThreadLock.Release;
  end;
end;


class procedure TiaProfiler.ClearTimers;
begin
  ThreadLock.Acquire;
  try
    ActiveTimers.Clear;
  finally
    ThreadLock.Release;
  end;
end;


class function TiaProfiler.TicksToMS(const pTicks:Int64):Int64;
begin
  if TStopwatch.IsHighResolution then
  begin
    Result := Trunc(pTicks * TickFrequency) div TTimeSpan.TicksPerMillisecond;
  end
  else
  begin
    Result := pTicks div TTimeSpan.TicksPerMillisecond;
  end;
end;


class function TiaProfiler.ExportStats(const pDestination:TStrings; const pResolution:TiaExportResolution = TiaExportResolution.Ticks):Integer;
const
  OutputFormat = '%s, %d, %d, %d, %d, %d';
var
  vAllStats:TiaTimerStatsArray;
  vItem:TiaTimerStats;
begin
  vAllStats := GetAllTimerStats;
  Result := Length(vAllStats);

  for vItem in vAllStats do
  begin
    if pResolution = TiaExportResolution.Ticks then
    begin
      pDestination.Add(Format(OutputFormat, [vItem.TimerName.QuotedString('"'), vItem.TotalExecutions, vItem.ElapsedTicks, vItem.AverageTicks, vItem.MinTicks, vItem.MaxTicks]));
    end
    else
    begin
      pDestination.Add(Format(OutputFormat, [vItem.TimerName.QuotedString('"'), vItem.TotalExecutions, vItem.ElapsedMS, vItem.AverageMS, vItem.MinMS, vItem.MaxMS]));
    end;
  end;
end;


class function TiaProfiler.GetAllTimerStats:TiaTimerStatsArray;
var
  vItem:TPair<string, TiaNamedTimer>;
  vAllItems:TArray<TPair<string, TiaNamedTimer>>;
  i:Integer;
begin
  ThreadLock.Acquire;
  try
    SetLength(Result, ActiveTimers.Count);
    if ActiveTimers.Count > 0 then
    begin
      vAllItems := ActiveTimers.ToArray;
      for i := 0 to Length(vAllItems) - 1 do
      begin
        vItem := vAllItems[i];
        Result[i] := vItem.Value.Stats^;
      end;
    end;
  finally
    ThreadLock.Release;
  end;
end;


constructor TiaNamedTimer.Create;
begin
  inherited;
  fThreadWatches := TObjectDictionary<cardinal, TiaThreadWatch>.Create([doOwnsValues]);
end;


destructor TiaNamedTimer.Destroy;
begin
  fThreadWatches.Free;
  inherited;
end;


function TiaNamedTimer.GetStats:PiaTimerStats;
begin
  Result := @fStats;
end;


procedure TiaNamedTimer.SetStats(const Value:PiaTimerStats);
begin
  fStats := Value^;
end;


procedure TiaNamedTimer.StartNew;
var
  vCurrentThreadId:Cardinal;
  vThreadWatch:TiaThreadWatch;
begin
  vCurrentThreadId := TThread.CurrentThread.ThreadID;
  Assert(not fThreadWatches.TryGetValue(vCurrentThreadId, vThreadWatch));

  vThreadWatch := TiaThreadWatch.Create;
  fThreadWatches.Add(vCurrentThreadId, vThreadWatch);
  vThreadWatch.fStopWatch := TStopWatch.StartNew;
end;


procedure TiaNamedTimer.Stop;
var
  vCurrentThreadId:Cardinal;
  vThreadWatch:TiaThreadWatch;
  vTicks:Int64;
begin
  vCurrentThreadId := TThread.CurrentThread.ThreadID;
  if fThreadWatches.TryGetValue(vCurrentThreadId, vThreadWatch) then
  begin
    vThreadWatch.fStopWatch.Stop;

    vTicks := vThreadWatch.fStopWatch.ElapsedTicks;
    if Stats.TotalExecutions = 0 then
    begin
      Stats.MinTicks := vTicks;
      Stats.MaxTicks := vTicks;
    end
    else
    begin
      if vTicks < Stats.MinTicks then
      begin
        Stats.MinTicks := vTicks;
      end;
      if vTicks > Stats.MaxTicks then
      begin
        Stats.MaxTicks := vTicks;
      end;
    end;

    Inc(Stats.TotalExecutions);
    Inc(Stats.ElapsedTicks, vTicks);

    fThreadWatches.Remove(vCurrentThreadId);
  end;
end;


function TiaTimerStats.ElapsedMS:Int64;
begin
  Result := TiaProfiler.TicksToMS(self.ElapsedTicks);
end;


function TiaTimerStats.AverageTicks:Int64;
begin
  if self.TotalExecutions > 0 then
  begin
    Result := Trunc(self.ElapsedTicks / self.TotalExecutions);
  end
  else
  begin
    Result := 0;
  end;
end;


function TiaTimerStats.AverageMS:Int64;
begin
  Result := TiaProfiler.TicksToMS(self.AverageTicks);
end;


function TiaTimerStats.MinMS:Int64;
begin
  Result := TiaProfiler.TicksToMS(self.MinTicks);
end;


function TiaTimerStats.MaxMS:Int64;
begin
  Result := TiaProfiler.TicksToMS(self.MaxTicks);
end;


end.
