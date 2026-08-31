import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/level_up_event.dart';

/// Константы длительности медитации (в минутах).
const int minDuration = 1;
const int maxDuration = 60;

/// Контроллер таймера для AxisMind.
///
/// Использует [ValueNotifier<int>] для отслеживания оставшихся секунд,
/// что позволяет обновлять только виджеты, подписанные на этот notifier,
/// без перерисовки всего дерева виджетов (в отличие от setState).
///
/// ## Анти-дрейф (Anti-Drift)
///
/// Вместо простого декремента на каждом тике [Timer.periodic],
/// контроллер запоминает [DateTime] старта и на каждом тике вычисляет
/// реальное прошедшее время. Это компенсирует дрейф (накопление
/// погрешности), вызванный задержками Event Loop.
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

  /// Момент старта таймера (UTC) для анти-дрейф расчёта.
  DateTime? _startTime;

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
  /// На каждом тике вычисляет реальное прошедшее время через
  /// [DateTime.now()], что компенсирует дрейф Event Loop.
  void start() {
    // Предотвращаем создание нескольких таймеров
    _timer?.cancel();

    _startTime = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime == null) return;

      // Вычисляем реальное прошедшее время с момента старта
      final elapsed = DateTime.now().difference(_startTime!).inSeconds;

      // Оставшееся время = общее - реально прошедшее
      final remaining = totalSeconds - elapsed;

      if (remaining > 0) {
        remainingSeconds.value = remaining;
      } else {
        // Таймер завершён — останавливаем
        remainingSeconds.value = 0;
        _timer?.cancel();
        _timer = null;
        _startTime = null;
      }
    });
  }

  /// Принудительно останавливает таймер.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _startTime = null;
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
  /// Сохраняет [DateTime.now()] для коррекции времени при возвращении.
  /// При паузе таймер продолжает работать в фоне (Dart-изолят жив),
  /// но для точности при возвращении вычитаем разницу.
  void handleAppLifecyclePaused() {
    // _startTime уже сохранён, ничего дополнительно делать не нужно,
    // т.к. на каждом тике мы вычисляем разницу с _startTime.
    // Если приложение было в фоне долго, при возвращении следующий тик
    // Timer.periodic скорректирует оставшееся время.
  }

  void handleAppLifecycleResumed() {
    // При возвращении из фона Timer.periodic может пропустить тики.
    // Следующий тик корректно пересчитает remaining через _startTime.
    // Дополнительной логики не требуется.
  }
}
