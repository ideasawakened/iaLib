unit iaDemo.ExecutionProfiler.MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TDemoExecutionProfilerForm = class(TForm)
    butExecuteDemoCode: TButton;
    butViewCurrentStatistics: TButton;
    memLog: TMemo;
    butExecMultiThreaded: TButton;
    procedure butExecuteDemoCodeClick(Sender: TObject);
    procedure butViewCurrentStatisticsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure butExecMultiThreadedClick(Sender: TObject);
  private
    procedure DoSomeComplexCode;
  public
    { Public declarations }
  end;

  TMySimpleThread = class(TThread)
  private
    fSleepTime:Integer;
  public
    constructor Create(const pSleepTime:Integer);
    procedure Execute(); override;
  end;

var
  DemoExecutionProfilerForm: TDemoExecutionProfilerForm;

implementation
uses
  System.DateUtils,
  iaRTL.ExecutionProfiler;

{$R *.dfm}


procedure TDemoExecutionProfilerForm.FormCreate(Sender: TObject);
begin
  ReportMemoryLeaksOnShutdown := True;
  memLog.Clear;
  memLog.Lines.Add(iaRTL.ExecutionProfiler.CSVHeaderLine);
end;


//Example how to automatically save performance metrics to a file when the program exits
procedure TDemoExecutionProfilerForm.FormDestroy(Sender: TObject);
{$IFDEF PROFILER}
var
  vAutoSaveStats:TStringList;
{$ENDIF}
begin
  {$IFDEF PROFILER}
  vAutoSaveStats := TStringList.Create;
  try
    if TiaProfiler.ExportStats(vAutoSaveStats, TiaExportResolution.Milliseconds) > 0 then
    begin
      vAutoSaveStats.SaveToFile('PerformanceStats.csv');
    end;
  finally
    vAutoSaveStats.Free;
  end;
  {$ENDIF}
end;


procedure TDemoExecutionProfilerForm.butViewCurrentStatisticsClick(Sender: TObject);
begin
  {$IFDEF PROFILER}
  TiaProfiler.ExportStats(memLog.Lines, TiaExportResolution.Milliseconds);
  {$ENDIF}
end;


procedure TDemoExecutionProfilerForm.butExecuteDemoCodeClick(Sender: TObject);
var
  i:integer;
begin
  for i := 1 to 10 do
  begin
    DoSomeComplexCode;
  end;
end;


//Here's an example "Old school" way of doing timing:
//procedure TDemoExecutionProfilerForm.DoSomeComplexCode;
//var
//  StartTime:TDateTime;
//  DebugMessage:String;
//begin
//  StartTime := Now;
//  Sleep(75);  //some time intensive code block
//  DebugMessage := Format('DoSomeComplexCode took %dms', [MillisecondsBetween(Now, StartTime)]);
//  OutputDebugString(PChar(DebugMessage));
//end;


//Here's the old school method upgraded to TiaProfiler:
//procedure TDemoExecutionProfilerForm.DoSomeComplexCode;
//begin
//  TiaProfiler.StartTimer('DoSomeComplexCode');
//  Sleep(75);  //some time intensive code block
//  TiaProfiler.StopTimer('DoSomeComplexCode');
//end;


//The same TiaProfiler code surrounded with compiler define, as recommended.
procedure TDemoExecutionProfilerForm.DoSomeComplexCode;
begin
  {$IFDEF PROFILER}TiaProfiler.StartTimer('DoSomeComplexCode');{$ENDIF}
  Sleep(75);  //some time intensive code block
  {$IFDEF PROFILER}TiaProfiler.StopTimer('DoSomeComplexCode');{$ENDIF}
end;


//Example used for Issue #2 correction
//https://github.com/ideasawakened/iaLib/issues/2
procedure TDemoExecutionProfilerForm.butExecMultiThreadedClick(Sender: TObject);
begin
  //Before fix, this will produce incorrect results (around 1 second min and 3 second max)
  //After fix, this should produce correct results (around 2 second min, max, average)
  TMySimpleThread.Create(2000);
  Sleep(1000);
  TMySimpleThread.Create(2000);
end;


constructor TMySimpleThread.Create(const pSleepTime:Integer);
begin
  fSleepTime := pSleepTime;
  FreeOnTerminate := True;
  inherited Create;
end;

procedure TMySimpleThread.Execute;
begin
  {$IFDEF PROFILER}TiaProfiler.StartTimer('ThreadedExample1');{$ENDIF}
  Sleep(fSleepTime);  //some time intensive code block
  {$IFDEF PROFILER}TiaProfiler.StopTimer('ThreadedExample1');{$ENDIF}
end;

end.
