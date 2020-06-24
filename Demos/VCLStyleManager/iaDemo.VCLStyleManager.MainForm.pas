unit iaDemo.VCLStyleManager.MainForm;

interface

uses
  System.Classes,
  System.SysUtils,
  Vcl.ComCtrls,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Menus,
  Vcl.StdCtrls;

type

  TDemoForm = class(TForm)
    Panel1:TPanel;
    MainMenu1:TMainMenu;
    File1:TMenuItem;
    Exit1:TMenuItem;
    Label1:TLabel;
    cboStyle:TComboBox;
    Memo1:TMemo;
    lstStyle:TListBox;
    Label2:TLabel;
    StatusBar1: TStatusBar;
    procedure FormCreate(Sender:TObject);
    procedure Exit1Click(Sender:TObject);
    procedure cboStyleChange(Sender:TObject);
    procedure lstStyleClick(Sender:TObject);
  private
    procedure PopulateStyleLists();
    procedure ResetSelection();
  public
    { Public declarations }
  end;

var
  DemoForm:TDemoForm;

implementation

uses
  Vcl.Themes,
  iaVCL.StyleManager;

{$R *.dfm}


procedure TDemoForm.FormCreate(Sender:TObject);
begin
  ReportMemoryLeaksOnShutdown := True;

  // Customize path to style files (if needed) before populating the list
  // Search path defaults to IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'Themes'
  // A 'VCLStyles' directory was added to the root folder in this GitHub repo
  TiaVCLStyleManager.StyleSearchPath := '..\..\..\..\VCLStyles';

  PopulateStyleLists();
end;


procedure TDemoForm.ResetSelection();
begin
  // simply keeps the two lists in-sync
  cboStyle.ItemIndex := cboStyle.Items.IndexOf(TStyleManager.ActiveStyle.Name);
  lstStyle.ItemIndex := lstStyle.Items.IndexOf(TStyleManager.ActiveStyle.Name);
end;


procedure TDemoForm.PopulateStyleLists();
begin
  // demo ComboBox usage
  TiaVCLStyleManager.PopulateStyleList(cboStyle.Items);

  // demo ListBox usage
  TiaVCLStyleManager.PopulateStyleList(lstStyle.Items);

  ResetSelection();
end;


procedure TDemoForm.cboStyleChange(Sender:TObject);
begin
  // demo ComboBox usage
  TiaVCLStyleManager.HandleSelectionChange(cboStyle.Items, cboStyle.ItemIndex);
  ResetSelection();
end;


procedure TDemoForm.lstStyleClick(Sender:TObject);
begin
  // demo ListBox usage
  TiaVCLStyleManager.HandleSelectionChange(lstStyle.Items, lstStyle.ItemIndex);
  ResetSelection();
end;


procedure TDemoForm.Exit1Click(Sender:TObject);
begin
  Close;
end;


end.
