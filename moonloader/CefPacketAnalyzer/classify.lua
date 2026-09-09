-- Классификация и анализ CEF-пакетов
-- База знаний по событиям интерфейса Radmir CRMP + автоанализ произвольных пакетов.
local M = {}

-- Строки-литералы движка в CP1251: база знаний и описания переводятся в UTF-8
-- ниже по файлу через require enc_utils (после объявления таблиц).

-- Человекопонятные названия служебных пакетов RakNet/клиента (для колонки "ID")
M.pktIdName = {
    [0]  = "ConnectedPing",
    [1]  = "UnconnectedPing",
    [3]  = "ConnectedPong",
    [5]  = "ConnectionRequest",
    [6]  = "ConnectionRequestAccepted",
    [8]  = "NewIncomingConnection",
    [9]  = "DisconnectionNotification",
    [10] = "IncompatibleProtocol",
    [16] = "AlreadyConnected",
    [17] = "ConnectionAttemptFailed",
    [18] = "Синхронизация игрока",
    [19] = "Синхронизация игрока (ugm)",
    [20] = "Синхронизация автомобиля",
    [21] = "Синхронизация автомобиля (ugm)",
    [22] = "Синхронизация пешехода (RPC)",
    [32] = "Служебный код клиента",
    [33] = "Служебный код клиента",
    [34] = "Служебный код клиента",
    [35] = "Служебный код клиента",
    [61] = "Диалог (показ окна)",
    [62] = "Ответ на диалог",
    [200] = "Команда игрока",
    [207] = "Ping",
    [215] = "CEF-пакет (команды интерфейса)",
}

-- Базовое описание смысла id (для колонки "что это")
M.pktIdWhat = {
    [0]  = "Служебный пинг соединения RakNet.",
    [1]  = "Служебный пинг без подключения (поиск сервера).",
    [3]  = "Ответный пинг соединения.",
    [5]  = "Запрос на установку соединения.",
    [6]  = "Запрос на соединение принят сервером.",
    [8]  = "Первый пакет входящего соединения (handshake клиента).",
    [9]  = "Уведомление об отключении (штатный выход).",
    [16] = "Клиент уже подключён.",
    [17] = "Попытка соединения не удалась.",
    [18] = "Поток состояния и позиции игрока (движение/поворот).",
    [19] = "Поток состояния игрока в формате UGM.",
    [20] = "Поток состояния автомобиля.",
    [21] = "Поток состояния автомобиля в формате UGM.",
    [32] = "Служебный код клиента (бродкаст/команды мира Радмира).",
    [33] = "Служебный код клиента (мир/коннект).",
    [34] = "Служебный код клиента.",
    [35] = "Служебный код клиента.",
    [61] = "Сервер показывает классическое окно диалога SAMP.",
    [62] = "Игрок отправил ответ/выбрал пункт диалога.",
    [200] = "Отправка команды с косой черты на сервер.",
    [207] = "Пакет пинга.",
    [215] = "CEF-пакет: сервер передаёт команды и данные интерфейса (окна, текст, события UI).",
}

-- Описания категорий: что это за группа пакетов и для чего нужна
M.catMeta = {
    login    = { title = "Авторизация и вход",      desc = "Пакеты окна входа: логин, пароль, данные персонажа, ошибки входа. Возникают после подключения, до входа в мир." },
    load     = { title = "Загрузка и коннект",      desc = "Экраны загрузки, очередь ожидания, сообщения о подключении. Возникают при входе на сервер и переподключении." },
    spawn    = { title = "Выбор спавна",            desc = "Окно выбора точки появления персонажа после авторизации." },
    menu     = { title = "Меню паузы и интерфейса", desc = "ESC-меню, главное меню, переключение режимов интерфейса." },
    world    = { title = "События игрового мира",   desc = "Появление в мире, смена ника, статусы подключения, смерть, спавн." },
    dialog   = { title = "Диалоги и окна",          desc = "Показ/закрытие окон и диалогов, игровые тексты, ошибки в окнах." },
    queue    = { title = "Очередь ожидания",        desc = "Данные позиции в очереди на сервер и времени ожидания." },
    limit    = { title = "Лимиты и ограничения",    desc = "Лимит попыток входа, античит, кик, бан, блокировки." },
    error    = { title = "Ошибки и предупреждения", desc = "Неверный пароль, лимиты, запреты, служебные сообщения об ошибках." },
    inv      = { title = "Инвентарь и предметы",    desc = "Окно инвентаря, предметы, вес, использование и обмен вещей." },
    money    = { title = "Банк и деньги",           desc = "Деньги, банк, переводы, зарплаты, налоги." },
    shop     = { title = "Магазины и покупки",      desc = "Магазины, рынок, автосалоны, оружейки, покупка/продажа." },
    donate   = { title = "VIP и донат",             desc = "Привилегии VIP, донат-магазин, активация привилегий." },
    vehicle  = { title = "Транспорт и гаражи",      desc = "Автомобили, гаражи, топливо, тюнинг, автосалоны." },
    house    = { title = "Недвижимость",            desc = "Дома, бизнесы, аренда, риелторы." },
    job      = { title = "Работа и фракции",        desc = "Работы, фракции, организации, гос.структуры." },
    police   = { title = "Полиция и розыск",        desc = "Полиция, розыск, тюрьма, штрафы." },
    medic    = { title = "Медицина",                desc = "Больница, лечение, аптеки, медикаменты." },
    phone    = { title = "Телефон и связь",         desc = "Телефон, звонки, SMS, мессенджер." },
    social   = { title = "Соцсети и сообщества",    desc = "VK, дискорд, социальные сервисы клиента." },
    pet      = { title = "Питомцы",                 desc = "Собаки, кошки, еноты и другие питомцы." },
    map      = { title = "Карта и GPS",             desc = "Карта, навигация, маршруты, локации." },
    hud      = { title = "HUD и справка",           desc = "Спидометр, здоровье, броня, статусы интерфейса." },
    event    = { title = "Ивенты и мини-игры",      desc = "Ивенты, мини-игры, праздничные активности." },
    casino   = { title = "Казино и азарт",          desc = "Казино, букмекеры, азартные игры." },
    media    = { title = "Медиа и развлечения",     desc = "Музыка, радио, видео, стримы." },
    settings = { title = "Настройки",               desc = "Настройки клиента, звук, управление." },
    html     = { title = "HTML-контент",            desc = "Сырой HTML/страница, загружаемая в окно интерфейса." },
    service  = { title = "Служебный поток",         desc = "Поток соединения и синхронизации, не связан с UI." },
    unknown  = { title = "Не распознано",           desc = "Пакет, который не удалось сопоставить с известными событиями." },
}

-- База знаний событий интерфейса.
-- fist = строка поиска; locase = искать в нижнем регистре (для латиницы);
-- cat = категория; title = краткий заголовок;
-- what = что это и что делает; why = зачем нужно; phase = подсказка по фазе игры.
M.kb = {
    -- ===== Авторизация =====
    { kw = "Authorization",        locase = true, cat = "login", title = "Окно авторизации",
      what = "Сервер требует показать окно входа: клиент открывает форму с полем логина/пароля и данными персонажа (ник, координаты окна).",
      why = "Первый этап входа на сервер: ввод учётных данных и загрузка персонажа.",
      phase = "login" },
    { kw = "OnAuthorizationStart", locase = true, cat = "login", title = "Старт авторизации",
      what = "Клиент начинает процесс авторизации персонажа и загрузку его данных.",
      why = "Переход от подключения к игровому процессу через авторизацию.",
      phase = "login" },
    { kw = "auth",                 locase = true, cat = "login", title = "Данные авторизации",
      what = "JSON с данными формы входа: ник персонажа, координаты и размеры окна.",
      why = "Позиционирует окно входа и передаёт ник для дальнейшего входа.",
      phase = "login" },
    { kw = "password",             locase = true, cat = "login", title = "Поле пароля",
      what = "Команда показать/активировать поле ввода пароля в окне входа.",
      why = "Игрок вводит пароль аккаунта для авторизации.",
      phase = "login" },
    { kw = "неверный пароль",      cat = "error",  title = "Ошибка пароля",
      what = "Сервер сообщает, что введён неверный пароль, и просит ввести его заново.",
      why = "Защита аккаунта: повторный ввод пароля при ошибочном значении.",
      phase = "login" },
    { kw = "неправильный пароль",  cat = "error",  title = "Ошибка пароля",
      what = "Сервер сообщает, что введён неверный пароль.",
      why = "Защита аккаунта от подбора пароля.",
      phase = "login" },
    { kw = "login",                locase = true, cat = "login", title = "Логин",
      what = "Пакет, связанный с логином игрока на сервер.",
      why = "Участвует в процессе входа на сервер.",
      phase = "login" },

    -- ===== Вход в мир / персонаж =====
    { kw = "setPlayerNickName",    locase = true, cat = "world", title = "Установка ника",
      what = "Клиент выставляет ник игрока; фактически сигнал, что персонаж вошёл в мир.",
      why = "Фиксирует вход в игру: после него интерфейс входа закрывается.",
      phase = "in_world" },
    { kw = "setPlayerConnectedStatus", locase = true, cat = "world", title = "Статус подключения",
      what = "Клиент меняет статус подключения игрока (вошёл/вышел из мира).",
      why = "Синхронизация состояния подключения в интерфейсе и мире.",
      phase = "in_world" },
    { kw = "OnPlayerSpawn",        locase = true, cat = "world", title = "Спавн игрока",
      what = "Игрок появился в мире (спавн после выбора точки или респаун).",
      why = "Начало управления персонажем в мире.",
      phase = "in_world" },
    { kw = "OnPlayerDeath",        locase = true, cat = "world", title = "Смерть игрока",
      what = "Событие смерти персонажа: показ окна о смерти и возрождения.",
      why = "Обработка смерти и переход к повторному спавну.",
      phase = "in_world" },
    { kw = "OnPlayerConnect",      locase = true, cat = "world", title = "Подключение игрока",
      what = "Сообщение о подключении нового/текущего игрока к миру.",
      why = "Синхронизация списка игроков и интерфейса.",
      phase = "in_world" },
    { kw = "OnPlayerDisconnect",   locase = true, cat = "world", title = "Отключение игрока",
      what = "Сообщение об отключении игрока от мира.",
      why = "Обновление списка игроков и интерфейса.",
      phase = "in_world" },
    { kw = "вошли в игру",         cat = "world", title = "Вход в игру",
      what = "Игрок успешно вошёл в мир.",
      why = "Фиксация успешного входа.",
      phase = "in_world" },
    { kw = "добро пожаловать",     cat = "world", title = "Приветствие",
      what = "Приветственное сообщение после входа в мир.",
      why = "Информирование игрока об успешном входе.",
      phase = "in_world" },

    -- ===== Меню паузы =====
    { kw = "OnPlayerOpenMenuPause",  locase = true, cat = "menu", title = "Открытие меню паузы",
      what = "Клиент открывает паузу-меню (ESC): профиль, настройки, выход.",
      why = "Доступ к меню игры и управлению сессией.",
      phase = "in_world" },
    { kw = "OnPlayerCloseMenuPause", locase = true, cat = "menu", title = "Закрытие меню паузы",
      what = "Клиент закрывает паузу-меню и возвращается в игру.",
      why = "Завершение работы с меню паузы.",
      phase = "in_world" },
    { kw = "MenuPause",              locase = true, cat = "menu", title = "Пауза-меню",
      what = "Пакет, связанный с меню паузы интерфейса.",
      why = "Обслуживание меню паузы.",
      phase = "in_world" },

    -- ===== Выбор спавна =====
    { kw = "SelectSpawn",         locase = true, cat = "spawn", title = "Окно выбора спавна",
      what = "Сервер открывает окно выбора точки появления персонажа.",
      why = "Игрок выбирает, где появиться после авторизации.",
      phase = "spawn_select" },
    { kw = "спавн",               cat = "spawn", title = "Выбор спавна",
      what = "Пакет с данными выбора точки спавна.",
      why = "Обработка выбора локации появления.",
      phase = "spawn_select" },

    -- ===== Диалоги, окна, игровые тексты =====
    { kw = "Dialog",              locase = true, cat = "dialog", title = "Диалог",
      what = "Показ диалогового окна с текстом и кнопками выбора.",
      why = "Выбор действий игроком в диалогах.",
      phase = "unknown" },
    { kw = "ShowDialog",          locase = true, cat = "dialog", title = "Показ диалога",
      what = "Команда показать диалоговое окно.",
      why = "Выдача игроку выбора действий.",
      phase = "unknown" },
    { kw = "CloseDialog",         locase = true, cat = "dialog", title = "Закрытие диалога",
      what = "Закрытие диалогового окна.",
      why = "Завершение диалога.",
      phase = "unknown" },
    { kw = "CloseWindow",         locase = true, cat = "dialog", title = "Закрытие окна",
      what = "Клиент закрывает окно интерфейса.",
      why = "Управление видимостью окон.",
      phase = "unknown" },
    { kw = "GameText",            locase = true, cat = "dialog", title = "Игровой текст",
      what = "Отображение крупного игрового текста на экране (например, Loading).",
      why = "Информирование игрока о состоянии игры.",
      phase = "unknown" },
    { kw = "setError",            locase = true, cat = "error", title = "Ошибка в окне",
      what = "Клиент показывает ошибку внутри окна интерфейса.",
      why = "Предупреждение игрока об ошибке.",
      phase = "unknown" },
    { kw = "OnDialogResponse",    locase = true, cat = "dialog", title = "Ответ диалога",
      what = "Игрок ответил на пункт диалога.",
      why = "Обработка выбора игрока.",
      phase = "unknown" },

    -- ===== Загрузка =====
    { kw = "Loading",             locase = true, cat = "load", title = "Экран загрузки",
      what = "Показ экрана загрузки мира и данных персонажа.",
      why = "Ожидание загрузки ресурсов перед входом в мир.",
      phase = "loading" },
    { kw = "Loading3000",         locase = true, cat = "load", title = "Экран загрузки (статичный)",
      what = "Статичный экран загрузки с таймером.",
      why = "Информация о процессе загрузки.",
      phase = "loading" },
    { kw = "загрузка",            cat = "load", title = "Загрузка",
      what = "Пакет, связанный с загрузкой данных/мира.",
      why = "Обслуживание процесса загрузки.",
      phase = "loading" },

    -- ===== Очередь =====
    { kw = "position in queue",   locase = true, cat = "queue", title = "Позиция в очереди",
      what = "Сервер сообщает позицию игрока в очереди ожидания входа.",
      why = "Ограничение нагрузки: пропуск игроков по очереди.",
      phase = "load" },
    { kw = "queue",               locase = true, cat = "queue", title = "Очередь ожидания",
      what = "Данные очереди на вход на сервер.",
      why = "Информирование о позиции и времени ожидания.",
      phase = "load" },
    { kw = "очередь",             cat = "queue", title = "Очередь ожидания",
      what = "Данные очереди на вход.",
      why = "Информирование о позиции в очереди.",
      phase = "load" },
    { kw = "estimated time",      locase = true, cat = "queue", title = "Время ожидания",
      what = "Расчётное время до входа в игру.",
      why = "Оценка времени ожидания в очереди.",
      phase = "load" },

    -- ===== Лимиты, античит, бан =====
    { kw = "limit attempts",      locase = true, cat = "limit", title = "Лимит попыток",
      what = "Сервер исчерпан лимит попыток входа, клиент показывает предупреждение.",
      why = "Защита от подбора пароля и перебора попыток.",
      phase = "login" },
    { kw = "too many attempts",   locase = true, cat = "limit", title = "Слишком много попыток",
      what = "Превышено число попыток входа, вход временно блокируется.",
      why = "Защита от автоматического подбора пароля.",
      phase = "login" },
    { kw = "попытки входа",       cat = "limit", title = "Лимит попыток входа",
      what = "Ограничение числа попыток входа.",
      why = "Защита от подбора пароля.",
      phase = "login" },
    { kw = "time limit",          locase = true, cat = "limit", title = "Лимит времени",
      what = "Истекло время ожидания/лимит на вход.",
      why = "Ограничение времени на выполнение действия.",
      phase = "login" },
    { kw = "anticheat",           locase = true, cat = "limit", title = "Античит",
      what = "Клиент предупреждает о работе анти-чита.",
      why = "Защита от чит-программ.",
      phase = "unknown" },
    { kw = "anti-cheat",          locase = true, cat = "limit", title = "Анти-чит",
      what = "Сообщение анти-чита.",
      why = "Защита от чит-программ.",
      phase = "unknown" },
    { kw = "бан",                 cat = "limit", title = "Бан",
      what = "Игрок заблокирован на сервере.",
      why = "Наказание за нарушение правил.",
      phase = "unknown" },
    { kw = "banned",              locase = true, cat = "limit", title = "Бан",
      what = "Сообщение о блокировке учётной записи.",
      why = "Ограничение доступа нарушителю.",
      phase = "unknown" },
    { kw = "заблокирован",        cat = "limit", title = "Блокировка",
      what = "Учётная запись заблокирована.",
      why = "Ограничение доступа.",
      phase = "unknown" },
    { kw = "кик",                 cat = "limit", title = "Кик",
      what = "Игрок отключён от сервера.",
      why = "Принудительное отключение.",
      phase = "unknown" },
    { kw = "kicked",              locase = true, cat = "limit", title = "Кик",
      what = "Сообщение об отключении игрока.",
      why = "Принудительное отключение.",
      phase = "unknown" },
    { kw = "waiting",             locase = true, cat = "limit", title = "Ожидание",
      what = "Сервер переводит клиент в режим ожидания.",
      why = "Регулировка нагрузки на сервер.",
      phase = "load" },

    -- ===== Инвентарь =====
    { kw = "Inventory",           locase = true, cat = "inv", title = "Инвентарь",
      what = "Открытие окна инвентаря: предметы, вес, использование.",
      why = "Управление предметами персонажа.",
      phase = "in_world" },
    { kw = "инвентарь",           cat = "inv", title = "Инвентарь",
      what = "Пакет с данными инвентаря.",
      why = "Управление предметами.",
      phase = "in_world" },
    { kw = "UseItem",             locase = true, cat = "inv", title = "Использование предмета",
      what = "Игрок использует предмет из инвентаря.",
      why = "Применение эффекта предмета.",
      phase = "in_world" },
    { kw = "предмет",             cat = "inv", title = "Предмет",
      what = "Пакет с данными предмета.",
      why = "Работа с предметами инвентаря.",
      phase = "in_world" },
    { kw = "вес",                 cat = "inv", title = "Вес",
      what = "Данные о весе инвентаря.",
      why = "Ограничение переносимых предметов.",
      phase = "in_world" },

    -- ===== Деньги / банк =====
    { kw = "bank",                locase = true, cat = "money", title = "Банк",
      what = "Окно банка: баланс, счета, вклады.",
      why = "Хранение и операции с деньгами.",
      phase = "in_world" },
    { kw = "банк",                cat = "money", title = "Банк",
      what = "Пакет банковских операций.",
      why = "Операции с деньгами.",
      phase = "in_world" },
    { kw = "деньги",              cat = "money", title = "Деньги",
      what = "Обновление баланса денег.",
      why = "Отображение средств.",
      phase = "in_world" },
    { kw = "money",               locase = true, cat = "money", title = "Деньги",
      what = "Обновление баланса.",
      why = "Отображение средств.",
      phase = "in_world" },

    -- ===== Магазины =====
    { kw = "shop",                locase = true, cat = "shop", title = "Магазин",
      what = "Окно магазина: список товаров, покупка.",
      why = "Покупка игровых товаров.",
      phase = "in_world" },
    { kw = "магазин",             cat = "shop", title = "Магазин",
      what = "Пакет магазина.",
      why = "Покупка товаров.",
      phase = "in_world" },
    { kw = "покуп",               cat = "shop", title = "Покупка",
      what = "Совершение покупки.",
      why = "Приобретение товаров.",
      phase = "in_world" },
    { kw = "buy",                 locase = true, cat = "shop", title = "Покупка",
      what = "Команда покупки товара.",
      why = "Приобретение товаров.",
      phase = "in_world" },
    { kw = "Market",              locase = true, cat = "shop", title = "Рынок",
      what = "Окно рынка товаров.",
      why = "Торговля предметами.",
      phase = "in_world" },
    { kw = "рынок",               cat = "shop", title = "Рынок",
      what = "Пакет рынка.",
      why = "Торговля предметами.",
      phase = "in_world" },
    { kw = "WeaponShop",          locase = true, cat = "shop", title = "Магазин оружия",
      what = "Окно магазина оружия.",
      why = "Покупка оружия.",
      phase = "in_world" },
    { kw = "оружи",               cat = "shop", title = "Оружие",
      what = "Пакет с данными оружия.",
      why = "Покупка/продажа оружия.",
      phase = "in_world" },

    -- ===== VIP / донат =====
    { kw = "vip",                 locase = true, cat = "donate", title = "VIP",
      what = "Окно VIP-привилегий: статус, активация.",
      why = "Управление привилегиями игрока.",
      phase = "in_world" },
    { kw = "донат",               cat = "donate", title = "Донат",
      what = "Пакет донат-магазина.",
      why = "Покупка привилегий.",
      phase = "in_world" },
    { kw = "donate",              locase = true, cat = "donate", title = "Донат",
      what = "Окно доната.",
      why = "Покупка привилегий.",
      phase = "in_world" },

    -- ===== Транспорт =====
    { kw = "vehicle",             locase = true, cat = "vehicle", title = "Автомобиль",
      what = "Данные автомобиля: состояние, параметры.",
      why = "Управление транспортом.",
      phase = "in_world" },
    { kw = "машина",              cat = "vehicle", title = "Машина",
      what = "Пакет автомобиля.",
      why = "Управление транспортом.",
      phase = "in_world" },
    { kw = "топлив",              cat = "vehicle", title = "Топливо",
      what = "Данные о топливе.",
      why = "Расчёт запаса хода.",
      phase = "in_world" },
    { kw = "fuel",                locase = true, cat = "vehicle", title = "Топливо",
      what = "Данные о топливе.",
      why = "Расчёт запаса хода.",
      phase = "in_world" },
    { kw = "гараж",               cat = "vehicle", title = "Гараж",
      what = "Окно гаража: хранение и ремонт машин.",
      why = "Хранение транспорта.",
      phase = "in_world" },
    { kw = "Garage",              locase = true, cat = "vehicle", title = "Гараж",
      what = "Окно гаража.",
      why = "Хранение транспорта.",
      phase = "in_world" },
    { kw = "автосалон",           cat = "vehicle", title = "Автосалон",
      what = "Окно автосалона: покупка машин.",
      why = "Приобретение транспорта.",
      phase = "in_world" },
    { kw = "Autosalon",           locase = true, cat = "vehicle", title = "Автосалон",
      what = "Окно автосалона.",
      why = "Приобретение транспорта.",
      phase = "in_world" },
    { kw = "тюнинг",              cat = "vehicle", title = "Тюнинг",
      what = "Тюнинг автомобиля.",
      why = "Улучшение характеристик/вида машины.",
      phase = "in_world" },

    -- ===== Недвижимость =====
    { kw = "house",               locase = true, cat = "house", title = "Дом",
      what = "Данные дома/недвижимости.",
      why = "Управление недвижимостью.",
      phase = "in_world" },
    { kw = "дом",                 cat = "house", title = "Дом",
      what = "Пакет недвижимости.",
      why = "Управление недвижимостью.",
      phase = "in_world" },
    { kw = "недвижимость",        cat = "house", title = "Недвижимость",
      what = "Окно недвижимости.",
      why = "Покупка/продажа недвижимости.",
      phase = "in_world" },
    { kw = "Realtor",             locase = true, cat = "house", title = "Риелтор",
      what = "Окно риелтора.",
      why = "Покупка/аренда недвижимости.",
      phase = "in_world" },
    { kw = "риелтор",             cat = "house", title = "Риелтор",
      what = "Пакет риелтора.",
      why = "Покупка/аренда недвижимости.",
      phase = "in_world" },
    { kw = "аренда",              cat = "house", title = "Аренда",
      what = "Аренда недвижимости.",
      why = "Временное использование объекта.",
      phase = "in_world" },

    -- ===== Работа / фракции =====
    { kw = "job",                 locase = true, cat = "job", title = "Работа",
      what = "Окно работы: выбор и смена профессии.",
      why = "Выбор способа заработка.",
      phase = "in_world" },
    { kw = "работа",              cat = "job", title = "Работа",
      what = "Пакет работы.",
      why = "Выбор профессии.",
      phase = "in_world" },
    { kw = "фракц",               cat = "job", title = "Фракция",
      what = "Данные фракции/организации.",
      why = "Управление фракционной жизнью.",
      phase = "in_world" },
    { kw = "fraction",            locase = true, cat = "job", title = "Фракция",
      what = "Данные фракции.",
      why = "Управление фракцией.",
      phase = "in_world" },
    { kw = "лидер",               cat = "job", title = "Лидер",
      what = "Данные лидера организации.",
      why = "Взаимодействие руководства фракции.",
      phase = "in_world" },

    -- ===== Полиция =====
    { kw = "police",              locase = true, cat = "police", title = "Полиция",
      what = "Данные полиции: вызовы, розыск.",
      why = "Органы правопорядка.",
      phase = "in_world" },
    { kw = "полиц",               cat = "police", title = "Полиция",
      what = "Пакет полиции.",
      why = "Органы правопорядка.",
      phase = "in_world" },
    { kw = "розыск",              cat = "police", title = "Розыск",
      what = "Окно розыска.",
      why = "Поиск преступников.",
      phase = "in_world" },
    { kw = "тюрьм",               cat = "police", title = "Тюрьма",
      what = "Данные тюремного заключения.",
      why = "Отбывание наказания.",
      phase = "in_world" },
    { kw = "штраф",               cat = "police", title = "Штраф",
      what = "Выписанный штраф.",
      why = "Наказание за нарушение.",
      phase = "in_world" },
    { kw = "fine",                locase = true, cat = "police", title = "Штраф",
      what = "Данные штрафа.",
      why = "Наказание за нарушение.",
      phase = "in_world" },
    { kw = "wanted",              locase = true, cat = "police", title = "Розыск (wanted)",
      what = "Данные розыска игрока.",
      why = "Отслеживание преступников.",
      phase = "in_world" },

    -- ===== Медицина =====
    { kw = "hospital",            locase = true, cat = "medic", title = "Больница",
      what = "Окно больницы: лечение.",
      why = "Восстановление здоровья.",
      phase = "in_world" },
    { kw = "больниц",             cat = "medic", title = "Больница",
      what = "Пакет больницы.",
      why = "Лечение.",
      phase = "in_world" },
    { kw = "медик",               cat = "medic", title = "Медик",
      what = "Данные медика.",
      why = "Оказание медпомощи.",
      phase = "in_world" },
    { kw = "аптек",               cat = "medic", title = "Аптека",
      what = "Окно аптеки.",
      why = "Покупка лекарств.",
      phase = "in_world" },
    { kw = "лечен",               cat = "medic", title = "Лечение",
      what = "Процесс лечения.",
      why = "Восстановление здоровья.",
      phase = "in_world" },

    -- ===== Телефон =====
    { kw = "phone",               locase = true, cat = "phone", title = "Телефон",
      what = "Интерфейс телефона: контакты, звонки.",
      why = "Связь между игроками.",
      phase = "in_world" },
    { kw = "телефон",             cat = "phone", title = "Телефон",
      what = "Пакет телефона.",
      why = "Связь между игроками.",
      phase = "in_world" },
    { kw = "sms",                 locase = true, cat = "phone", title = "SMS",
      what = "Сообщение SMS.",
      why = "Текстовая связь.",
      phase = "in_world" },
    { kw = "звонок",              cat = "phone", title = "Звонок",
      what = "Звонок игроку.",
      why = "Голосовая связь.",
      phase = "in_world" },
    { kw = "мсс",                 locase = false, cat = "phone", title = "Мессенджер",
      what = "Сообщение мессенджера.",
      why = "Связь между игроками.",
      phase = "in_world" },

    -- ===== Соцсети =====
    { kw = "vk",                  locase = true, cat = "social", title = "VK",
      what = "Интеграция с VK (авторизация, оповещения).",
      why = "Привязка аккаунта/оповещения.",
      phase = "unknown" },
    { kw = "вконтакте",           cat = "social", title = "ВКонтакте",
      what = "Интеграция с ВКонтакте.",
      why = "Привязка аккаунта.",
      phase = "unknown" },
    { kw = "discord",             locase = true, cat = "social", title = "Discord",
      what = "Интеграция с Discord.",
      why = "Привязка аккаунта.",
      phase = "unknown" },
    { kw = "соцсет",              cat = "social", title = "Соцсеть",
      what = "Социальный сервис клиента.",
      why = "Социальное взаимодействие.",
      phase = "unknown" },

    -- ===== Питомцы =====
    { kw = "pet",                 locase = true, cat = "pet", title = "Питомец",
      what = "Данные питомца.",
      why = "Управление питомцами.",
      phase = "in_world" },
    { kw = "питомец",             cat = "pet", title = "Питомец",
      what = "Пакет питомца.",
      why = "Управление питомцами.",
      phase = "in_world" },
    { kw = "собак",               cat = "pet", title = "Собака",
      what = "Данные собаки.",
      why = "Взаимодействие с собакой.",
      phase = "in_world" },
    { kw = "кошк",                cat = "pet", title = "Кошка",
      what = "Данные кошки.",
      why = "Взаимодействие с кошкой.",
      phase = "in_world" },
    { kw = "енот",                cat = "pet", title = "Енот",
      what = "Данные енота.",
      why = "Взаимодействие с енотом.",
      phase = "in_world" },

    -- ===== Карта / GPS =====
    { kw = "map",                 locase = true, cat = "map", title = "Карта",
      what = "Данные карты местности.",
      why = "Навигация по городу.",
      phase = "in_world" },
    { kw = "карта",               cat = "map", title = "Карта",
      what = "Пакет карты.",
      why = "Навигация.",
      phase = "in_world" },
    { kw = "gps",                 locase = true, cat = "map", title = "GPS",
      what = "Данные навигатора.",
      why = "Маршрут до точки.",
      phase = "in_world" },
    { kw = "навига",              cat = "map", title = "Навигация",
      what = "Пакет навигации.",
      why = "Построение маршрута.",
      phase = "in_world" },
    { kw = "маршрут",             cat = "map", title = "Маршрут",
      what = "Данные маршрута.",
      why = "Построение пути.",
      phase = "in_world" },

    -- ===== HUD =====
    { kw = "speedometer",         locase = true, cat = "hud", title = "Спидометр",
      what = "Данные спидометра (скорость, обороты).",
      why = "Отображение скорости.",
      phase = "in_world" },
    { kw = "спидометр",           cat = "hud", title = "Спидометр",
      what = "Пакет спидометра.",
      why = "Отображение скорости.",
      phase = "in_world" },
    { kw = "здоровье",            cat = "hud", title = "Здоровье",
      what = "Данные здоровья персонажа.",
      why = "Отображение HP.",
      phase = "in_world" },
    { kw = "брон",                cat = "hud", title = "Броня",
      what = "Данные брони.",
      why = "Отображение защиты.",
      phase = "in_world" },
    { kw = "hud",                 locase = true, cat = "hud", title = "HUD",
      what = "Обновление элементов интерфейса.",
      why = "Отображение статусов.",
      phase = "in_world" },

    -- ===== Ивенты / мини-игры =====
    { kw = "paintball",           locase = true, cat = "event", title = "Страйкбол",
      what = "Мини-игра страйкбол: подбор команд, раунды.",
      why = "Развлекательный ивент.",
      phase = "in_world" },
    { kw = "страйкбол",           cat = "event", title = "Страйкбол",
      what = "Пакет мини-игры.",
      why = "Развлечение.",
      phase = "in_world" },
    { kw = "event",               locase = true, cat = "event", title = "Ивент",
      what = "Данные ивента.",
      why = "Проведение события.",
      phase = "in_world" },
    { kw = "ивент",               cat = "event", title = "Ивент",
      what = "Пакет ивента.",
      why = "Проведение события.",
      phase = "in_world" },
    { kw = "helloween",           locase = true, cat = "event", title = "Хеллоуин",
      what = "Праздничный ивент Хеллоуин.",
      why = "Сезонное событие.",
      phase = "in_world" },
    { kw = "хеллоуин",            cat = "event", title = "Хеллоуин",
      what = "Пакет праздничного ивента.",
      why = "Сезонное событие.",
      phase = "in_world" },
    { kw = "новый год",           cat = "event", title = "Новый год",
      what = "Праздничный ивент Новый год.",
      why = "Сезонное событие.",
      phase = "in_world" },
    { kw = "новогод",             cat = "event", title = "Новогодний ивент",
      what = "Пакет новогоднего ивента.",
      why = "Сезонное событие.",
      phase = "in_world" },
    { kw = "охота",               cat = "event", title = "Охота",
      what = "Мини-игра охота.",
      why = "Развлечение.",
      phase = "in_world" },
    { kw = "мини-игра",           cat = "event", title = "Мини-игра",
      what = "Мини-игра.",
      why = "Развлечение.",
      phase = "in_world" },

    -- ===== Казино =====
    { kw = "casino",              locase = true, cat = "casino", title = "Казино",
      what = "Окно казино: ставки, автоматы.",
      why = "Азартные развлечения.",
      phase = "in_world" },
    { kw = "казино",              cat = "casino", title = "Казино",
      what = "Пакет казино.",
      why = "Азартные развлечения.",
      phase = "in_world" },
    { kw = "букмекер",            cat = "casino", title = "Букмекер",
      what = "Окно букмекера: ставки на спорт.",
      why = "Ставки.",
      phase = "in_world" },

    -- ===== Медиа =====
    { kw = "music",               locase = true, cat = "media", title = "Музыка",
      what = "Данные музыки: выбор треков.",
      why = "Музыкальный плеер.",
      phase = "in_world" },
    { kw = "музык",               cat = "media", title = "Музыка",
      what = "Пакет музыки.",
      why = "Плеер.",
      phase = "in_world" },
    { kw = "radio",               locase = true, cat = "media", title = "Радио",
      what = "Данные радио.",
      why = "Радиовещание в игре.",
      phase = "in_world" },
    { kw = "радио",               cat = "media", title = "Радио",
      what = "Пакет радио.",
      why = "Радио в машине.",
      phase = "in_world" },

    -- ===== Настройки =====
    { kw = "settings",            locase = true, cat = "settings", title = "Настройки",
      what = "Окно настроек клиента.",
      why = "Настройка под себя.",
      phase = "unknown" },
    { kw = "настрой",             cat = "settings", title = "Настройки",
      what = "Пакет настроек.",
      why = "Изменение настроек.",
      phase = "unknown" },
    { kw = "громкость",           cat = "settings", title = "Громкость",
      what = "Настройка громкости звука.",
      why = "Управление звуком.",
      phase = "unknown" },
}

-- Перевод базы знаний и описаний категорий из CP1251 (литералы движка) в UTF-8
local encUtils = require("CefPacketAnalyzer.enc_utils")
do
    for _, meta in pairs(M.catMeta) do
        meta.title = encUtils.bytesCpToUtf8(meta.title)
        meta.desc = encUtils.bytesCpToUtf8(meta.desc)
    end
    for _, e in ipairs(M.kb) do
        e.kw = encUtils.bytesCpToUtf8(e.kw)
        e.title = encUtils.bytesCpToUtf8(e.title)
        e.what = encUtils.bytesCpToUtf8(e.what)
        e.why = encUtils.bytesCpToUtf8(e.why)
        if e.phase then
            e.phase = encUtils.bytesCpToUtf8(e.phase)
        end
    end
    -- Те же ключевые слова, но в нижнем регистре, для поиска по латинице
    for _, e in ipairs(M.kb) do
        if e.locase then
            e.kwLow = e.kw:lower()
        end
    end
end

-- Вспомогательные функции для автоматического разбора тела пакета
local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Поиск всех читабельных токенов-идентификаторов вида CamelCase / событий
local function findTokens(text)
    local tokens = {}
    local seen = {}
    for w in tostring(text):gmatch("[A-Za-z_][A-Za-z0-9_]{2,}") do
        if not seen[w] then
            seen[w] = true
            table.insert(tokens, w)
        end
    end
    return tokens
end

-- Попытка разобрать JSON из фрагмента текста (ищем первую { и последнюю })
local function tryParseJson(text, wantKeys)
    local jsonOk, dkjson = pcall(require, "dkjson")
    if not jsonOk then
        return nil, {}
    end
    local s = tostring(text)
    local b = s:find("{", 1, true)
    if not b then return nil, {} end
    local e = s:find("}", b, true)
    if not e then return nil, {} end
    -- ищем максимально правую закрывающую скобку в пределах разумного
    for j = #s, e + 1, -1 do
        if s:sub(j, j) == "}" then e = j; break end
    end
    local frag = s:sub(b)
    if #frag > 20000 then frag = frag:sub(1, 20000) end
    local dec, pos, err = dkjson.decode(frag)
    local pairKeys = wantKeys or {}
    local pairsCnt = 0
    if dec then
        for k, v in pairs(dec) do
            if pairsCnt < 30 then
                table.insert(pairKeys, k .. "=" .. tostring(v))
            end
            pairsCnt = pairsCnt + 1
        end
        return dec, pairKeys
    end
    return nil, pairKeys
end

-- Примитивное разбиение на пары вида ключ: значение / key = value без JSON
local function tryExtractPairs(text)
    local pairsColl = {}
    local cnt = 0
    for k, v in tostring(text):gmatch('"'.."([%w_]+)"..'"%s*:%s*"([^"]*)"') do
        if cnt < 40 then
            table.insert(pairsColl, k .. "=" .. v)
        end
        cnt = cnt + 1
    end
    if cnt == 0 then
        for k, v in tostring(text):gmatch("([%w_]+)%s*[=%t:-]%s*([^%s,]*)") do
            if cnt < 40 then
                table.insert(pairsColl, k .. "=" .. v)
            end
            cnt = cnt + 1
        end
    end
    return pairsColl
end

-- Извлечение команд, адресов окон и данных из CEF-пакетов.
-- Работает по JSON-телу (если распознано) и как запасной вариант - по тексту.
local function extractCefFields(text, jsonData)
    local out = { cmd = nil, url = nil, win = nil, dataKeys = {}, nick = nil, fn = nil }

    if type(jsonData) == "table" then
        -- Команда/событие интерфейса (event, cmd, command, type, action, name)
        local cmdKeys = { "event", "cmd", "command", "type", "action", "name", "window" }
        for _, k in ipairs(cmdKeys) do
            for key, val in pairs(jsonData) do
                if not out.cmd and key:lower() == k and type(val) == "string" then
                    if val ~= "" then
                        out.cmd = val
                    end
                end
            end
        end
        -- Адрес окна/страницы (url, src, page, resource, link, iframe, path, uri)
        local urlKeys = { "url", "src", "page", "resource", "link", "iframe", "path", "uri" }
        for _, k in ipairs(urlKeys) do
            for key, val in pairs(jsonData) do
                if not out.url and key:lower() == k and type(val) == "string" then
                    local u = tostring(val):match("^[%w_]+://")
                    if u then
                        out.url = val
                    end
                end
            end
        end
        -- Ключи вспомогательных данных (data, args, params, body, payload)
        local dataKeys = { "data", "args", "params", "body", "payload" }
        for _, k in ipairs(dataKeys) do
            for key, val in pairs(jsonData) do
                if key:lower() == k and type(val) == "table" then
                    for sk in pairs(val) do
                        if #out.dataKeys < 24 then
                            table.insert(out.dataKeys, tostring(sk))
                        end
                    end
                end
            end
        end
        -- Параметры окна (window, windowSettings, size, pos, dimensions)
        local winKeys = { "window", "windowSettings", "size", "pos", "dimensions" }
        for _, k in ipairs(winKeys) do
            for key, val in pairs(jsonData) do
                if not out.win and key:lower() == k and type(val) == "table" then
                    local x = val.x or val.left
                    local y = val.y or val.top
                    local w = val.width or val.w
                    local h = val.height or val.h
                    if x or y or w or h then
                        out.win = { x = x, y = y, w = w, h = h }
                    end
                end
            end
        end
    end

    -- Запасной вариант: ищем URL прямо в тексте, если JSON не разобран
    if not out.url then
        local u = tostring(text):match("([%w_]+://[^%s\"']+)")
        if u then
            out.url = u
        end
    end

    -- Ник игрока: параметр авторизации в URL (username= и др.) либо поле JSON.
    -- На сервере Radmir ник приходит в окне входа как
    -- window.setActionRedirectUri('https://radmir.online/login?...&username=Ник...').
    local nickKeys = { "username", "nick", "login", "account", "user" }
    if not out.nick and type(jsonData) == "table" then
        -- Поиск ника в JSON: на верхнем уровне и внутри контейнеров data/args/params.
        local function scanForNick(tb)
            for key, val in pairs(tb) do
                local lk = key
                if type(lk) == "string" then
                    lk = lk:lower()
                end
                if not out.nick and type(lk) == "string" then
                    for _, nk in ipairs(nickKeys) do
                        if lk == nk and type(val) == "string" and val ~= "" then
                            out.nick = val
                        end
                    end
                end
            end
        end
        scanForNick(jsonData)
        if not out.nick then
            local dataKeys = { "data", "args", "params", "body", "payload" }
            for _, k in ipairs(dataKeys) do
                for key, val in pairs(jsonData) do
                    if type(key) == "string" and not out.nick and key:lower() == k and type(val) == "table" then
                        scanForNick(val)
                    end
                end
            end
        end
    end
    if not out.nick and out.url then
        local _, query = tostring(out.url):match("^([^?]*)%?(.*)$")
        if query then
            for k, v in query:gmatch("([%w%.%-_]+)=([^&%s\"']*)") do
                local lk = k:lower()
                for _, nk in ipairs(nickKeys) do
                    if not out.nick and lk == nk then
                        out.nick = v
                    end
                end
            end
        end
    end
    -- Ник также может приходить JS-вызовом window.setPlayerNickName('<ник>') —
    -- типичный входящий CEF-пакет RX 215 при входе в мир (пачка window.set*).
    -- Раньше отсюда ник не доставался, из-за чего gameNick оставался пустым
    -- и фоновая отправка агрегатов не стартовала.
    if not out.nick and type(text) == "string" then
        local _, jsNick = text:match(
            "setPlayerNickName%s*%(%s*([\"'])(.-)%1%s*%)"
        )
        if jsNick and jsNick ~= "" then
            out.nick = jsNick
        end
    end

    if out.nick then
        -- Разжимаем возможное URL-кодирование символов (проценты).
        out.nick = (out.nick:gsub("%%(%x%x)", function(h)
            return string.char(tonumber(h, 16))
        end))
        -- Убираем лишние пробелы вокруг ника.
        out.nick = (out.nick:gsub("^%s+", ""):gsub("%s+$", ""))
        if out.nick == "" then
            out.nick = nil
        end
    end

    -- Имя вызываемой JS-функции окна (window.setPlayerChatBubble, CefMenu... и т.п.)
    if not out.fn and type(text) == "string" then
        local fn = tostring(text):match("([%w_]+%.[%w_%._]*%s*%()")
        if fn then
            fn = (fn:gsub("%s*%($", ""))
            fn = (fn:gsub("^%s+", ""):gsub("%s+$", ""))
            if fn ~= "" then
                out.fn = fn
            end
        end
    end

    return out
end

-- Главная функция: классификация записи пакета
-- record: {id=..., text=...} ; возвращает таблицу с результатами анализа.
function M.classify(record)
    local text = record.text or ""
    local lowText = tostring(text):lower()
    local id = record.id
    local res = {
        category = "unknown",
        categoryTitle = M.catMeta.unknown.title,
        categoryDesc = M.catMeta.unknown.desc,
        title = "Не распознано",
        events = {},
        tokens = {},
        params = {},
        analysis = {},
        description = "",
        phaseHint = nil,
        pktName = M.pktIdName[id] or ("id=" .. tostring(id)),
        pktWhat = M.pktIdWhat[id] or "",
    }

    -- 1. Проверяем, что это HTML
    if tostring(text):find("<%s*[Hh][Tt][Mm][Ll]", 1) or tostring(text):find("<%s*[Bb][Oo][Dd][Yy]") then
        res.category = "html"
        res.categoryTitle = M.catMeta.html.title
        res.categoryDesc = M.catMeta.html.desc
        res.title = "HTML-контент страницы"
        res.description = "Пакет содержит сырую HTML-разметку страницы интерфейса."
        table.insert(res.analysis, "Найден HTML-контент.")
    end

    -- 2. Перебираем базу знаний
    local found = {}
    for _, entry in ipairs(M.kb) do
        local hay = entry.locase and lowText or tostring(text)
        local needle = entry.locase and entry.kwLow or entry.kw
        if hay:find(needle, 1, true) then
            table.insert(found, entry)
        end
    end

    -- Приоритет: берём первое совпадение в порядке базы (наиболее специфичное раньше)
    if #found > 0 then
        local primary = found[1]
        res.category = primary.cat
        res.categoryTitle = (M.catMeta[primary.cat] and M.catMeta[primary.cat].title) or primary.cat
        res.categoryDesc = (M.catMeta[primary.cat] and M.catMeta[primary.cat].desc) or ""
        res.title = primary.title
        res.description = primary.what
        res.phaseHint = primary.phase
        table.insert(res.analysis, "Событие: " .. primary.title .. ".")
        table.insert(res.analysis, "Назначение: " .. primary.why .. ".")
        local seen = {}
        for _, e in ipairs(found) do
            if not seen[e.title] then
                seen[e.title] = true
                table.insert(res.events, e.title)
            end
        end
    end

    -- 3. Автоанализ произвольных пакетов
    -- 3.1 JSON
    local wantJson = {}
    local jsonData = nil
    if (M.state == nil or M.state.parseJson) then
        jsonData, wantJson = tryParseJson(text, {})
    end
    if jsonData then
        table.insert(res.analysis, "Тело является JSON-объектом.")
        for _, p in ipairs(wantJson) do
            if #res.params < 24 then
                table.insert(res.params, p)
            end
        end
    else
        for _, p in ipairs(tryExtractPairs(text)) do
            if #res.params < 16 then
                table.insert(res.params, p)
            end
        end
    end

    -- 3.1б Извлечение команд/URL из CEF-пакетов
    local cef = extractCefFields(text, jsonData)
    res.cmd = cef.cmd
    res.url = cef.url
    res.win = cef.win
    res.dataKeys = cef.dataKeys
    res.nick = cef.nick
    res.fn = cef.fn
    if cef.cmd then
        table.insert(res.analysis, "Команда интерфейса: " .. cef.cmd .. ".")
        if cef.url then
            table.insert(res.analysis, "Окно загружается по адресу: " .. cef.url .. ".")
        end
    elseif cef.url then
        table.insert(res.analysis, "Загрузка окна по адресу: " .. cef.url .. ".")
    end
    if cef.nick then
        table.insert(res.analysis, "Ник игрока: " .. cef.nick .. ".")
    end

    -- 3.2 Токены-события
    res.tokens = findTokens(text)
    if #res.tokens > 0 and #res.events == 0 then
        table.insert(res.analysis, "Найдены идентификаторы: " .. table.concat(res.tokens, ", ") .. ".")
    end

    -- 3.3 URL
    for url in tostring(text):gmatch("https?://[^%s\"]+") do
        if #res.params < 24 then
            table.insert(res.params, "url=" .. url:sub(1, 160))
        end
    end
    for url in tostring(text):gmatch("www%.[%w%.%-]+") do
        if #res.params < 24 then
            table.insert(res.params, "url=" .. url:sub(1, 160))
        end
    end

    -- 3.4 Размеры окна (полезно для UI-пакетов)
    local win = {}
    local wx = tostring(text):match('"x"%s*:%s*([%d%.%-]+)')
    local wy = tostring(text):match('"y"%s*:%s*([%d%.%-]+)')
    local ww = tostring(text):match('"width"%s*:%s*([%d%.%-]+)')
    local wh = tostring(text):match('"height"%s*:%s*([%d%.%-]+)')
    if wx and wy and ww and wh then
        table.insert(res.params, string.format("окно: x=%s y=%s w=%s h=%s", wx, wy, ww, wh))
        table.insert(res.analysis, "Пакет позиционирует окно интерфейса.")
    end

    -- 3.5 Если событий нет и это не CEF-подобный пакет — пометим служебным
    if #res.events == 0 then
        if res.category == "unknown" then
            if id == 215 then
                res.category = "dialog"
                res.categoryTitle = M.catMeta.dialog.title
                res.categoryDesc = M.catMeta.dialog.desc
                res.title = "CEF-команда/текст интерфейса"
                table.insert(res.analysis, "Пакет id=215: команды интерфейса, но событие не распознано.")
            end
        end
    end

    -- Собираем итоговое описание
    local parts = {}
    if res.pktWhat ~= "" then
        table.insert(parts, res.pktWhat)
    end
    if res.description ~= "" then
        table.insert(parts, res.description)
    end

    res.pktIdDesc = res.pktWhat
    return res
end

-- Каноническая подпись текста пакета для дедупликации в итоговой таблице.
-- Схлопываем пробельные последовательности и заменяем числа на маркер "#",
-- чтобы пакеты одного типа, различающиеся только значениями данных
-- (координаты, количество, время), считались одним типом.
function M.signature(text)
    local s = tostring(text or "")
    s = s:gsub("%s+", " ")
    s = s:gsub("%d+[%.%,]?%d*", "#")
    return s
end

-- Описание категории по ключу
function M.categoryMeta(key)
    return M.catMeta[key] or M.catMeta.unknown
end

return M