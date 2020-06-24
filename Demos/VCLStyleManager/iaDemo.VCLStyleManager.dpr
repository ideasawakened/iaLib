program iaDemo.VCLStyleManager;

uses
  Vcl.Forms,
  iaDemo.VCLStyleManager.MainForm in 'iaDemo.VCLStyleManager.MainForm.pas' {DemoForm},
  iaVCL.StyleFileList in '..\..\Source\iaVCL.StyleFileList.pas',
  iaVCL.StyleManager in '..\..\Source\iaVCL.StyleManager.pas',
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Auric');
  Application.CreateForm(TDemoForm, DemoForm);
  Application.Run;
end.
