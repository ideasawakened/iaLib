program iaDemo.ExecutionProfiler;

uses
  Vcl.Forms,
  iaDemo.ExecutionProfiler.MainForm in 'iaDemo.ExecutionProfiler.MainForm.pas' {DemoExecutionProfilerForm},
  iaRTL.ExecutionProfiler in '..\..\Source\iaRTL.ExecutionProfiler.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDemoExecutionProfilerForm, DemoExecutionProfilerForm);
  Application.Run;
end.
