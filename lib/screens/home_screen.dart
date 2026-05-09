import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../data/analytics_repository.dart';
import '../data/database_provider.dart';
import '../engine/timer_controller.dart';
import 'timer_page.dart';
import 'statistics_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Текущая выбранная длительность медитации в минутах.
  double _durationMinutes = minDuration.toDouble();

  AnalyticsRepository? _repository;
  UserProgression _progression = const UserProgression(
    minutes: 0,
    level: 0,
    rank: 'Новичок осознанности',
  );
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgression();
  }

  Future<void> _loadProgression() async {
    try {
      final db = await DatabaseProvider.instance();
      _repository = AnalyticsRepository(db);
      final progression = await _repository!.getUserProgression();
      if (mounted) {
        setState(() {
          _progression = progression;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки прогрессии: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _navigateToTimer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TimerPage(
          durationInMinutes: _durationMinutes.toInt(),
        ),
      ),
    );
    // После возврата с таймера — обновляем прогрессию
    _loadProgression();
  }

  Future<void> _navigateToStatistics() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StatisticsPage()),
    );
    // После возврата со статистики — обновляем прогрессию
    _loadProgression();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Заголовок "ZenBalance"
              Text('ZenBalance', style: theme.textTheme.headlineLarge),

              const Gap(40),

              // Приветствие с динамическим рангом
              Text(
                _loading
                    ? 'Загрузка...'
                    : 'Приветствую, ${_progression.rank}',
                style: theme.textTheme.headlineMedium,
              ),

              const Gap(8),

              // Статус уровня
              Text(
                _loading
                    ? ''
                    : 'Уровень ${_progression.level} · ${_progression.minutes} мин',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),

              const Gap(48),

              // Выбор длительности медитации
              Text(
                'Длительность: ${_durationMinutes.toInt()} мин',
                style: theme.textTheme.bodyLarge,
              ),

              const Gap(8),

              Slider(
                value: _durationMinutes,
                min: minDuration.toDouble(),
                max: maxDuration.toDouble(),
                divisions: maxDuration - minDuration,
                label: '${_durationMinutes.toInt()} мин',
                onChanged: (value) {
                  setState(() {
                    _durationMinutes = value;
                  });
                },
              ),

              const Gap(24),

              // Кнопка "Начать практику"
              ElevatedButton(
                onPressed: _navigateToTimer,
                child: const Text('Начать практику'),
              ),

              const Gap(16),

              // Кнопка "Статистика"
              TextButton.icon(
                onPressed: _navigateToStatistics,
                icon: Icon(
                  Icons.bar_chart_outlined,
                  size: 18,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
                label: Text(
                  'Статистика',
                  style: TextStyle(
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),

              const Gap(32),

            ],
          ),
        ),
      ),
    );
  }
}
