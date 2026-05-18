import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/theme/zen_theme.dart';
import '../data/analytics_repository.dart';
import '../engine/gong_service.dart';
import '../engine/timer_controller.dart';
import '../services/app_service_locator.dart';
import '../widgets/goal_completed_notification.dart';
import '../widgets/journal_dialog.dart';
import '../widgets/level_up_dialog.dart';
import 'widgets/samadhi_view.dart';

/// Экран медитации с таймером обратного отсчёта и фазой Самадхи.
///
/// После завершения таймера и гонга переводит пользователя в
/// бесконечную фазу интеграции «Самадхи» с концентрическими кругами.
/// Выход из Самадхи — по тапу/пробелу, после чего открывается JournalDialog.
class TimerPage extends StatefulWidget {
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
  bool _isSaving = false;

  /// Флаг: показывать ли SamadhiView после завершения таймера.
  bool _showSamadhi = false;

  /// Completer для ожидания выхода из фазы Самадхи.
  Completer<void>? _samadhiCompleter;

  /// Флаг: Desktop/Web режим.
  bool get _isDesktop => kIsWeb;

  @override
  void initState() {
    super.initState();
    _gongService = GongService();
    _controller = TimerController(durationInMinutes: widget.durationInMinutes);
    _controller.start();

    _gongService.playStartGong();
    _enableWakelock();

    _controller.remainingSeconds.addListener(_onTimerTick);
  }

  Future<void> _enableWakelock() async {
    if (AppServiceLocator.isWakelockSupported) {
      try {
        await WakelockPlus.enable();
      } catch (e) {
        debugPrint('Wakelock enable failed (non-critical): $e');
      }
    }
  }

  Future<void> _disableWakelock() async {
    if (AppServiceLocator.isWakelockSupported) {
      try {
        await WakelockPlus.disable();
      } catch (e) {
        debugPrint('Wakelock disable failed (non-critical): $e');
      }
    }
  }

  @override
  void dispose() {
    _controller.remainingSeconds.removeListener(_onTimerTick);
    _controller.dispose();
    _gongService.dispose();
    _disableWakelock();
    super.dispose();
  }

  void _onTimerTick() {
    if (_controller.isFinished && !_sessionSaved && !_isSaving) {
      _sessionSaved = true;
      _isSaving = true;
      _gongService.playEndGong();
      _saveSession();
    }
  }

  Future<void> _saveSession() async {
    try {
      final locator = AppServiceLocator.instance;
      final syncRepo = locator.syncRepo;
      if (syncRepo == null) {
        _sessionSaved = false;
        _isSaving = false;
        return;
      }

      _repository ??= AnalyticsRepository(syncRepo);
      _repository!.goalsRepo = locator.goalsRepo;

      final sessionResult = await _repository!.processSessionEnd(
        _controller.totalSeconds,
      );

      if (!context.mounted) return;

      // === Фаза Самадхи (бесконечная интеграция) ===
      // Показываем SamadhiView перед JournalDialog
      await _showSamadhiPhase();

      if (!context.mounted) return;

      // === JournalDialog ===
      final journalResult = await showDialog<JournalResult>(
        // ignore: use_build_context_synchronously
        context: context,
        barrierDismissible: false,
        builder: (_) => JournalDialog(
          durationSeconds: _controller.totalSeconds,
        ),
      );

      if (journalResult != null && context.mounted) {
        final sessions = await _repository!.getJournalSessions(limit: 1);
        if (sessions.isNotEmpty) {
          await _repository!.updateSessionJournal(
            sessions.first.id,
            note: journalResult.note,
            moodRating: journalResult.moodRating,
            tag: journalResult.tag,
          );
        }
      }

      if (!context.mounted) return;

      // Показываем GoalCompletedNotification, если были выполнены цели
      if (sessionResult.hasCompletedGoals) {
        await showDialog<void>(
          // ignore: use_build_context_synchronously
          context: context,
          barrierDismissible: false,
          builder: (_) => GoalCompletedNotification(
            completedGoals: sessionResult.completedGoals,
          ),
        );
      }

      if (!context.mounted) return;

      // Показываем LevelUpDialog, если был повышение уровня
      if (sessionResult.hasLevelUp) {
        await showDialog<void>(
          // ignore: use_build_context_synchronously
          context: context,
          barrierDismissible: false,
          builder: (_) => LevelUpDialog(event: sessionResult.levelUp!),
        );
      }

      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Ошибка сохранения сессии: $e');
      _sessionSaved = false;
      _isSaving = false;
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Не удалось сохранить сессию. Попробуйте снова.'),
            // ignore: use_build_context_synchronously
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Повторить',
              textColor: Colors.white,
              onPressed: () {
                _sessionSaved = true;
                _isSaving = true;
                _saveSession();
              },
            ),
          ),
        );
      }
    }
  }

  /// Показывает фазу Самадхи как встроенный слой.
  ///
  /// Использует Completer, чтобы дождаться выхода пользователя
  /// из режима Самадхи перед открытием JournalDialog.
  Future<void> _showSamadhiPhase() async {
    _samadhiCompleter = Completer<void>();

    if (!mounted) return;
    setState(() => _showSamadhi = true);

    // Ждём, пока SamadhiView не вызовет onExited
    await _samadhiCompleter!.future;
  }

  void _onSamadhiExited() {
    if (mounted) {
      setState(() => _showSamadhi = false);
      _samadhiCompleter?.complete();
      _samadhiCompleter = null;
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_showSamadhi) return; // Блокируем выход во время Самадхи

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
          await _disableWakelock();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
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
                // === Основной контент таймера (скрыт во время Самадхи) ===
                if (!_showSamadhi) ...[
                  // Кнопка закрытия
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      iconSize: 28,
                      onPressed: () async {
                        _controller.stop();
                        await _disableWakelock();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),

                  // Центральный контент
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLandscape ? zen.spacingUnit * 2 : zen.spacingUnit * 4,
                      ),
                      child: isLandscape
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildTimerCard(theme, zen, isLandscape),
                                ),
                                SizedBox(width: zen.gap(3)),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildPostureHint(theme),
                                      SizedBox(height: zen.gap(3)),
                                      _buildControls(),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Карточка таймера
                                _buildTimerCard(theme, zen, isLandscape),
                                SizedBox(height: zen.gap(5)),
                                _buildPostureHint(theme),
                                SizedBox(height: zen.gap(5)),
                                _buildControls(),
                              ],
                            ),
                    ),
                  ),
                ],

                // === SamadhiView (поверх всего) ===
                if (_showSamadhi)
                  SamadhiView(
                    onExited: _onSamadhiExited,
                    isDesktop: _isDesktop,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCard(ThemeData theme, ZenStyles zen, [bool isLandscape = false]) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isLandscape ? 20 : 40,
        horizontal: isLandscape ? 16 : 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(zen.cardRadius),
      ),
      child: Column(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: _controller.remainingSeconds,
            builder: (context, seconds, _) {
              return Text(
                _formatTime(seconds),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: isLandscape ? 48 : 72,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
              );
            },
          ),
          SizedBox(height: isLandscape ? zen.gap(1) : zen.gap(3)),
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
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
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
    );
  }

  Widget _buildPostureHint(ThemeData theme) {
    return Text(
      'Спина прямая\nВзгляд вниз 45°\nФокус размыт',
      style: theme.textTheme.bodySmall?.copyWith(
        color: Colors.white.withValues(alpha: 0.50),
        fontSize: 15,
        fontWeight: FontWeight.w300,
        letterSpacing: 0.5,
        height: 1.8,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ValueListenableBuilder<int>(
          valueListenable: _controller.remainingSeconds,
          builder: (context, seconds, _) {
            final isRunning = _controller.isRunning;
            return _TimerControlButton(
              icon: isRunning
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              label: isRunning ? 'ПАУЗА' : 'ПРОДОЛЖИТЬ',
              onPressed: () {
                if (isRunning) {
                  _controller.stop();
                } else {
                  _controller.start();
                }
                setState(() {});
              },
            );
          },
        ),
        const SizedBox(width: 16),
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
