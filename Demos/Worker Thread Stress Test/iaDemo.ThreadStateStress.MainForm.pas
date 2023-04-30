unit iaDemo.ThreadStateStress.MainForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
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
    fInTimer:Boolean;
    fTestCodeSite:Boolean;
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
  fInTimer := True;
  tmrThreadEvent.Enabled := False;
  for Worker in fWorkerThreads do
  begin
    Worker.Free;
  end;
end;


procedure TfrmThreadStateTest.FormCloseQuery(Sender:TObject; var CanClose:Boolean);
begin
  tmrThreadEvent.Enabled := False;
end;


procedure TfrmThreadStateTest.butStartTimerClick(Sender:TObject);
begin
  if not tmrThreadEvent.Enabled then
  begin
    labTimerActiveStatus.Caption := 'Timer Active';
    labTimerStarted.Caption := FormatDateTime('mm/dd/yyyy hh:nn:ss', Now);
    tmrThreadEvent.Enabled := True;
  end;
end;


procedure TfrmThreadStateTest.butStopTimerClick(Sender:TObject);
begin
  if (not fInTimer) and tmrThreadEvent.Enabled then
  begin
    fInTimer := True;
    tmrThreadEvent.Enabled := False;
    TakeAction(True);
    labTimerStarted.Caption := labTimerStarted.Caption + ' - ' + FormatDateTime('mm/dd/yyyy hh:nn:ss', Now);
    labTimerActiveStatus.Caption := 'Timer Not Active';
    fInTimer := False;
  end;
end;


procedure TfrmThreadStateTest.LogProgress(const LogEntry:string);
begin
  if memLog.Lines.Count > 5000 then
  begin
    memLog.Lines.Clear;
  end;
  memLog.Lines.Add(LogEntry);
  memLog.Repaint;
end;


procedure TfrmThreadStateTest.tmrThreadEventTimer(Sender:TObject);
begin
  if (not fInTimer) and (not Application.Terminated) then
  begin
    tmrThreadEvent.Enabled := False;
    fInTimer := True;
    tmrThreadEvent.Interval := Trunc(Random(50)) + 1;
    TakeAction;
    fInTimer := False;
    tmrThreadEvent.Enabled := True;
  end;
end;


// Validate that the methods can be externally called in any order, during any current state of the thread
procedure TfrmThreadStateTest.TakeAction(const ForceAllStop:Boolean = False);
const
  MAX_THREADS = 300;
var
  ActionToTake:Integer;
  CurrentWorkerThreadCount:Integer;
  Worker:TSimpleExample;
  i:Integer;
begin
  CurrentWorkerThreadCount := Length(fWorkerThreads);
  if ForceAllStop then
  begin
    if CurrentWorkerThreadCount = 0 then
      Exit;
    for i := low(fWorkerThreads) to high(fWorkerThreads) do
    begin
      Worker := fWorkerThreads[i];
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
  WorkerThread.PauseBetweenWorkMS := Random(10000);
  if Odd(Random(100)) then
  begin
    WorkerThread.OnReportProgress := LogProgress;
  end;

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


end.
