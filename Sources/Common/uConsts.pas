unit uConsts;

interface

uses
  { VCL }
  Winapi.Messages,
  { Common }
  Common.uConsts;

const

  IC_MAX_RUNNING_THREAD_COUNT = 10;
  IC_MAX_DATA_PULLING_LENGTH  = 100;
  IC_MIN_POSTING_INTERVAL     = 30;

  WM_TASK_INSTANCE_CHANGED = WM_USER + 1000;
  WM_TASK_SEND_DATA        = WM_USER + 1001;

  DC_GOLDEN_SECTION: Double = 1.618;

  SC_MESSAGE_BOX_ERROR_CAPTION = '������';

  SC_TASK_STATE_CREATED_CAPTION    = '�������';
  SC_TASK_STATE_WAITING_CAPTION    = '� ��������';
  SC_TASK_STATE_PROCESSING_CAPTION = '�����������';
  SC_TASK_STATE_FINISHED_CAPTION   = '���������';
  SC_TASK_STATE_CANCELED_CAPTION   = '��������';
  SC_TASK_STATE_ERROR_CAPTION      = '������';

  SC_TASK_STATE_CREATED_REPORT    = '������ �������.';
  SC_TASK_STATE_WAITING_REPORT    = '������ ��������� � �������� �������.';
  SC_TASK_STATE_PROCESSING_REPORT = '���������� ������ ��������.';
  SC_TASK_STATE_FINISHED_REPORT   = '���������� ������ ���������.';
  SC_TASK_STATE_CANCELED_REPORT   = '���������� ������ ��������.';
  SC_TASK_STATE_ERROR_REPORT      = '��� ���������� ������ �������� ������.';

  SC_TASKS_COLUMN_0_CAPTION = '������';
  SC_TASKS_COLUMN_1_CAPTION = '��������';

  SC_TASKS_ITEMS_COLUMN_1_CAPTION = '������';
  SC_TASKS_ITEMS_COLUMN_2_CAPTION = '���������';
  SC_TASKS_ITEMS_COLUMN_3_CAPTION = '���������';
  SC_TASKS_ITEMS_COLUMN_4_CAPTION = '�������';
  SC_TASKS_ITEMS_COLUMN_5_CAPTION = '���������';

  SC_TASK_NAME_UNIQUE_ERROR       = '������ � ������ ''%s'' ��� ����������������. ������� ���������� ��� ������.';

  SC_GET_TASK_PARAMS_FORM_CAPTION = '������� ���������';
  SC_GET_TASK_PARAMS_FORM_TEXT    = '������� ��������� ������� ��������� ������.';

  SC_EMPTY_TASK_PARAMS_ERROR_MESSAGE =

      '������ � ���������� ������ IMKOTaskParams.ValidateParams. ���� �������� ������ �� �������� ���������, ������� ' +
      '������� ��������� �� ������ � �������� ��������� ������ _Params.ErrorMessage.';

  SC_TASK_EXECUTE_ERROR_MESSAGE = '��� ���������� ������ �������� ���������� %s: %s.';

  SC_TASK_SUMMARY = '����� ����� %d, �������� %d, ������� ��������� %d.';

implementation

end.
