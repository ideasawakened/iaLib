program iaVCLDemo.ScreenCursorStack;

uses
  Vcl.Forms,
  iaVCLDemo.ScreenCursorStack.MainForm in 'iaVCLDemo.ScreenCursorStack.MainForm.pas' {ScreenCursorStackDemoForm},
  iaRTL.ScreenCursorStack in '..\..\..\Source\iaRTL.ScreenCursorStack.pas',
  iaVCL.ScreenCursorStack in '..\..\..\Source\iaVCL.ScreenCursorStack.pas',
  ExampleWorker in '..\..\ExampleWorker.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TScreenCursorStackDemoForm, ScreenCursorStackDemoForm);
  Application.Run;
end.
