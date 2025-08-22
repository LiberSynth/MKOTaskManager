unit uConsts;

interface

uses
  { VCL }
  Winapi.Messages,
  { Common }
  Common.uConsts;

const

  WM_TASK_INSTANCE_CHANGED = WM_USER + 1000;

  DC_GOLDEN_SECTION: Double = 1.618;

  SC_TASK_STATE_CREATED_CAPTION    = '�������';
  SC_TASK_STATE_PROCESSING_CAPTION = '�����������';
  SC_TASK_STATE_FINISHED_CAPTION   = '���������';
  SC_TASK_STATE_CANCELED_CAPTION   = '��������';
  SC_TASK_STATE_ERROR_CAPTION      = '������';

  SC_TASK_STATE_REPORT_CREATED    = '������ �������.';
  SC_TASK_STATE_REPORT_PROCESSING = '������ ��������.';
  SC_TASK_STATE_REPORT_FINISHED   = '������ ���������.';
  SC_TASK_STATE_REPORT_CANCELED   = '���������� ������ ��������.';
  {TODO 2 -oVasilevSM : ���������� �������, ��� �� ������. }
  SC_TASK_STATE_REPORT_ERROR      = '��� ���������� ������ �������� ������.';

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
