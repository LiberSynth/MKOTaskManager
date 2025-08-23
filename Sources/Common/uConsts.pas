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

  SC_MESSAGE_BOX_ERROR_CAPTION = 'Ошибка';

  SC_TASK_STATE_CREATED_CAPTION    = 'Создана';
  SC_TASK_STATE_PROCESSING_CAPTION = 'Выполняется';
  SC_TASK_STATE_FINISHED_CAPTION   = 'Завершена';
  SC_TASK_STATE_CANCELED_CAPTION   = 'Прервана';
  SC_TASK_STATE_ERROR_CAPTION      = 'Ошибка';

  SC_TASK_STATE_REPORT_CREATED    = 'Задача создана.';
  SC_TASK_STATE_REPORT_PROCESSING = 'Задача запущена.';
  SC_TASK_STATE_REPORT_FINISHED   = 'Задача завершена.';
  SC_TASK_STATE_REPORT_CANCELED   = 'Выполнение задачи прервано.';
  {TODO 2 -oVasilevSM : Желательно вернуть, что за ошибка. }
  SC_TASK_STATE_REPORT_ERROR      = 'При выполнении задачи возникла ошибка.';

  SC_TASKS_COLUMN_0_CAPTION = 'Задача';
  SC_TASKS_COLUMN_1_CAPTION = 'Описание';

  SC_TASKS_ITEMS_COLUMN_0_CAPTION = 'Задача';
  SC_TASKS_ITEMS_COLUMN_1_CAPTION = 'Параметры';
  SC_TASKS_ITEMS_COLUMN_2_CAPTION = 'Состояние';
  SC_TASKS_ITEMS_COLUMN_3_CAPTION = 'Создана';

  SC_TASK_NAME_UNIQUE_ERROR       = 'Задача с именем ''%s'' уже зарегистрирована. Укажите уникальное имя задачи.';

  SC_GET_TASK_PARAMS_FORM_CAPTION = 'Укажите параметры';
  SC_GET_TASK_PARAMS_FORM_TEXT    = 'Укажите параметры запуска выбранной задачи.';

  SC_EMPTY_TASK_PARAMS_ERROR_MESSAGE =

      'Ошибка в исполнении метода IMKOTaskParams.ValidateParams. Если парамеры задачи не проходят валидацию, следует ' +
      'вернуть сообщение об ошибке в свойстве параметра метода _Params.ErrorMessage.';

implementation

end.
