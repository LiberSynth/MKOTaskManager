unit uConsts;

interface

uses
  { Common }
  Common.uConsts;

const

  DC_GOLDEN_SECTION: Double = 1.618;

  SC_MESSAGE_BOX_ERROR_CAPTION = '������';

  SC_TASKS_COLUMN_0_CAPTION = '������';
  SC_TASKS_COLUMN_1_CAPTION = '���';
  SC_TASKS_COLUMN_2_CAPTION = '��������';

  SC_TASKS_ITEMS_COLUMN_1_CAPTION = '������';
  SC_TASKS_ITEMS_COLUMN_2_CAPTION = '���������';
  SC_TASKS_ITEMS_COLUMN_3_CAPTION = '���������';
  SC_TASKS_ITEMS_COLUMN_4_CAPTION = '�������';
  SC_TASKS_ITEMS_COLUMN_5_CAPTION = '���������';

  SC_GET_TASK_PARAMS_FORM_CAPTION = '������� ���������';
  SC_GET_TASK_PARAMS_FORM_TEXT    = '������� ��������� ������� ��������� ������.';

  SC_EMPTY_TASK_PARAMS_ERROR_MESSAGE =

      '������ � ���������� ������ IMKOTaskParams.ValidateParams. ���� �������� ������ �� �������� ���������, ������� ' +
      '������� ��������� �� ������ � �������� ��������� ������ _Params.ErrorMessage.';

implementation

end.
