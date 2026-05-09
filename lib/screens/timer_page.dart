import 'package:flutter/material.dart';

import '../data/database_provider.dart';
import '../data/analytics_repository.dart';
import '../engine/timer_controller.dart';
import '../widgets/level_up_dialog.dart';

/// Экран медитации с таймером обратного отсчёта.
///
/// Получает длительность через конструктор:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => TimerPage(durationInMinutes: 10),
///   ),
/// );
/// ```
class TimerPage extends StatefulWidget {
  /// Длительность медитации в минутах.
  final int durationInMinutes;

  const TimerPage({super.key, required this.durationInMinutes});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  late final TimerController _controller;
  AnalyticsRepository? _repository;
  bool _sessionSaved = false;

  @override
  void initState() {
    super.initState();
    _controller = TimerController(durationInMinutes: widget.durationInMinutes);
    _controller.start();

    // Listen for timer completion to auto-save session
    _controller.remainingSeconds.addListener(_onTimerTick);
  }

  @override
  void dispose() {
    // Remove listeners first
    _controller.remainingSeconds.removeListener(_onTimerTick);
    // Строгая очистка ресурсов: отмена Timer и удаление слушателей
    _controller.dispose();
    super.dispose();
  }

  void _onTimerTick() {
    debugPrint(
      'ТИК: remainingSeconds=${_controller.remainingSeconds.value}, '
      'isFinished=${_controller.isFinished}, '
      'sessionSaved=$_sessionSaved',
    );
    if (_controller.isFinished && !_sessionSaved) {
      _sessionSaved = true;
      _saveSession();
    }
  }

  Future<void> _saveSession() async {
    debugPrint('Попытка вызова сохранения сессии...');
    try {
      final db = await DatabaseProvider.instance();
      _repository = AnalyticsRepository(db);

      // Используем processSessionEnd — он сам сохраняет сессию
      // и возвращает событие повышения уровня, если оно произошло
      final levelUp = await _repository!.processSessionEnd(
        _controller.totalSeconds,
      );
      debugPrint('Сохранение сессии успешно завершено');

      if (!context.mounted) return;

      if (levelUp != null) {
        // Уровень повысился — показываем LevelUpDialog
        // Он содержит поздравление, информацию об уровне/ранге
        // и кнопку "Продолжить". После закрытия — возврат на главный экран.
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => LevelUpDialog(event: levelUp),
        );
      } else {
        // Повышения не было — показываем стандартную благодарность
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Спасибо за практику 🙏'),
            content: const Text('Сессия медитации завершена.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Отлично'),
              ),
            ],
          ),
        );
      }

      // После закрытия любого диалога — возвращаемся на главный экран
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Ошибка сохранения сессии: $e');
    }
  }

  /// Форматирует секунды в строку "ММ:СС".
  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      // Предотвращаем случайный выход (например, свайпом назад на iOS)
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        // Показываем диалог подтверждения выхода
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Завершить медитацию?'),
            content: const Text('Ваша практика ещё не завершена.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Продолжить'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Завершить'),
              ),
            ],
          ),
        );

        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Отображение таймера — подписан на ValueNotifier<int>
                // Перерисовывается только этот текст, а не весь экран
                ValueListenableBuilder<int>(
                  valueListenable: _controller.remainingSeconds,
                  builder: (context, seconds, _) {
                    return Text(
                      _formatTime(seconds),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: 72,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 4,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // Кнопка "Отмена" — визуально менее яркая (UX-тишина)
                TextButton(
                  onPressed: () {
                    _controller.stop();
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.35,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  child: const Text('Отмена'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Расширение для предотвращения гашения экрана во время медитации.
///
/// Чтобы экран смартфона не гас, используйте плагин `wakelock_plus`:
/// ```yaml
/// dependencies:
///   wakelock_plus: ^1.2.8
/// ```
///
/// Пример использования:
/// ```dart
/// import 'package:wakelock_plus/wakelock_plus.dart';
///
/// // Включить (не давать экрану гаснуть):
/// await WakelockPlus.enable();
///
/// // Выключить (вернуть стандартное поведение):
/// await WakelockPlus.disable();
/// ```
///
/// В iOS это требует капабилити в Info.plist,
/// в Android — разрешения WAKE_LOCK (автоматически добавляется плагином).
///
/// Альтернатива без плагина — использовать [SystemChrome] (не гарантирует работу):
/// ```dart
/// SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
/// ```
