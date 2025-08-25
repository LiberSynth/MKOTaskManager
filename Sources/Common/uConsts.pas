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

  SC_MESSAGE_BOX_ERROR_CAPTION = 'Ошибка';

  SC_TASK_STATE_CREATED_CAPTION    = 'Создана';
  SC_TASK_STATE_WAITING_CAPTION    = 'В ожидании';
  SC_TASK_STATE_PROCESSING_CAPTION = 'Выполняется';
  SC_TASK_STATE_FINISHED_CAPTION   = 'Завершена';
  SC_TASK_STATE_CANCELED_CAPTION   = 'Прервана';
  SC_TASK_STATE_ERROR_CAPTION      = 'Ошибка';

  SC_TASK_STATE_CREATED_REPORT    = 'Задача создана.';
  SC_TASK_STATE_WAITING_REPORT    = 'Задача находится в ожидании запуска.';
  SC_TASK_STATE_PROCESSING_REPORT = 'Выполнение задачи запущено.';
  SC_TASK_STATE_FINISHED_REPORT   = 'Выполнение задачи завершено.';
  SC_TASK_STATE_CANCELED_REPORT   = 'Выполнение задачи прервано.';
  SC_TASK_STATE_ERROR_REPORT      = 'При выполнении задачи возникла ошибка.';

  SC_TASKS_COLUMN_0_CAPTION = 'Задача';
  SC_TASKS_COLUMN_1_CAPTION = 'Описание';

  SC_TASKS_ITEMS_COLUMN_1_CAPTION = 'Задача';
  SC_TASKS_ITEMS_COLUMN_2_CAPTION = 'Параметры';
  SC_TASKS_ITEMS_COLUMN_3_CAPTION = 'Состояние';
  SC_TASKS_ITEMS_COLUMN_4_CAPTION = 'Создана';
  SC_TASKS_ITEMS_COLUMN_5_CAPTION = 'Завершена';

  SC_TASK_NAME_UNIQUE_ERROR       = 'Задача с именем ''%s'' уже зарегистрирована. Укажите уникальное имя задачи.';

  SC_GET_TASK_PARAMS_FORM_CAPTION = 'Укажите параметры';
  SC_GET_TASK_PARAMS_FORM_TEXT    = 'Укажите параметры запуска выбранной задачи.';

  SC_EMPTY_TASK_PARAMS_ERROR_MESSAGE =

      'Ошибка в исполнении метода IMKOTaskParams.ValidateParams. Если парамеры задачи не проходят валидацию, следует ' +
      'вернуть сообщение об ошибке в свойстве параметра метода _Params.ErrorMessage.';

  SC_TASK_EXECUTE_ERROR_MESSAGE = 'При выполнении задачи возникло исключение %s: %s.';

  SC_TASK_SUMMARY = 'Всего задач %d, запущено %d, успешно завершено %d.';

implementation

end.
