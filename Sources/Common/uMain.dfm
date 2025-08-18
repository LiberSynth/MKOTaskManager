object fmMain: TfmMain
  Left = 0
  Top = 0
  Caption = 'MKO Task Manager'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object pCommon: TGridPanel
    Left = 0
    Top = 0
    Width = 624
    Height = 441
    Align = alClient
    BevelOuter = bvNone
    ColumnCollection = <
      item
        Value = 33.333333333333340000
      end
      item
        Value = 66.666666666666660000
      end>
    ControlCollection = <
      item
        Column = 1
        Control = pRightSide
        Row = 0
      end
      item
        Column = 0
        Control = pTasks
        Row = 0
      end>
    RowCollection = <
      item
        Value = 100.000000000000000000
      end>
    TabOrder = 0
    object pRightSide: TGridPanel
      Left = 208
      Top = 0
      Width = 416
      Height = 441
      Align = alClient
      BevelOuter = bvNone
      ColumnCollection = <
        item
          Value = 100.000000000000000000
        end>
      ControlCollection = <
        item
          Column = 0
          Control = pRunning
          Row = 0
        end
        item
          Column = 0
          Control = pConsole
          Row = 1
        end>
      RowCollection = <
        item
          Value = 50.000000000000000000
        end
        item
          Value = 50.000000000000000000
        end>
      TabOrder = 0
      object pRunning: TPanel
        Left = 0
        Top = 0
        Width = 416
        Height = 220
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 0
        object lRunning: TLabel
          Left = 4
          Top = 4
          Width = 70
          Height = 15
          Caption = #1042#1099#1087#1086#1083#1085#1077#1085#1080#1077
        end
        object lvRunning: TListView
          AlignWithMargins = True
          Left = 0
          Top = 25
          Width = 416
          Height = 195
          Margins.Left = 0
          Margins.Top = 25
          Margins.Right = 0
          Margins.Bottom = 0
          Align = alClient
          Columns = <>
          TabOrder = 0
        end
      end
      object pConsole: TPanel
        Left = 0
        Top = 220
        Width = 416
        Height = 221
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        object lConsole: TLabel
          Left = 4
          Top = 4
          Width = 47
          Height = 15
          Caption = #1050#1086#1085#1089#1086#1083#1100
        end
        object lvConsole: TListView
          AlignWithMargins = True
          Left = 0
          Top = 25
          Width = 416
          Height = 196
          Margins.Left = 0
          Margins.Top = 25
          Margins.Right = 0
          Margins.Bottom = 0
          Align = alClient
          Columns = <>
          TabOrder = 0
        end
      end
    end
    object pTasks: TPanel
      Left = 0
      Top = 0
      Width = 208
      Height = 441
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object lTasks: TLabel
        Left = 4
        Top = 4
        Width = 39
        Height = 15
        Caption = #1047#1072#1076#1072#1095#1080
      end
      object sgTasks: TStringGrid
        AlignWithMargins = True
        Left = 0
        Top = 25
        Width = 208
        Height = 416
        Margins.Left = 0
        Margins.Top = 25
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alClient
        ColCount = 2
        DefaultRowHeight = 20
        FixedCols = 0
        RowCount = 2
        ParentShowHint = False
        ShowHint = False
        TabOrder = 0
      end
    end
  end
end
