object DemoExecutionProfilerForm: TDemoExecutionProfilerForm
  Left = 0
  Top = 0
  Caption = 'ExecutionProfiler Demo'
  ClientHeight = 371
  ClientWidth = 492
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object butExecuteDemoCode: TButton
    Left = 24
    Top = 24
    Width = 161
    Height = 25
    Caption = 'Execute some demo code'
    TabOrder = 0
    OnClick = butExecuteDemoCodeClick
  end
  object butViewCurrentStatistics: TButton
    Left = 208
    Top = 24
    Width = 161
    Height = 25
    Caption = 'Display Execution Stats'
    TabOrder = 1
    OnClick = butViewCurrentStatisticsClick
  end
  object memLog: TMemo
    Left = 24
    Top = 77
    Width = 449
    Height = 276
    TabOrder = 2
  end
end
