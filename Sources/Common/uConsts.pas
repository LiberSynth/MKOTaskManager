unit uConsts;

interface

uses
  { Common }
  Common.uConsts;

const

  DC_GOLDEN_SECTION: Double = 1.618;

  SC_MESSAGE_BOX_ERROR_CAPTION = 'Ошибка';

  SC_TASKS_COLUMN_0_CAPTION = 'Задача';
  SC_TASKS_COLUMN_1_CAPTION = 'Имя';
  SC_TASKS_COLUMN_2_CAPTION = 'Описание';

  SC_TASKS_ITEMS_COLUMN_1_CAPTION = 'Задача';
  SC_TASKS_ITEMS_COLUMN_2_CAPTION = 'Параметры';
  SC_TASKS_ITEMS_COLUMN_3_CAPTION = 'Состояние';
  SC_TASKS_ITEMS_COLUMN_4_CAPTION = 'Создана';
  SC_TASKS_ITEMS_COLUMN_5_CAPTION = 'Завершена';

  SC_GET_TASK_PARAMS_FORM_CAPTION = 'Укажите параметры';
  SC_GET_TASK_PARAMS_FORM_TEXT    = 'Укажите параметры запуска выбранной задачи.';

  SC_EMPTY_TASK_PARAMS_ERROR_MESSAGE =

      'Ошибка в исполнении метода IMKOTaskParams.ValidateParams. Если парамеры задачи не проходят валидацию, следует ' +
      'вернуть сообщение об ошибке в свойстве параметра метода _Params.ErrorMessage.';

implementation

end.
