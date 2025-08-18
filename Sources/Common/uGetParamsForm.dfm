object fmGetParamsForm: TfmGetParamsForm
  Left = 0
  Top = 0
  Caption = #1059#1082#1072#1078#1080#1090#1077' '#1087#1072#1088#1072#1084#1077#1090#1088#1099
  ClientHeight = 300
  ClientWidth = 409
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  TextHeight = 15
  object pCommon: TGridPanel
    Left = 0
    Top = 0
    Width = 409
    Height = 300
    Align = alClient
    BevelOuter = bvNone
    ColumnCollection = <
      item
        Value = 100.000000000000000000
      end>
    ControlCollection = <
      item
        Column = 0
        Control = pContent
        Row = 0
      end
      item
        Column = 0
        Control = pButtons
        Row = 1
      end>
    RowCollection = <
      item
        Value = 100.000000000000000000
      end
      item
        SizeStyle = ssAbsolute
        Value = 34.000000000000000000
      end>
    TabOrder = 0
    ExplicitLeft = 120
    ExplicitTop = 148
    ExplicitWidth = 185
    ExplicitHeight = 41
    object pContent: TPanel
      Left = 0
      Top = 0
      Width = 409
      Height = 266
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitLeft = 112
      ExplicitTop = 132
      ExplicitWidth = 185
      ExplicitHeight = 41
      object lText: TLabel
        AlignWithMargins = True
        Left = 4
        Top = 4
        Width = 401
        Height = 30
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Align = alTop
        Alignment = taCenter
        Caption = 
          'Text Text Text Text Text Text Text Text Text Text Text Text Text' +
          ' Text Text Text Text Text Text Text Text Text Text Text Text Tex' +
          't Text Text Text Text Text Text Text '
        WordWrap = True
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 408
      end
      object mParams: TMemo
        AlignWithMargins = True
        Left = 4
        Top = 38
        Width = 401
        Height = 228
        Margins.Left = 4
        Margins.Top = 0
        Margins.Right = 4
        Margins.Bottom = 0
        Align = alClient
        TabOrder = 0
        ExplicitLeft = 112
        ExplicitTop = 92
        ExplicitWidth = 185
        ExplicitHeight = 89
      end
    end
    object pButtons: TPanel
      Left = 0
      Top = 266
      Width = 409
      Height = 34
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      ExplicitLeft = 112
      ExplicitTop = 132
      ExplicitWidth = 185
      ExplicitHeight = 41
      DesignSize = (
        409
        34)
      object bOk: TButton
        Left = 248
        Top = 4
        Width = 75
        Height = 25
        Anchors = [akTop, akRight]
        Caption = #1054#1050
        ModalResult = 1
        TabOrder = 0
      end
      object bCancel: TButton
        Left = 330
        Top = 4
        Width = 75
        Height = 25
        Anchors = [akTop, akRight]
        Caption = #1054#1090#1084#1077#1085#1072
        ModalResult = 2
        TabOrder = 1
      end
    end
  end
end
