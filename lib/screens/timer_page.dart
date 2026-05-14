import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/theme/zen_theme.dart';
import '../data/analytics_repository.dart';
import '../data/database_provider.dart';
import '../data/sync_repository.dart';
import '../engine/gong_service.dart';
import '../engine/timer_controller.dart';
import '../services/auth_service.dart';
import '../widgets/journal_dialog.dart';
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
  late final GongService _gongService;
  AnalyticsRepository? _repository;
  bool _sessionSaved = false;

  @override
  void initState() {
    super.initState();
    _gongService = GongService();
    _controller = TimerController(durationInMinutes: widget.durationInMinutes);
    _controller.start();

    // Звон гонга в начале сессии
    _gongService.playStartGong();

    // Не даём экрану гаснуть во время медитации
    WakelockPlus.enable();

    // Listen for timer completion to auto-save session
    _controller.remainingSeconds.addListener(_onTimerTick);
  }

  @override
  void dispose() {
    // Remove listeners first
    _controller.remainingSeconds.removeListener(_onTimerTick);
    // Строгая очистка ресурсов: отмена Timer и удаление слушателей
    _controller.dispose();
    _gongService.dispose();
    // Возвращаем стандартное поведение гашения экрана
    WakelockPlus.disable();
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
      // Звон гонга в конце сессии
      _gongService.playEndGong();
      _saveSession();
    }
  }

  Future<void> _saveSession() async {
    debugPrint('Попытка вызова сохранения сессии...');
    try {
      final db = await DatabaseProvider.instance();
      final auth = AuthService();
      final syncRepo = SyncRepository(localDb: db, auth: auth);
      _repository = AnalyticsRepository(syncRepo);

      // Используем processSessionEnd — он сам сохраняет сессию
      // и возвращает событие повышения уровня, если оно произошло
      final levelUp = await _repository!.processSessionEnd(
        _controller.totalSeconds,
      );
      debugPrint('Сохранение сессии успешно завершено');

      if (!context.mounted) return;

      // === JournalDialog: предлагаем записать ощущения ===
      final journalResult = await showDialog<JournalResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => JournalDialog(
          durationSeconds: _controller.totalSeconds,
        ),
      );

      // Сохраняем заметку/оценку/тег, если пользователь ввёл данные
      if (journalResult != null && context.mounted) {
        // Получаем ID последней сессии (она только что сохранена)
        final sessions = await _repository!.getJournalSessions(limit: 1);
        if (sessions.isNotEmpty) {
          await _repository!.updateSessionJournal(
            sessions.first.id,
            note: journalResult.note,
            moodRating: journalResult.moodRating,
            tag: journalResult.tag,
          );
          debugPrint('Запись дневника сохранена: '
              'mood=${journalResult.moodRating}, '
              'note=${journalResult.note}, '
              'tag=${journalResult.tag}');
        }
      }

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
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;

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
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: zen.focusGradient,
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // === Кнопка закрытия ✕ в правом верхнем углу ===
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    iconSize: 28,
                    onPressed: () {
                      _controller.stop();
                      Navigator.of(context).pop();
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),

                // === Центральный контент ===
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: zen.spacingUnit * 4), // 32px
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // === Карточка таймера ===
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 40,
                            horizontal: 32,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(zen.cardRadius),
                          ),
                          child: Column(
                            children: [
                              // Время
                              ValueListenableBuilder<int>(
                                valueListenable: _controller.remainingSeconds,
                                builder: (context, seconds, _) {
                                  return Text(
                                    _formatTime(seconds),
                                    style: theme.textTheme.displayLarge?.copyWith(
                                      fontSize: 72,
                                      fontWeight: FontWeight.w200,
                                      letterSpacing: 4,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),

                              SizedBox(height: zen.gap(3)), // 24px

                              // Прогресс-бар
                              ValueListenableBuilder<int>(
                                valueListenable: _controller.remainingSeconds,
                                builder: (context, seconds, _) {
                                  final progress = _controller.totalSeconds > 0
                                      ? seconds / _controller.totalSeconds
                                      : 0.0;
                                  final elapsed = _controller.totalSeconds - seconds;
                                  return Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 4,
                                          backgroundColor:
                                              Colors.white.withValues(alpha: 0.15),
                                          valueColor: const AlwaysStoppedAnimation<Color>(
                                            Color(0xFFC5A059),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${_formatTime(elapsed)} / ${_formatTime(_controller.totalSeconds)}',
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 1,
                                          color: Colors.white.withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: zen.gap(5)), // 40px

                        // Напоминание о позе и взгляде
                        Text(
                          'Спина прямая\nВзгляд вниз 45°\nФокус размыт',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.50),
                            fontSize: 15,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.5,
                            height: 1.8,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: zen.gap(5)), // 40px

                        // === Кнопки управления: Пауза + Стоп ===
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Кнопка Пауза / Продолжить
                            ValueListenableBuilder<int>(
                              valueListenable: _controller.remainingSeconds,
                              builder: (context, seconds, _) {
                                final isRunning = _controller.isRunning;
                                return _TimerControlButton(
                                  icon: isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  label: isRunning ? 'ПАУЗА' : 'ПРОДОЛЖИТЬ',
                                  onPressed: () {
                                    if (isRunning) {
                                      _controller.stop();
                                    } else {
                                      _controller.start();
                                    }
                                    // Триггерим перерисовку через setState,
                                    // так как isRunning не ValueNotifier
                                    setState(() {});
                                  },
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            // Кнопка Стоп
                            _TimerControlButton(
                              icon: Icons.stop_rounded,
                              label: 'СТОП',
                              isOutlined: true,
                              onPressed: () {
                                _controller.stop();
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Кнопка управления таймером (Пауза/Продолжить/Стоп).
class _TimerControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isOutlined;

  const _TimerControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.6),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5A059),
                foregroundColor: const Color(0xFF0A192F),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1.5,
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
