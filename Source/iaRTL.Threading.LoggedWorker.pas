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


  Module History
  1.0 2023-04-29 Darian Miller: Unit created
}
unit iaRTL.Threading.LoggedWorker;

interface

uses
  iaRTL.Threading,
  iaRTL.Logging;

type

  TiaLoggedWorkerThread = class(TiaThread)
  private const
    defPauseBetweenWorkMS = 250;
    defInternalLogEntryType:TiaLogLevel = TiaLogLevel.All; // Logging entries for internal "plumbing" work is not normally captured
  private
    fPauseBetweenWorkMS:UInt32;
    fLogger:ILogger;
  protected
    procedure BeforeRun; override;
    procedure AfterRun; override;
    procedure BetweenRuns; override;
  public
    constructor Create(const ThreadName:string; const OptionalLogger:ILogger = nil); reintroduce;
    destructor Destroy; override;

    procedure Log(const LogEntry:string; const LogLevel:TiaLogLevel = TiaLogLevel.Debug);
    function ShouldWorkTerminate(const SleepAfterCheckMS:Integer = 0):Boolean;

    property PauseBetweenWorkMS:UInt32 read fPauseBetweenWorkMS write fPauseBetweenWorkMS;
  end;


implementation

uses
  System.SysUtils;


constructor TiaLoggedWorkerThread.Create(const ThreadName:string; const OptionalLogger:ILogger = nil);
begin
  inherited Create;
  fLogger := OptionalLogger;
  ThreadNameForDebugger := ThreadName;
  fPauseBetweenWorkMS := defPauseBetweenWorkMS;
  Log(Format('%s: created WorkerThread', [ThreadName]), defInternalLogEntryType);
end;


destructor TiaLoggedWorkerThread.Destroy;
begin
  Log(Format('%s: Shutting down WorkerThread', [ThreadNameForDebugger]), defInternalLogEntryType);
  inherited;
  Log(Format('%s: WorkerThread shut down', [ThreadNameForDebugger]), defInternalLogEntryType);
end;


procedure TiaLoggedWorkerThread.BeforeRun;
begin
  Log('WorkerThread BeforeRun', defInternalLogEntryType);
  inherited;

end;


procedure TiaLoggedWorkerThread.AfterRun;
begin
  Log('WorkerThread AfterRun', defInternalLogEntryType);

  inherited;
end;


procedure TiaLoggedWorkerThread.BetweenRuns;
begin
  Log('WorkerThread BetweenRuns', defInternalLogEntryType);
  inherited;
  ShouldWorkTerminate(PauseBetweenWorkMS);
end;


function TiaLoggedWorkerThread.ShouldWorkTerminate(const SleepAfterCheckMS:Integer = 0):Boolean;
begin
  if ThreadIsActive then
  begin
    Result := False;
    if SleepAfterCheckMS > 0 then
    begin
      Log(Format('Sleeping worker thread for %dms', [SleepAfterCheckMS]), defInternalLogEntryType);
      Self.Sleep(SleepAfterCheckMS); // abortable sleep
    end;
  end
  else
  begin
    Log('WorkerThread termination detected', defInternalLogEntryType);
    Result := True;
  end;
end;


procedure TiaLoggedWorkerThread.Log(const LogEntry:string; const LogLevel:TiaLogLevel = TiaLogLevel.Debug);
begin
  if Assigned(fLogger) then
  begin
    fLogger.Log(LogEntry, LogLevel);
  end;
end;


end.
