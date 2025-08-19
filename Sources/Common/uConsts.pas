unit uConsts;

interface

uses
  { Common }
  Common.uConsts;

const

  DC_GOLDEN_SECTION: Double = 1.618;

  SC_TASK_ITEM_STATE_CREATED_CAPTION    = 'Создана';
  SC_TASK_ITEM_STATE_PROCESSING_CAPTION = 'Выполняется';
  SC_TASK_ITEM_STATE_FINISHED_CAPTION   = 'Завершена';
  SC_TASK_ITEM_STATE_CANCELED_CAPTION   = 'Прервана';
  SC_TASK_ITEM_STATE_ERROR_CAPTION      = 'Ошибка';

  SC_TASKS_COLUMN_0_CAPTION = 'Задача';
  SC_TASKS_COLUMN_1_CAPTION = 'Описание';

  SC_TASKS_ITEMS_COLUMN_0_CAPTION = 'Задача';
  SC_TASKS_ITEMS_COLUMN_1_CAPTION = 'Параметры';
  SC_TASKS_ITEMS_COLUMN_2_CAPTION = 'Состояние';
  SC_TASKS_ITEMS_COLUMN_3_CAPTION = 'Создана';

  SC_GET_TASK_PARAMS_FORM_CAPTION = 'Укажите параметры';
  SC_GET_TASK_PARAMS_FORM_TEXT    = 'Укажите параметры запуска выбранной задачи:' + CRLFx2 + '%s';


implementation

end.
