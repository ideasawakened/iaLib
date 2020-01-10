program iaFMXDemo.ScreenCursorStack;

uses
  System.StartUpCopy,
  FMX.Forms,
  iaFMXDemo.ScreenCursorStack.MainForm in 'iaFMXDemo.ScreenCursorStack.MainForm.pas' {ScreenCursorStackDemoForm},
  iaFMX.ScreenCursorStack in '..\..\..\Source\iaFMX.ScreenCursorStack.pas',
  iaRTL.ScreenCursorStack in '..\..\..\Source\iaRTL.ScreenCursorStack.pas',
  ExampleWorker in '..\..\ExampleWorker.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TScreenCursorStackDemoForm, ScreenCursorStackDemoForm);
  Application.Run;
end.
