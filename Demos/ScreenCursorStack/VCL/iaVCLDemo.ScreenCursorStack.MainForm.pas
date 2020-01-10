unit iaVCLDemo.ScreenCursorStack.MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TScreenCursorStackDemoForm = class(TForm)
    butToggleCursor: TButton;
    butExampleWork: TButton;
    procedure butToggleCursorClick(Sender: TObject);
    procedure butExampleWorkClick(Sender: TObject);
  end;

var
  ScreenCursorStackDemoForm: TScreenCursorStackDemoForm;

implementation
uses
  ExampleWorker,
  iaRTL.ScreenCursorStack;

{$R *.dfm}

//clicking Toggle and then Example work should handle nested requests
procedure TScreenCursorStackDemoForm.butToggleCursorClick(Sender: TObject);
begin
  if butToggleCursor.Tag = 0 then
  begin
    TiaScreenCursorStack.PushCursor(crHourGlass);
    butToggleCursor.Tag := 1;
  end
  else
  begin
    TiaScreenCursorStack.PopCursor;
    butToggleCursor.Tag := 0;
  end;
end;

procedure TScreenCursorStackDemoForm.butExampleWorkClick(Sender: TObject);
begin
  TiaScreenCursorStack.PushCursor(crHourGlass);
  try
    TExampleWorker.SimulateWork(2000);
  finally
    TiaScreenCursorStack.PopCursor;
  end;
  ShowMessage('Work completed!');
end;

end.
