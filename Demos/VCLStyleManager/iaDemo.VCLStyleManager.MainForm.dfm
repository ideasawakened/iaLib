object DemoForm: TDemoForm
  Left = 0
  Top = 0
  Caption = 'TiaVCLStyleManager demo'
  ClientHeight = 411
  ClientWidth = 655
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 655
    Height = 149
    Align = alTop
    TabOrder = 0
    object Label1: TLabel
      Left = 12
      Top = 14
      Width = 145
      Height = 13
      Caption = 'Select style with a ComboBox:'
    end
    object Label2: TLabel
      Left = 328
      Top = 14
      Width = 86
      Height = 13
      Caption = 'Or, use a list box:'
    end
    object cboStyle: TComboBox
      Left = 168
      Top = 11
      Width = 145
      Height = 21
      Style = csDropDownList
      TabOrder = 0
      OnChange = cboStyleChange
    end
    object lstStyle: TListBox
      Left = 420
      Top = 11
      Width = 194
      Height = 132
      ItemHeight = 13
      TabOrder = 1
      OnClick = lstStyleClick
    end
  end
  object Memo1: TMemo
    Left = 0
    Top = 149
    Width = 655
    Height = 243
    Align = alClient
    Lines.Strings = (
      
        'Project options customized to include "Auric" style to be used a' +
        's default VCL Style for this application')
    TabOrder = 1
    ExplicitTop = 148
    ExplicitHeight = 244
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 392
    Width = 655
    Height = 19
    Panels = <>
  end
  object MainMenu1: TMainMenu
    Left = 616
    Top = 104
    object File1: TMenuItem
      Caption = '&File'
      object Exit1: TMenuItem
        Caption = 'E&xit'
        OnClick = Exit1Click
      end
    end
  end
end
