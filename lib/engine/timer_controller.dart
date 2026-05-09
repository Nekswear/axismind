import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/level_up_event.dart';

/// Константы длительности медитации (в минутах).
const int minDuration = 1;
const int maxDuration = 60;

/// Контроллер таймера для ZenBalance.
///
/// Использует [ValueNotifier<int>] для отслеживания оставшихся секунд,
/// что позволяет обновлять только виджеты, подписанные на этот notifier,
/// без перерисовки всего дерева виджетов (в отличие от setState).
class TimerController {
  /// Текущее количество оставшихся секунд.
  final ValueNotifier<int> remainingSeconds;

  /// Общая длительность таймера в секундах (для расчёта прогресса).
  final int totalSeconds;

  /// Нотификатор события повышения уровня.
  ///
  /// UI-слой подписывается через [addListener] и показывает
  /// [LevelUpDialog] при срабатывании.
  final ValueNotifier<LevelUpEvent?> levelUpNotifier;

  Timer? _timer;

  /// Создаёт контроллер с заданной длительностью в минутах.
  ///
  /// [durationInMinutes] — длительность медитации в минутах.
  TimerController({required int durationInMinutes})
    : totalSeconds = durationInMinutes * 60,
      remainingSeconds = ValueNotifier<int>(durationInMinutes * 60),
      levelUpNotifier = ValueNotifier<LevelUpEvent?>(null);

  /// Запускает обратный отсчёт.
  ///
  /// Использует [Timer.periodic] с интервалом в 1 секунду.
  /// Таймер взаимодействует с Event Loop Dart'а: каждый тик (1 сек)
  /// помещается в очередь макрозадач (macrotask queue) и выполняется
  /// после завершения текущего микрозадачи (microtask queue).
  void start() {
    // Предотвращаем создание нескольких таймеров
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value = remainingSeconds.value - 1;
      } else {
        // Таймер завершён — останавливаем
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  /// Принудительно останавливает таймер.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Сбрасывает таймер к начальному значению.
  void reset() {
    stop();
    remainingSeconds.value = totalSeconds;
  }

  /// Флаг: завершён ли таймер (достиг нуля).
  bool get isFinished => remainingSeconds.value <= 0;

  /// Флаг: запущен ли таймер в данный момент.
  bool get isRunning => _timer != null && _timer!.isActive;

  /// Строгое освобождение ресурсов.
  ///
  /// Обязательно вызывать в [State.dispose] виджета-владельца.
  /// Отменяет [Timer] и удаляет всех слушателей [ValueNotifier],
  /// предотвращая утечки памяти и вызовы колбэков после dispose.
  void dispose() {
    stop();
    remainingSeconds.dispose();
    levelUpNotifier.dispose();
  }

  /// Обработка ухода приложения в фоновый режим.
  ///
  /// Для использования необходимо:
  /// 1. Примешать [WidgetsBindingObserver] к State виджета.
  /// 2. В [State.didChangeAppLifecycleState] вызвать этот метод:
  ///
  /// ```dart
  /// @override
  /// void didChangeAppLifecycleState(AppLifecycleState state) {
  ///   if (state == AppLifecycleState.paused) {
  ///     controller.handleAppLifecyclePaused();
  ///   } else if (state == AppLifecycleState.resumed) {
  ///     controller.handleAppLifecycleResumed();
  ///   }
  /// }
  /// ```
  ///
  /// При паузе таймер продолжает работать в фоне (Dart-изолят жив),
  /// но для точности можно сохранять [DateTime.now()] и при возвращении
  /// вычитать разницу. Ниже — минимальная заглушка.
  void handleAppLifecyclePaused() {
    // TODO: сохранить DateTime.now() для коррекции времени при возврате
  }

  void handleAppLifecycleResumed() {
    // TODO: восстановить точное время, вычтя разницу с сохранённым timestamp
  }
}
