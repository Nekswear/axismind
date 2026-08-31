// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'AxisMind';

  @override
  String get startPractice => 'НАЧАТЬ ПРАКТИКУ';

  @override
  String get openPathToClarity => 'ОТКРЫТЬ ПУТЬ К ЯСНОСТИ';

  @override
  String get continueLabel => 'Продолжить';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get retry => 'Повторить';

  @override
  String get skip => 'Пропустить';

  @override
  String get close => 'Закрыть';

  @override
  String get done => 'Готово';

  @override
  String get edit => 'Изменить';

  @override
  String get add => 'Добавить';

  @override
  String get setup => 'Настроить';

  @override
  String get create => 'Создать';

  @override
  String get sendTest => 'Отправить тестовое';

  @override
  String get learnMore => 'УЗНАТЬ БОЛЬШЕ';

  @override
  String get startPracticeBtn => 'НАЧАТЬ ПРАКТИКУ';

  @override
  String get exhale => 'ВЫДОХ';

  @override
  String get reset => 'СБРОС';

  @override
  String get repeat => 'Повторить';

  @override
  String get ok => 'Отлично!';

  @override
  String get great => 'Отлично!';

  @override
  String get chooseDuration => 'Выбери длительность';

  @override
  String get selectDurationColon => 'Выбери длительность:';

  @override
  String get presetQuick => 'Быстрая';

  @override
  String get presetQuickSub => 'Перерыв';

  @override
  String get presetStandard => 'Стандарт';

  @override
  String get presetStandardSub => 'Ежедневная';

  @override
  String get presetDeep => 'Глубокая';

  @override
  String get presetDeepSub => 'Вечерняя';

  @override
  String get presetMaster => 'Мастер';

  @override
  String get presetMasterSub => 'Выходная';

  @override
  String min(Object minutes) {
    return '$minutes мин';
  }

  @override
  String minutesLabelWithName(Object minutes, Object name) {
    return '$minutes мин — $name';
  }

  @override
  String get navPractice => 'Практика';

  @override
  String get navJournal => 'Дневник';

  @override
  String get navStatistics => 'Статистика';

  @override
  String get navGuide => 'Путь к ясности';

  @override
  String get navNotifications => 'Уведомления';

  @override
  String get premium => 'Премиум';

  @override
  String get premiumActive => 'Premium активно';

  @override
  String get authGoogle => 'Войти через Google';

  @override
  String get authContinueWithout => 'Продолжить без входа';

  @override
  String get authTitle => 'Ваш путь к осознанности';

  @override
  String get authSubtitle =>
      'Вход используется только для синхронизации\nваших данных между устройствами';

  @override
  String get authGoogleTitle => 'Авторизация через Google';

  @override
  String get authGoogleSubtitle =>
      'Доступна на мобильных устройствах и в веб-версии.\nНа компьютере приложение работает в локальном режиме.';

  @override
  String authError(Object error) {
    return 'Ошибка входа: $error';
  }

  @override
  String get authCloseTooltip => 'Закрыть';

  @override
  String get userPlaceholder => 'Пользователь';

  @override
  String get paywallTitle => 'Откройте полный\nпотенциал AxisMind';

  @override
  String get try7DaysFree => 'Попробуйте 7 дней бесплатно';

  @override
  String thenPrice(Object price) {
    return 'Попробовать 7 дней бесплатно\nзатем $price';
  }

  @override
  String get cancelAnytime => 'Отмена в любое время';

  @override
  String get restorePurchases => 'Восстановить покупки';

  @override
  String get continueFree => 'Продолжить бесплатно';

  @override
  String get paywallCloseTooltip => 'Закрыть';

  @override
  String get purchaseFailed => 'Покупка не удалась. Попробуйте позже.';

  @override
  String get subscriptionRestored => 'Подписка восстановлена!';

  @override
  String get noActivePurchases => 'Активных покупок не найдено.';

  @override
  String get paymentTerms =>
      'Оплата будет списана с вашего аккаунта Google Play после подтверждения покупки. Подписка автоматически продлевается, если не отменена за 24 часа до окончания текущего периода. Управлять подпиской можно в настройках Google Play.';

  @override
  String get featureMotivationalNotifications => 'Мотивационные уведомления';

  @override
  String get featureMotivationalNotificationsSub =>
      'Вдохновляющие цитаты и статистика прогресса';

  @override
  String get featureGoalReminders => 'Напоминания о целях';

  @override
  String get featureGoalRemindersSub =>
      'Ежедневное напоминание, если цель не выполнена';

  @override
  String get featureMeditationGoals => 'Цели медитации';

  @override
  String get featureMeditationGoalsSub => 'Создавайте и отслеживайте свои цели';

  @override
  String get featureDetailedStats => 'Детальная статистика';

  @override
  String get featureDetailedStatsSub => 'Тепловая карта, прогресс уровней и XP';

  @override
  String get featureDeviceSync => 'Синхронизация устройств';

  @override
  String get featureDeviceSyncSub => 'Ваши данные всегда с вами';

  @override
  String get journalTitle => 'Дневник медитаций';

  @override
  String get journalEdit => 'Редактировать запись ✏️';

  @override
  String get journalNew => 'Запиши свои ощущения 📝';

  @override
  String journalSession(Object duration) {
    return 'Сессия: $duration';
  }

  @override
  String get journalMood => 'Как ты себя чувствуешь?';

  @override
  String get journalNote => 'Напиши, что пришло в голову...';

  @override
  String get journalTag => 'Тег (необязательно)';

  @override
  String get journalSearch => 'Поиск по заметкам...';

  @override
  String get journalAllTags => 'Все';

  @override
  String get journalEmpty => 'Здесь пока пусто';

  @override
  String get journalEmptySubtitle =>
      'Заверши медитацию,\nчтобы появилась первая запись';

  @override
  String get journalUpdateFailed => 'Не удалось обновить запись';

  @override
  String get journalDeleteConfirm => 'Удалить запись?';

  @override
  String get journalDeleteConfirmSub => 'Это действие нельзя отменить.';

  @override
  String get journalDeleted => 'Запись удалена';

  @override
  String get journalDeleteFailed => 'Не удалось удалить запись';

  @override
  String get tagMorning => 'Утро';

  @override
  String get tagDay => 'День';

  @override
  String get tagEvening => 'Вечер';

  @override
  String get tagStress => 'Стресс';

  @override
  String get tagCalm => 'Спокойствие';

  @override
  String get tagGratitude => 'Благодарность';

  @override
  String get goalsTitle => 'Настройка целей';

  @override
  String get goalsSubtitle =>
      'Цели помогают отслеживать регулярность практики\nи дают бонусные XP за выполнение.';

  @override
  String get goalsCurrent => 'Текущие цели';

  @override
  String get goalsMaxReached => 'Максимум 4 цели';

  @override
  String get goalsAdd => 'Добавить цель';

  @override
  String get goalsNoGoals => 'У вас пока нет целей';

  @override
  String get goalsNoGoalsSubtitle =>
      'Поставьте цель, чтобы отслеживать прогресс\nи получать бонусные XP';

  @override
  String get goalsCreate => 'Создать цель';

  @override
  String get goalsEdit => 'Изменить цель';

  @override
  String get goalsNew => 'Новая цель';

  @override
  String get goalsDeleteConfirm => 'Удалить цель?';

  @override
  String goalsDeleteConfirmSub(Object name) {
    return 'Вы уверены, что хотите удалить цель\n«$name»?';
  }

  @override
  String goalsGoalLabel(Object target, Object unit, Object xp) {
    return '$target $unit · +$xp XP';
  }

  @override
  String get goalsTypeLabel => 'Тип цели';

  @override
  String get goalsTargetLabel => 'Целевое значение';

  @override
  String get goalsTargetHintDaily => 'Например: 10 минут в день';

  @override
  String get goalsTargetHintWeeklySessions => 'Например: 5 сессий в неделю';

  @override
  String get goalsTargetHintWeeklyMinutes => 'Например: 60 минут в неделю';

  @override
  String get goalsTargetHintStreak => 'Например: 7 дней подряд';

  @override
  String get goalDailyMinutes => 'Ежедневная практика';

  @override
  String get goalWeeklySessions => 'Сессий в неделю';

  @override
  String get goalWeeklyMinutes => 'Минут в неделю';

  @override
  String get goalStreakDays => 'Дней подряд';

  @override
  String get goalUnitMinPerDay => 'мин/день';

  @override
  String get goalUnitSessPerWeek => 'сесс./нед.';

  @override
  String get goalUnitMinPerWeek => 'мин/нед.';

  @override
  String get goalUnitDays => 'дней';

  @override
  String get statsTitle => 'Статистика';

  @override
  String statsLastDays(Object days) {
    return 'Последние $days дней';
  }

  @override
  String get statsTotalMinutes => 'Всего минут';

  @override
  String get statsSessions => 'Сессий';

  @override
  String get statsStreak => 'Серия';

  @override
  String get statsStreakUnit => 'день';

  @override
  String get statsStreakUnitPlural => 'дней';

  @override
  String get statsGrowth => 'Рост';

  @override
  String statsGrowthPeriod(Object days) {
    return 'за $days д.';
  }

  @override
  String get statsAverage => 'в среднем';

  @override
  String get statsAveragePerDay => 'в среднем в день';

  @override
  String get statsBest => 'лучший';

  @override
  String get statsRegularity => 'регулярность';

  @override
  String get statsActivity30 => 'Активность за 30 дней';

  @override
  String get statsDynamics => 'Динамика';

  @override
  String statsAvgLabel(Object minutes) {
    return 'сред. $minutes';
  }

  @override
  String get statsPeriod7 => '7д';

  @override
  String get statsPeriod14 => '14д';

  @override
  String get statsPeriod30 => '30д';

  @override
  String get notifTitle => 'Уведомления';

  @override
  String get notifSubtitle =>
      'Настройте пуш-уведомления, чтобы не пропускать\nпрактику и отслеживать прогресс.';

  @override
  String get notifGeneral => 'Общие';

  @override
  String get notifEnabled => 'Уведомления';

  @override
  String get notifEnabledSub => 'Включить или отключить все уведомления';

  @override
  String get notifDailyReminder => 'Ежедневное напоминание';

  @override
  String get notifReminderTime => 'Время напоминания';

  @override
  String get notifReminderTimeSub => 'Ежедневное уведомление о медитации';

  @override
  String get notifMotivation => 'Мотивация';

  @override
  String get notifMotivationMessages => 'Мотивационные сообщения';

  @override
  String get notifMotivationSub =>
      'Вдохновляющие цитаты и статистика прогресса';

  @override
  String get notifMotivationTime => 'Время мотивации';

  @override
  String get notifMotivationTimeSub => 'Ежедневное мотивационное уведомление';

  @override
  String get notifGoals => 'Цели';

  @override
  String get notifGoalReminder => 'Напоминание о целях';

  @override
  String get notifGoalReminderSub =>
      'Напоминание вечером, если цель дня не выполнена';

  @override
  String get notifGoalReminderTime => 'Время напоминания';

  @override
  String get notifGoalReminderTimeSub => 'Ежедневное напоминание о целях';

  @override
  String get notifQuietHours => 'Тихие часы';

  @override
  String notifQuietHoursSubEnabled(Object start, Object end) {
    return 'Не беспокоить с $start до $end';
  }

  @override
  String get notifQuietHoursSubDisabled => 'Отключить уведомления на ночь';

  @override
  String get notifQuietHoursStart => 'Начало';

  @override
  String get notifQuietHoursEnd => 'Конец';

  @override
  String get notifTesting => 'Проверка';

  @override
  String get notifTestSent => 'Тестовое уведомление отправлено!';

  @override
  String notifQuietHoursActive(Object start, Object end) {
    return 'Сейчас тихие часы ($start–$end). Уведомление не будет показано.';
  }

  @override
  String get notifTimePickerHelp => 'Выберите время напоминания';

  @override
  String get notifTimePickerMotivationHelp => 'Время мотивационных сообщений';

  @override
  String get notifTimePickerGoalHelp => 'Время напоминания о целях';

  @override
  String get notifTimePickerQuietStartHelp => 'Начало тихих часов';

  @override
  String get notifTimePickerQuietEndHelp => 'Конец тихих часов';

  @override
  String get notifTimePickerCancel => 'Отмена';

  @override
  String get notifTimePickerConfirm => 'Готово';

  @override
  String get notifTypeReminder => 'Напоминания';

  @override
  String get notifTypeMotivation => 'Мотивация';

  @override
  String get notifTypeGoals => 'Цели';

  @override
  String get notifTypeStreak => 'Серия';

  @override
  String get notifChannelReminders => 'Напоминания';

  @override
  String get notifChannelRemindersDesc => 'Ежедневные напоминания о медитации';

  @override
  String get notifChannelMotivation => 'Мотивация';

  @override
  String get notifChannelMotivationDesc => 'Мотивационные сообщения и цитаты';

  @override
  String get notifChannelGoals => 'Цели';

  @override
  String get notifChannelGoalsDesc => 'Уведомления о прогрессе целей';

  @override
  String get notifChannelStreak => 'Серия';

  @override
  String get notifChannelStreakDesc => 'Поздравления с рекордами дней подряд';

  @override
  String get notifBodyReminder =>
      '🧘 Пора медитировать!\nВыделите 10 минут для внутренней тишины и покоя.';

  @override
  String get notifBodyGoalReminder =>
      '🎯 Осталось время до выполнения цели!\nВсего несколько минут медитации — и вы получите бонусные XP!';

  @override
  String notifBodyStreak(Object streak) {
    return '🔥 Новый рекорд: $streak дней подряд!\nПоздравляем! Вы побили свой личный рекорд!';
  }

  @override
  String get timerPause => 'ПАУЗА';

  @override
  String get timerResume => 'ПРОДОЛЖИТЬ';

  @override
  String get timerStop => 'СТОП';

  @override
  String get timerPosture => 'Спина прямая\nВзгляд вниз 45°\nФокус размыт';

  @override
  String get timerEndMeditation => 'Завершить медитацию?';

  @override
  String get timerEndMeditationSub => 'Ваша практика ещё не завершена.';

  @override
  String get timerContinue => 'Продолжить';

  @override
  String get timerEnd => 'Завершить';

  @override
  String get timerSaveFailed =>
      'Не удалось сохранить сессию. Попробуйте снова.';

  @override
  String get timerRetry => 'Повторить';

  @override
  String get guideHeroLabel => 'Alex Merch Foundation';

  @override
  String get guideTitle => 'AxisMind';

  @override
  String get guideSubtitle => 'Рациональный путь к ясности ума';

  @override
  String get guideFinalEdition => 'FINAL EDITION 2026';

  @override
  String get guideTechnique => 'Техника: Сусокукан (Счёт дыхания)';

  @override
  String get guideArithmetic => 'Арифметика осознанности';

  @override
  String get guidePosture => 'ПОСАДКА';

  @override
  String get guidePostureDesc =>
      'Сядьте на край стула или в дзадзен. Спина прямая, но без напряжения. Плечи расслаблены, руки в мудре (овальный замок).';

  @override
  String get guideGaze => 'ВЗГЛЯД';

  @override
  String get guideGazeDesc =>
      'Глаза приоткрыты, взгляд направлен вниз под углом ~45° на пол перед собой (1–1.5 метра). Не закрывайте глаза — это уводит в сонливость и грёзы.';

  @override
  String get guideFocus => 'ФОКУС';

  @override
  String get guideFocusDesc =>
      'Размойте зрение — не всматривайтесь в текстуру пола, не фиксируйтесь на точках. Используйте периферическое зрение. Вы смотрите, но не видите деталей.';

  @override
  String get guideAlgorithm =>
      'Считайте каждый выдох. Дойдя до 10, начните обратный отсчёт до 1. Если мысль прервала счёт — вернитесь к единице.';

  @override
  String get guideBioEffect => 'Биологический эффект';

  @override
  String get guideBioEffectDesc =>
      'Счёт задействует префронтальную кору, блокируя «дефолт-систему» мозга, отвечающую за блуждание мыслей и тревогу.';

  @override
  String get guideZenRule => 'Правило Дзен';

  @override
  String get guideZenRuleQuote =>
      '«Если вы потеряли счёт на цифре 9 — вы проиграли битву за внимание. Смиренно вернитесь к 1. Это и есть практика.»';

  @override
  String get guideZazenGeometry => 'Геометрия Дзадзен';

  @override
  String get guideFormContent => 'Форма и Содержание';

  @override
  String get guideVertical => 'Вертикаль';

  @override
  String get guideVerticalDesc =>
      'Спина прямая, как струна. Это физиологическая база для бодрствующего сознания.';

  @override
  String get guideGazeZazen => 'Взгляд';

  @override
  String get guideGazeZazenDesc =>
      'Глаза приоткрыты, взгляд под 45° вниз, фокус размыт. Вы не уходите в мир грёз, вы остаётесь здесь и сейчас.';

  @override
  String get guideMudra => 'Мудра';

  @override
  String get guideMudraDesc =>
      'Руки в овальном замке. Это ваш физический датчик глубины концентрации.';

  @override
  String get guideResistance => 'Преодоление сопротивления';

  @override
  String get guidePracticalGuide => 'Практическое руководство';

  @override
  String get guideProblem => 'Проблема';

  @override
  String get guideMindMechanism => 'Механизм ума';

  @override
  String get guideZenSolution => 'Дзен-решение';

  @override
  String get guideProblemItch => 'Зуд и беспокойство';

  @override
  String get guideLogicItch => 'Защитная реакция эго на непривычную тишину.';

  @override
  String get guideActionItch =>
      'Мусётоку. Наблюдай зуд как посторонний объект. Он уйдет сам.';

  @override
  String get guideProblemNoise => 'Ментальный шум';

  @override
  String get guideLogicNoise =>
      'Попытка мозга заполнить вакуум привычными планами.';

  @override
  String get guideActionNoise =>
      'Сусокукан. Мягко верни внимание к счёту «Один». Без агрессии.';

  @override
  String get guideProblemSleep => 'Сонливость';

  @override
  String get guideLogicSleep =>
      'Признак потери тонуса и соскальзывания в транс.';

  @override
  String get guideActionSleep =>
      'Энергия. Выпрями спину. Приоткрой глаза. Дыши чуть глубже.';

  @override
  String get guideWitness => 'Будьте Свидетелем.';

  @override
  String get guideQuote => 'Ваш ум — ваш главный актив.';

  @override
  String get guideFooter => 'ALEX MERCH • AXISMIND SYSTEM • 2026';

  @override
  String levelUpTitle(Object level) {
    return 'Уровень $level';
  }

  @override
  String get goalCompleted => 'Цель выполнена!';

  @override
  String get goalCompletedClose => 'Отлично!';

  @override
  String get emptyDashboardTitle =>
      'Ваш путь к спокойствию\nначинается с первой минуты';

  @override
  String get emptyDashboardSubtitle =>
      'Завершите свою первую медитацию,\nчтобы увидеть здесь свою статистику';

  @override
  String get errorUnknown => 'Произошла неизвестная ошибка';

  @override
  String get errorDatabase =>
      'Ошибка базы данных. Попробуйте перезапустить приложение.';

  @override
  String get errorNetwork =>
      'Проблема с подключением. Проверьте интернет-соединение.';

  @override
  String get errorStats => 'Ошибка при загрузке статистики.';

  @override
  String get errorStatsRetry =>
      'Не удалось загрузить статистику. Попробуйте снова.';

  @override
  String get errorStatsRefresh =>
      'Не удалось загрузить статистику. Попробуйте снова.';

  @override
  String get errorDataRefreshing => 'Данные обновляются...';

  @override
  String get rankNovice => 'Новичок осознанности';

  @override
  String get rankSeeker => 'Искатель спокойствия';

  @override
  String get rankGuardian => 'Хранитель тишины';

  @override
  String get rankMaster => 'Мастер баланса';

  @override
  String get rankWanderer => 'Странник глубин';

  @override
  String get rankAwakened => 'Пробуждённый';

  @override
  String get rankSage => 'Мудрец';

  @override
  String get rankEnlightened => 'Просветлённый';

  @override
  String get rankLegend => 'Легенда';

  @override
  String get rankImmortal => 'Бессмертный';

  @override
  String get rankDivine => 'Божественный';

  @override
  String get rankDescriptionNovice => 'Первый шаг на пути к осознанности';

  @override
  String get rankDescriptionSeeker => 'Поиск внутренней гармонии';

  @override
  String get rankDescriptionGuardian => 'Умение находить тишину внутри';

  @override
  String get rankDescriptionMaster => 'Баланс между усилием и покоем';

  @override
  String get rankDescriptionWanderer => 'Исследование глубин сознания';

  @override
  String get rankDescriptionAwakened => 'Пробуждение внутреннего света';

  @override
  String get rankDescriptionSage => 'Мудрость, рождённая практикой';

  @override
  String get rankDescriptionEnlightened => 'Свет осознанности ведёт вас';

  @override
  String get rankDescriptionLegend => 'Ваш путь вдохновляет других';

  @override
  String get rankDescriptionImmortal => 'Вневременная практика';

  @override
  String get rankDescriptionDivine => 'Вы достигли просветления';

  @override
  String rankLevel(Object level) {
    return 'Уровень $level';
  }

  @override
  String get rankYouAreHere => 'Вы здесь';

  @override
  String get rankContinuePractice =>
      'Продолжайте практику, чтобы открыть новые ранги';

  @override
  String get rankClose => 'Закрыть';

  @override
  String get rankTiers => 'Уровни';

  @override
  String get rankRequiredPractice => 'Требуется практики';

  @override
  String get rankProgressToNext => 'Прогресс до следующего ранга';

  @override
  String rankRemainingMinutes(Object minutes) {
    return 'Осталось ~$minutes мин до следующего ранга';
  }

  @override
  String rankRemainingToNext(Object minutes) {
    return 'Осталось $minutes мин до следующего уровня';
  }

  @override
  String get rankStatusCompleted => 'Пройден';

  @override
  String get rankStatusCurrent => 'Текущий ранг';

  @override
  String get rankStatusLocked => 'Ещё не доступен';

  @override
  String rankLevelRangeOpen(Object min) {
    return '$min+ ур.';
  }

  @override
  String rankLevelRangeSingle(Object min) {
    return '$min ур.';
  }

  @override
  String rankLevelRangeMulti(Object min, Object max) {
    return '$min–$max ур.';
  }

  @override
  String rankMinutesRequired(Object minutes) {
    return '$minutes мин';
  }

  @override
  String rankMinutesRequiredThousands(Object value) {
    return '$value тыс. мин';
  }

  @override
  String rankMinutesTotal(Object minutes) {
    return '$minutes мин всего';
  }

  @override
  String rankMinutesTotalThousands(Object value) {
    return '$value тыс. мин всего';
  }

  @override
  String get subscriptionGuardLoading => 'AxisMind';

  @override
  String get samadhiExitHint => 'Нажмите Пробел или кликните для выхода';

  @override
  String get neuroPreset5 =>
      'Остановка «мысленного шума».\nБыстрый возврат контроля над вниманием.';

  @override
  String get neuroPreset10 =>
      'Снижение физического напряжения.\nГлубокое упорядочивание ментальной активности.';

  @override
  String get neuroPreset15 =>
      'Глубокая стабилизация восприятия.\nПереход к ментальной тишине и покою.';

  @override
  String get neuroPreset20 =>
      'Классическая Дзен-тренировка.\nСнижение симпатического тонуса и абсолютная ясность ума.';

  @override
  String get daySun => 'Вс';

  @override
  String get dayMon => 'Пн';

  @override
  String get dayTue => 'Вт';

  @override
  String get dayWed => 'Ср';

  @override
  String get dayThu => 'Чт';

  @override
  String get dayFri => 'Пт';

  @override
  String get daySat => 'Сб';

  @override
  String get dayShortSun => 'Вс';

  @override
  String get dayShortMon => 'Пн';

  @override
  String get dayShortTue => 'Вт';

  @override
  String get dayShortWed => 'Ср';

  @override
  String get dayShortThu => 'Чт';

  @override
  String get dayShortFri => 'Пт';

  @override
  String get dayShortSat => 'Сб';

  @override
  String get monthJan => 'янв';

  @override
  String get monthFeb => 'фев';

  @override
  String get monthMar => 'мар';

  @override
  String get monthApr => 'апр';

  @override
  String get monthMay => 'май';

  @override
  String get monthJun => 'июн';

  @override
  String get monthJul => 'июл';

  @override
  String get monthAug => 'авг';

  @override
  String get monthSep => 'сен';

  @override
  String get monthOct => 'окт';

  @override
  String get monthNov => 'ноя';

  @override
  String get monthDec => 'дек';

  @override
  String get month => '/мес';

  @override
  String get openGuide => 'ОТКРЫТЬ ПУТЬ К ЯСНОСТИ';

  @override
  String get journal => 'Дневник';

  @override
  String get statistics => 'Статистика';

  @override
  String get notifications => 'Уведомления';

  @override
  String get user => 'Пользователь';

  @override
  String get quote1 => 'Тишина — это не отсутствие звуков, а присутствие себя.';

  @override
  String get quote2 =>
      'Каждая минута медитации — это инвестиция в спокойствие.';

  @override
  String get quote3 => 'Дышите глубже — внутри вас целый океан покоя.';

  @override
  String get quote4 =>
      'Не пытайтесь остановить мысли. Научитесь не вовлекаться в них.';

  @override
  String get quote5 => 'Медитация — это не техника, а способ быть.';

  @override
  String get quote6 =>
      'Внутренний покой начинается с того момента, как вы решаете не позволять внешнему миру управлять вами.';

  @override
  String get quote7 =>
      'Осознанность — это ключ, который открывает дверь к гармонии.';

  @override
  String get quote8 =>
      'Ваша практика — это ваш остров. Никто не может отнять его у вас.';

  @override
  String get quote9 => 'Сделайте паузу. Вдохните. Вы уже на правильном пути.';

  @override
  String get quote10 => 'Каждый день — это новая возможность вернуться к себе.';

  @override
  String get quote11 => 'Сила не в напряжении, а в расслаблении.';

  @override
  String get quote12 => 'Медитация — это возвращение домой, в своё истинное Я.';

  @override
  String get quote13 => 'Не ждите идеального момента. Начните сейчас.';

  @override
  String get quote14 => 'Ваше дыхание — это якорь в настоящем моменте.';

  @override
  String get quote15 =>
      'Прогресс — это не прямая линия. Каждая минута практики имеет значение.';
}
