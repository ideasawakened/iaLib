object ScreenCursorStackDemoForm: TScreenCursorStackDemoForm
  Left = 0
  Top = 0
  Caption = 'VCL'
  ClientHeight = 111
  ClientWidth = 284
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object butToggleCursor: TButton
    Left = 80
    Top = 24
    Width = 121
    Height = 25
    Caption = 'Toggle Cursor'
    TabOrder = 0
    OnClick = butToggleCursorClick
  end
  object butExampleWork: TButton
    Left = 80
    Top = 55
    Width = 121
    Height = 25
    Caption = 'Example Work'
    TabOrder = 1
    OnClick = butExampleWorkClick
  end
end
