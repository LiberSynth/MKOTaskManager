unit uConsts;

interface

uses
  { Common }
  Common.uConsts;

const

  DC_GOLDEN_SECTION: Double = 1.618;

  SC_TASK_ITEM_STATE_CREATED_CAPTION    = '�������';
  SC_TASK_ITEM_STATE_PROCESSING_CAPTION = '�����������';
  SC_TASK_ITEM_STATE_FINISHED_CAPTION   = '���������';
  SC_TASK_ITEM_STATE_CANCELED_CAPTION   = '��������';
  SC_TASK_ITEM_STATE_ERROR_CAPTION      = '������';

  SC_TASKS_COLUMN_0_CAPTION = '������';
  SC_TASKS_COLUMN_1_CAPTION = '��������';

  SC_TASKS_ITEMS_COLUMN_0_CAPTION = '������';
  SC_TASKS_ITEMS_COLUMN_1_CAPTION = '���������';
  SC_TASKS_ITEMS_COLUMN_2_CAPTION = '���������';
  SC_TASKS_ITEMS_COLUMN_3_CAPTION = '�������';

  SC_GET_TASK_PARAMS_FORM_CAPTION = '������� ���������';
  SC_GET_TASK_PARAMS_FORM_TEXT    = '������� ��������� ������� ��������� ������:' + CRLFx2 + '%s';


implementation

end.
