object frmThreadStateTest: TfrmThreadStateTest
  Left = 0
  Top = 0
  Caption = 'Thread Stress Test - validate randomly changing thread state'
  ClientHeight = 507
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object panTop: TPanel
    Left = 0
    Top = 0
    Width = 635
    Height = 41
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 631
    object butStartTimer: TButton
      Left = 16
      Top = 9
      Width = 89
      Height = 25
      Caption = 'Start Timer'
      TabOrder = 0
      OnClick = butStartTimerClick
    end
    object butStopTimer: TButton
      Left = 111
      Top = 10
      Width = 89
      Height = 25
      Caption = 'Stop Timer'
      TabOrder = 1
      OnClick = butStopTimerClick
    end
  end
  object panStats: TPanel
    Left = 0
    Top = 41
    Width = 635
    Height = 144
    Align = alTop
    TabOrder = 1
    ExplicitWidth = 631
    object Label1: TLabel
      Left = 24
      Top = 16
      Width = 81
      Height = 13
      Caption = 'Threads Created'
    end
    object Label2: TLabel
      Left = 24
      Top = 36
      Width = 78
      Height = 13
      Caption = 'Threads Started'
    end
    object Label3: TLabel
      Left = 24
      Top = 57
      Width = 82
      Height = 13
      Caption = 'Threads Stopped'
    end
    object Label4: TLabel
      Left = 24
      Top = 78
      Width = 79
      Height = 13
      Caption = 'Is Active Checks'
    end
    object Label5: TLabel
      Left = 24
      Top = 99
      Width = 83
      Height = 13
      Caption = 'Can Start Checks'
    end
    object Label6: TLabel
      Left = 24
      Top = 120
      Width = 70
      Height = 13
      Caption = 'Threads Freed'
    end
    object labThreadsCreated: TLabel
      Left = 129
      Top = 16
      Width = 6
      Height = 13
      Caption = '0'
    end
    object labThreadsStarted: TLabel
      Left = 129
      Top = 36
      Width = 6
      Height = 13
      Caption = '0'
    end
    object labThreadsStopped: TLabel
      Left = 129
      Top = 57
      Width = 6
      Height = 13
      Caption = '0'
    end
    object labIsActiveChecks: TLabel
      Left = 129
      Top = 78
      Width = 6
      Height = 13
      Caption = '0'
    end
    object labCanStartChecks: TLabel
      Left = 129
      Top = 99
      Width = 6
      Height = 13
      Caption = '0'
    end
    object labThreadsFreed: TLabel
      Left = 129
      Top = 120
      Width = 6
      Height = 13
      Caption = '0'
    end
    object labTimerActiveStatus: TLabel
      Left = 298
      Top = 16
      Width = 79
      Height = 13
      Caption = 'Timer Not Active'
    end
    object labTimerStarted: TLabel
      Left = 386
      Top = 16
      Width = 16
      Height = 13
      Caption = 'n/a'
    end
  end
  object panLog: TPanel
    Left = 0
    Top = 185
    Width = 635
    Height = 322
    Align = alClient
    TabOrder = 2
    ExplicitWidth = 631
    ExplicitHeight = 321
    object memLog: TMemo
      Left = 1
      Top = 1
      Width = 633
      Height = 320
      Align = alClient
      ScrollBars = ssBoth
      TabOrder = 0
      ExplicitWidth = 629
      ExplicitHeight = 319
    end
  end
  object tmrThreadEvent: TTimer
    Enabled = False
    Interval = 1
    OnTimer = tmrThreadEventTimer
    Left = 576
  end
end
