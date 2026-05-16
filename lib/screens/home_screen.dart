import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme/zen_theme.dart';
import '../core/version_info.dart';
import '../core/widgets/zen_ui.dart';
import '../data/analytics_repository.dart';
import '../engine/timer_controller.dart';
import '../services/app_service_locator.dart';
import 'journal_screen.dart';
import 'meditation_guide_screen.dart';
import 'timer_page.dart';
import 'statistics_page.dart';
import 'widgets/glassmorphic_hero.dart';
import 'widgets/neuro_preset_info.dart';
import 'widgets/widescreen_layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  double _durationMinutes = minDuration.toDouble();

  AnalyticsRepository? _repository;
  UserProgression _progression = const UserProgression(
    minutes: 0,
    level: 0,
    rank: 'Новичок осознанности',
  );
  XpProgress _xpProgress = const XpProgress(
    currentXp: 0,
    nextLevelXp: 100,
    progress: 0.0,
    remainingMinutes: 0,
  );
  bool _loading = true;

  StreamSubscription<User?>? _authSubscription;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    final auth = AppServiceLocator.instance.authService;
    _authSubscription = auth?.authStateChanges.listen((user) {
      if (mounted) {
        setState(() {});
        _loadProgression();
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadProgression() async {
    final locator = AppServiceLocator.instance;
    final db = locator.db;
    final auth = locator.authService;
    final syncRepo = locator.syncRepo;

    if (db == null || auth == null || syncRepo == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      _repository ??= AnalyticsRepository(syncRepo);

      final results = await Future.wait([
        _repository!.getUserProgression(),
        _repository!.getXpProgress(),
      ]);

      if (mounted) {
        setState(() {
          _progression = results[0] as UserProgression;
          _xpProgress = results[1] as XpProgress;
          _loading = false;
        });
      }
    } catch (e) {
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
    _loadProgression();
  }

  Future<void> _navigateToStatistics() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StatisticsPage()),
    );
    _loadProgression();
  }

  Future<void> _navigateToGuide() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MeditationGuideScreen()),
    );
  }

  Future<void> _navigateToJournal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JournalScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = kIsWeb || constraints.maxWidth > 800;
          final isCompact = constraints.maxHeight < 600;

          if (isDesktop) {
            return _buildDesktopLayout(theme, zen);
          }
          return _buildMobileLayout(theme, zen, isCompact);
        },
      ),
    );
  }

  // ===========================================================================
  // DESKTOP / WEB LAYOUT
  // ===========================================================================

  Widget _buildDesktopLayout(ThemeData theme, ZenStyles zen) {
    return WidescreenLayout(
      durationMinutes: _durationMinutes,
      onDurationChanged: (value) => setState(() => _durationMinutes = value),
      onStartPractice: _navigateToTimer,
      onJournalTap: _navigateToJournal,
      onStatisticsTap: _navigateToStatistics,
      onGuideTap: _navigateToGuide,
    );
  }

  // ===========================================================================
  // MOBILE LAYOUT
  // ===========================================================================

  Widget _buildMobileLayout(ThemeData theme, ZenStyles zen, bool isCompact) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: zen.spacingUnit * 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hero-секция с 3D Glassmorphic эффектом
                if (_loading)
                  _buildLoadingState(zen)
                else
                  GlassmorphicHero(
                    progression: _progression,
                    xpProgress: _xpProgress,
                    isCompact: isCompact,
                    isDesktop: false,
                  ),

                SizedBox(height: zen.gap(5)),

                // Пресеты длительности
                _buildDurationPresets(theme, zen),

                // Нейробиологическая подсказка
                NeuroPresetInfo(minutes: _durationMinutes.toInt()),

                SizedBox(height: zen.gap(3)),

                // CTA-кнопка с пульсацией
                AnimatedScale(
                  scale: _pulseAnimation.value,
                  duration: const Duration(milliseconds: 2000),
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _navigateToTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ZenColors.gold,
                        foregroundColor: ZenColors.background,
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      child: const Text('НАЧАТЬ ПРАКТИКУ'),
                    ),
                  ),
                ),

                SizedBox(height: zen.gap(2)),

                // Дневник
                TextButton.icon(
                  onPressed: _navigateToJournal,
                  icon: Icon(
                    Icons.book_outlined,
                    size: 18,
                    color: ZenColors.gold.withValues(alpha: 0.7),
                  ),
                  label: Text(
                    'Дневник',
                    style: TextStyle(
                      color: ZenColors.gold.withValues(alpha: 0.7),
                    ),
                  ),
                ),

                SizedBox(height: zen.gap(1)),

                // Статистика
                TextButton.icon(
                  onPressed: _navigateToStatistics,
                  icon: Icon(
                    Icons.bar_chart_outlined,
                    size: 18,
                    color: ZenColors.gold.withValues(alpha: 0.7),
                  ),
                  label: Text(
                    'Статистика',
                    style: TextStyle(
                      color: ZenColors.gold.withValues(alpha: 0.7),
                    ),
                  ),
                ),

                SizedBox(height: zen.gap(2)),

                // Путь к ясности
                OutlinedButton(
                  onPressed: _navigateToGuide,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ZenColors.textPrimary,
                    side: BorderSide(
                      color: ZenColors.gold.withValues(alpha: 0.7),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 2.0,
                    ),
                  ),
                  child: const Text('ОТКРЫТЬ ПУТЬ К ЯСНОСТИ'),
                ),

                SizedBox(height: zen.gap(4)),

                // Версия
                Padding(
                  padding: EdgeInsets.only(bottom: zen.spacingUnit),
                  child: Text(
                    VersionInfo.displayVersion,
                    style: TextStyle(
                      color: ZenColors.textMuted,
                      fontSize: 11,
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
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

  Widget _buildLoadingState(ZenStyles zen) {
    return ZenSurface(
      padding: EdgeInsets.all(zen.spacingUnit * 3),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ZenColors.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          SizedBox(height: zen.spacingUnit * 2),
          Container(
            width: 200,
            height: 20,
            decoration: BoxDecoration(
              color: ZenColors.textMuted.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: zen.spacingUnit),
          Container(
            width: 140,
            height: 16,
            decoration: BoxDecoration(
              color: ZenColors.textMuted.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationPresets(ThemeData theme, ZenStyles zen) {
    return Column(
      children: [
        Text(
          'Выбери длительность:',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: ZenColors.textSecondary,
          ),
        ),
        SizedBox(height: zen.spacingUnit * 2),
        Wrap(
          spacing: zen.spacingUnit * 1.5,
          runSpacing: zen.spacingUnit * 1.5,
          alignment: WrapAlignment.center,
          children: [
            DurationPreset(
              minutes: 5,
              icon: Icons.coffee_outlined,
              label: 'Быстрая',
              subtitle: 'Перерыв',
              isSelected: _durationMinutes == 5,
              onTap: () => setState(() => _durationMinutes = 5),
            ),
            DurationPreset(
              minutes: 10,
              icon: Icons.self_improvement,
              label: 'Стандарт',
              subtitle: 'Ежедневная',
              isSelected: _durationMinutes == 10,
              onTap: () => setState(() => _durationMinutes = 10),
            ),
            DurationPreset(
              minutes: 15,
              icon: Icons.water_drop_outlined,
              label: 'Глубокая',
              subtitle: 'Вечерняя',
              isSelected: _durationMinutes == 15,
              onTap: () => setState(() => _durationMinutes = 15),
            ),
            DurationPreset(
              minutes: 20,
              icon: Icons.auto_awesome_outlined,
              label: 'Мастер',
              subtitle: 'Выходная',
              isSelected: _durationMinutes == 20,
              onTap: () => setState(() => _durationMinutes = 20),
            ),
          ],
        ),
      ],
    );
  }
}
