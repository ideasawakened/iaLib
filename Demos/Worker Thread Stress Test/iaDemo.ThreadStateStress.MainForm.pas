unit iaDemo.ThreadStateStress.MainForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  iaDemo.ExampleThread;

type
  TfrmThreadStateTest = class(TForm)
    tmrThreadEvent:TTimer;
    panTop:TPanel;
    butStartTimer:TButton;
    butStopTimer:TButton;
    panStats:TPanel;
    Label1:TLabel;
    Label2:TLabel;
    Label3:TLabel;
    Label4:TLabel;
    Label5:TLabel;
    Label6:TLabel;
    labThreadsCreated:TLabel;
    labThreadsStarted:TLabel;
    labThreadsStopped:TLabel;
    labIsActiveChecks:TLabel;
    labCanStartChecks:TLabel;
    labThreadsFreed:TLabel;
    labTimerActiveStatus:TLabel;
    labTimerStarted:TLabel;
    panLog:TPanel;
    memLog:TMemo;
    procedure butStartTimerClick(Sender:TObject);
    procedure butStopTimerClick(Sender:TObject);
    procedure FormCreate(Sender:TObject);
    procedure FormDestroy(Sender:TObject);
    procedure tmrThreadEventTimer(Sender:TObject);
    procedure FormCloseQuery(Sender:TObject; var CanClose:Boolean);
  private
    fWorkerThreads:TArray<TSimpleExample>;
    fSelectedWorker:Integer;
    fCountCreate:Int64;
    fCountFree:Int64;
    fCountStop:Int64;
    fCountStart:Int64;
    fCountIsActive:Int64;
    fCountCanStart:Int64;
    fTestCodeSite:Boolean;
    fClosed:Boolean;
    procedure LogProgress(const LogEntry:string);
    procedure DoCreateThread;
    procedure DoFree;
    procedure DoStop;
    procedure DoStart;
    procedure DoIsActive;
    procedure DoCanStart;
    procedure TakeAction(const ForceAllStop:Boolean = False);
  end;

var
  frmThreadStateTest:TfrmThreadStateTest;
  fActionLock:TCriticalSection;

const
  MAX_THREADS = 150;

implementation

uses
  CodeSiteLogging,
  iaRTL.Logging,
  iaRTL.Logging.Debugger.Windows,
  iaRTL.Logging.CodeSite;

{$R *.dfm}


procedure TfrmThreadStateTest.FormCreate(Sender:TObject);
begin
  ReportMemoryLeaksOnShutdown := True;
  fTestCodeSite := CodeSite.Installed;
end;


procedure TfrmThreadStateTest.FormDestroy(Sender:TObject);
var
  Worker:TSimpleExample;
begin
  fActionLock.Enter;
  try
    tmrThreadEvent.Enabled := False;
    for Worker in fWorkerThreads do
    begin
      Worker.Free;
    end;
  finally
    fActionLock.Leave;
  end;
end;


procedure TfrmThreadStateTest.FormCloseQuery(Sender:TObject; var CanClose:Boolean);
begin
  tmrThreadEvent.Enabled := False;
  fClosed := True;
end;


procedure TfrmThreadStateTest.butStartTimerClick(Sender:TObject);
begin
  fActionLock.Enter;
  try
    memLog.Lines.Clear;
    LogProgress('Start clicked');
    if not tmrThreadEvent.Enabled then
    begin
      labTimerActiveStatus.Caption := 'Timer Active';
      labTimerStarted.Caption := FormatDateTime('mm/dd/yyyy hh:nn:ss', Now);
      tmrThreadEvent.Enabled := True;
    end;
  finally
    fActionLock.Leave;
  end;
end;


procedure TfrmThreadStateTest.butStopTimerClick(Sender:TObject);
begin
  fActionLock.Enter;
  try
    LogProgress(Format('Stop clicked [%d]', [GetTickCount]));
    tmrThreadEvent.Enabled := False;
    TakeAction(True);
    labTimerStarted.Caption := labTimerStarted.Caption + ' - ' + FormatDateTime('mm/dd/yyyy hh:nn:ss', Now);
    labTimerActiveStatus.Caption := 'Timer Not Active';
  finally
    fActionLock.Leave;
  end;
end;


procedure TfrmThreadStateTest.LogProgress(const LogEntry:string);
begin
  if memLog.Lines.Count > (MAX_THREADS*3) then
  begin
    memLog.Lines.Clear;
  end;
  memLog.Lines.Add(LogEntry);
  memLog.Repaint;
end;


procedure TfrmThreadStateTest.tmrThreadEventTimer(Sender:TObject);
begin
  if (not fClosed) and fActionLock.TryEnter then
  begin
    try
      tmrThreadEvent.Enabled := False;
      tmrThreadEvent.Interval := Trunc(Random(50)) + 1;
      TakeAction;
      tmrThreadEvent.Enabled := True;
    finally
      fActionLock.Leave;
    end;
  end;
end;


// Validate that the methods can be externally called in any order, during any current state of the thread
procedure TfrmThreadStateTest.TakeAction(const ForceAllStop:Boolean = False);
var
  ActionToTake:Integer;
  CurrentWorkerThreadCount:Integer;
  Worker:TSimpleExample;
begin
  CurrentWorkerThreadCount := Length(fWorkerThreads);
  if ForceAllStop then
  begin
    if CurrentWorkerThreadCount = 0 then
      Exit;
    for Worker in fWorkerThreads do
    begin
      LogProgress(Format('Stopping %s [%d]', [Worker.ThreadNameForDebugger, GetTickCount]));
      Worker.Stop;
      Inc(fCountStop);
    end;
    for Worker in fWorkerThreads do
    begin
      LogProgress(Format('Freeing %s [%d]', [Worker.ThreadNameForDebugger, GetTickCount]));
      Worker.Free;
      Inc(fCountFree);
    end;
    fWorkerThreads := nil;
    labThreadsFreed.Caption := IntToStr(fCountFree);
  end
  else
  begin
    ActionToTake := Trunc(Random(10));

    fSelectedWorker := Trunc(Random(CurrentWorkerThreadCount));
    if ((fSelectedWorker < CurrentWorkerThreadCount) and (CurrentWorkerThreadCount > 0)) and ((ActionToTake < 5) or (CurrentWorkerThreadCount > MAX_THREADS)) then
    begin
      case ActionToTake of
        0:
          DoFree;
        1:
          DoStart;
        2:
          DoIsActive;
        3:
          DoCanStart;
      else
        DoStop;
      end;
    end
    else
    begin
      DoCreateThread;
    end;
  end;
end;


procedure TfrmThreadStateTest.DoCreateThread;
var
  WorkerThread:TSimpleExample;
  Logger:ILogger;
begin
  if fTestCodeSite and Odd(Random(100)) then
  begin
    Logger := TiaCodeSiteLogger.Create('Viewer');
  end
  else
  begin
    Logger := TiaWindowsDebugLogging.Create;
  end;
  Logger.SetLoggingIsEnabled(True);
  Logger.SetCurrentLogLevel(TiaLogLevel.All);

  WorkerThread := TSimpleExample.Create('Worker' + fCountCreate.ToString, Logger);
  WorkerThread.PauseBetweenWorkMS := Random(1000);
  WorkerThread.OnReportProgress := LogProgress;

  fWorkerThreads := fWorkerThreads + [WorkerThread];
  Inc(fCountCreate);
  labThreadsCreated.Caption := IntToStr(fCountCreate);
end;


procedure TfrmThreadStateTest.DoFree;
var
  WorkerThread:TSimpleExample;
begin
  WorkerThread := fWorkerThreads[fSelectedWorker];
  WorkerThread.Free;
  Delete(fWorkerThreads, fSelectedWorker, 1);
  Inc(fCountFree);
  labThreadsFreed.Caption := IntToStr(fCountFree);
end;


procedure TfrmThreadStateTest.DoStop;
var
  WorkerThread:TSimpleExample;
begin
  WorkerThread := fWorkerThreads[fSelectedWorker];
  WorkerThread.Stop;
  Inc(fCountStop);
  labThreadsStopped.Caption := IntToStr(fCountStop);
end;


procedure TfrmThreadStateTest.DoStart;
var
  WorkerThread:TSimpleExample;
begin
  WorkerThread := fWorkerThreads[fSelectedWorker];
  WorkerThread.Start;
  Inc(fCountStart);
  labThreadsStarted.Caption := IntToStr(fCountStart);
end;


procedure TfrmThreadStateTest.DoIsActive;
var
  WorkerThread:TSimpleExample;
begin
  WorkerThread := fWorkerThreads[fSelectedWorker];
  WorkerThread.ThreadIsActive;
  Inc(fCountIsActive);
  labIsActiveChecks.Caption := IntToStr(fCountIsActive);
end;


procedure TfrmThreadStateTest.DoCanStart;
var
  WorkerThread:TSimpleExample;
begin
  WorkerThread := fWorkerThreads[fSelectedWorker];
  WorkerThread.CanBeStarted;
  Inc(fCountCanStart);
  labCanStartChecks.Caption := IntToStr(fCountCanStart);
end;

initialization
  fActionLock := TCriticalSection.Create;
finalization
  fActionLock.Free;

end.
