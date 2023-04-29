program iaDemo.WorkerThread.StressTest;

uses
  Vcl.Forms,
  iaDemo.ThreadStateStress.MainForm in 'iaDemo.ThreadStateStress.MainForm.pas' {frmThreadStateTest},
  iaDemo.ExampleThread in 'iaDemo.ExampleThread.pas',
  iaRTL.Logging.CodeSite in '..\..\Source\iaRTL.Logging.CodeSite.pas',
  iaRTL.Logging.Debugger.Windows in '..\..\Source\iaRTL.Logging.Debugger.Windows.pas',
  iaRTL.Logging in '..\..\Source\iaRTL.Logging.pas',
  iaRTL.Threading.LoggedWorker in '..\..\Source\iaRTL.Threading.LoggedWorker.pas',
  iaRTL.Threading in '..\..\Source\iaRTL.Threading.pas',
  iaRTL.NameDelphiThreads.Windows in '..\..\Source\iaRTL.NameDelphiThreads.Windows.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmThreadStateTest, frmThreadStateTest);
  Application.Run;
end.
