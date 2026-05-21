import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme/zen_theme.dart';
import '../core/version_info.dart';
import '../core/widgets/zen_ui.dart';
import '../data/analytics_repository.dart';
import '../data/goals_repository.dart';
import '../data/meditation_goal.dart';
import '../domain/progress_calculator.dart';
import '../engine/timer_controller.dart';
import '../l10n/app_localizations.dart';
import '../services/app_service_locator.dart';
import 'auth_screen.dart';
import 'journal_screen.dart';
import 'meditation_guide_screen.dart';
import 'notification_settings_screen.dart';
import 'timer_page.dart';
import 'statistics_page.dart';
import 'widgets/glassmorphic_hero.dart';
import 'widgets/goals_panel.dart';
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
  List<GoalWithProgress> _goalsProgress = [];
  bool _loading = true;

  // Auth state
  bool _isAuthenticated = false;
  String? _displayName;
  String? _photoUrl;

  StreamSubscription<User?>? _authSubscription;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint('[DIAG] HomeScreen.initState()');

    // Пытаемся получить сервисы, но не падаем, если их нет
    _tryInitServices();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Загружаем прогрессию сразу
    _loadProgression();
  }

  void _tryInitServices() {
    try {
      final locator = AppServiceLocator.instance;
      final auth = locator.authService;
      debugPrint('[DIAG] AuthService available: ${auth != null}, DB available: ${locator.db != null}');

      // Устанавливаем начальное состояние аутентификации
      _updateAuthState(auth?.currentUser);

      _authSubscription = auth?.authStateChanges.listen((user) {
        debugPrint('[DIAG] Auth state changed: user=${user?.uid ?? "null"}');
        if (mounted) {
          _updateAuthState(user);
          _loadProgression();
        }
      });
    } catch (e) {
      debugPrint('[DIAG] Services not available: $e');
      // Продолжаем без сервисов — показываем статический UI
    }
  }

  /// Обновляет состояние аутентификации из [User] Firebase.
  void _updateAuthState(User? user) {
    setState(() {
      _isAuthenticated = user != null;
      _displayName = user?.displayName;
      _photoUrl = user?.photoURL;
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadProgression() async {
    debugPrint('[DIAG] _loadProgression() started');

    // Пробуем получить сервисы, но не падаем, если их нет
    try {
      final locator = AppServiceLocator.instance;
      final db = locator.db;
      final auth = locator.authService;
      final syncRepo = locator.syncRepo;

      if (db == null || auth == null || syncRepo == null) {
        debugPrint('[DIAG] _loadProgression: services not ready, db=$db, auth=$auth, syncRepo=$syncRepo');
        if (mounted) setState(() => _loading = false);
        return;
      }

      _repository ??= AnalyticsRepository(syncRepo);
      _repository!.goalsRepo = locator.goalsRepo;
      debugPrint('[DIAG] _loadProgression: fetching data...');

      final results = await Future.wait([
        _repository!.getUserProgression(),
        _repository!.getXpProgress(),
        _loadGoalsProgress(locator.goalsRepo),
      ]);
      debugPrint('[DIAG] _loadProgression: data fetched successfully');

      if (mounted) {
        setState(() {
          _progression = results[0] as UserProgression;
          _xpProgress = results[1] as XpProgress;
          _goalsProgress = results[2] as List<GoalWithProgress>;
          _loading = false;
        });
        debugPrint('[DIAG] _loadProgression: state updated, loading=false');
      }
    } catch (e) {
      debugPrint('[DIAG] _loadProgression error: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Загружает прогресс целей.
  Future<List<GoalWithProgress>> _loadGoalsProgress(
      GoalsRepository? goalsRepo) async {
    if (goalsRepo == null) return [];

    try {
      final goals = await goalsRepo.getGoals();
      if (goals.isEmpty) return [];

      // Получаем метрики для расчёта прогресса
      final todayMinutes = await _getTodayMinutes();
      final weeklyMetrics = await _getWeeklyMetrics();
      final dates = await _repository!.syncRepo.getDistinctSessionDates();
      final currentStreak = ProgressCalculator.calculateStreak(dates);

      return await goalsRepo.calculateAndUpdateProgress(
        todayMinutes: todayMinutes,
        weeklySessions: weeklyMetrics.$1,
        weeklyMinutes: weeklyMetrics.$2,
        currentStreak: currentStreak,
      );
    } catch (e) {
      debugPrint('Ошибка загрузки прогресса целей: $e');
      return [];
    }
  }

  /// Возвращает количество минут медитации за сегодня.
  Future<int> _getTodayMinutes() async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${_pad(now.month)}-${_pad(now.day)}';
      // end должен быть следующим днём, т.к. SQL запрос использует timestamp < end
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowStr =
          '${tomorrow.year}-${_pad(tomorrow.month)}-${_pad(tomorrow.day)}';
      final sessions =
          await _repository!.syncRepo.getSessionsInRange(dateStr, tomorrowStr);
      final totalSeconds =
          sessions.fold<int>(0, (sum, s) => sum + s.seconds);
      return (totalSeconds / 60).floor();
    } catch (_) {
      return 0;
    }
  }

  /// Возвращает (количество сессий за неделю, сумма минут за неделю).
  Future<(int, int)> _getWeeklyMetrics() async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final startStr =
          '${weekStart.year}-${_pad(weekStart.month)}-${_pad(weekStart.day)}';
      // end должен быть следующим днём, т.к. SQL запрос использует timestamp < end
      final tomorrow = now.add(const Duration(days: 1));
      final endStr =
          '${tomorrow.year}-${_pad(tomorrow.month)}-${_pad(tomorrow.day)}';
      final sessions =
          await _repository!.syncRepo.getSessionsInRange(startStr, endStr);
      final sessionCount = sessions.length;
      final totalSeconds =
          sessions.fold<int>(0, (sum, s) => sum + s.seconds);
      return (sessionCount, (totalSeconds / 60).floor());
    } catch (_) {
      return (0, 0);
    }
  }

  String _pad(int value) => value.toString().padLeft(2, '0');

  Future<void> _openAuthScreen() async {
    final auth = AppServiceLocator.instance.authService;
    if (auth == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(authService: auth),
      ),
    );

    if (result == true && mounted) {
      // После успешного входа — мигрируем локальные данные в облако
      final user = auth.currentUser;
      if (user != null) {
        final syncRepo = AppServiceLocator.instance.syncRepo;
        if (syncRepo != null) {
          await syncRepo.migrateLocalToCloud(user.uid);
        }
      }
      _loadProgression();
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

  Future<void> _navigateToNotificationSettings() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationSettingsScreen(),
      ),
    );
    if (changed == true && mounted) {
      _loadProgression();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;

    debugPrint('[DIAG] HomeScreen.build(), _loading=$_loading');

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Desktop/Web: ширина > 800 И высота > 600 (чтобы ландшафт на телефоне
          // не триггерил десктопный макет, где нет мобильной кнопки "Начать практику")
          final isDesktop = kIsWeb || (constraints.maxWidth > 800 && constraints.maxHeight > 600);
          final isCompact = constraints.maxHeight < 600;
          debugPrint('[DIAG] LayoutBuilder: w=${constraints.maxWidth}, h=${constraints.maxHeight}, isDesktop=$isDesktop, isCompact=$isCompact');

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
      isAuthenticated: _isAuthenticated,
      onAuthTap: _openAuthScreen,
      displayName: _displayName,
      photoUrl: _photoUrl,
      goalsProgress: _goalsProgress,
      onGoalsChanged: _loadProgression,
      onNotificationSettingsTap: _navigateToNotificationSettings,
    );
  }

  // ===========================================================================
  // MOBILE LAYOUT
  // ===========================================================================

  Widget _buildMobileLayout(ThemeData theme, ZenStyles zen, bool isCompact) {
    final horizontalPadding = isCompact ? zen.spacingUnit * 2 : zen.spacingUnit * 4;
    final gapScale = isCompact ? 0.5 : 1.0;

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                  isAuthenticated: _isAuthenticated,
                  onAuthTap: _openAuthScreen,
                  displayName: _displayName,
                  photoUrl: _photoUrl,
                ),

              SizedBox(height: zen.gap(5) * gapScale),

              // Пресеты длительности
              _buildDurationPresets(theme, zen, isCompact),

              // Нейробиологическая подсказка
              NeuroPresetInfo(minutes: _durationMinutes.toInt()),

              SizedBox(height: zen.gap(3) * gapScale),

              // CTA-кнопка с пульсацией
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: SizedBox(
                  height: isCompact ? 48 : 56,
                  child: ElevatedButton(
                    onPressed: _navigateToTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ZenColors.gold,
                      foregroundColor: ZenColors.background,
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      textStyle: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.startPractice),
                  ),
                ),
              ),

              SizedBox(height: zen.gap(2) * gapScale),

              // Дневник
              TextButton.icon(
                onPressed: _navigateToJournal,
                icon: Icon(
                  Icons.book_outlined,
                  size: 18,
                  color: ZenColors.gold.withValues(alpha: 0.7),
                ),
                label: Text(
                  AppLocalizations.of(context)!.journal,
                  style: TextStyle(
                    color: ZenColors.gold.withValues(alpha: 0.7),
                  ),
                ),
              ),

              SizedBox(height: zen.gap(1) * gapScale),

              // Статистика
              TextButton.icon(
                onPressed: _navigateToStatistics,
                icon: Icon(
                  Icons.bar_chart_outlined,
                  size: 18,
                  color: ZenColors.gold.withValues(alpha: 0.7),
                ),
                label: Text(
                  AppLocalizations.of(context)!.statistics,
                  style: TextStyle(
                    color: ZenColors.gold.withValues(alpha: 0.7),
                  ),
                ),
              ),

              SizedBox(height: zen.gap(2) * gapScale),

              // Путь к ясности
              OutlinedButton(
                onPressed: _navigateToGuide,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ZenColors.textPrimary,
                  side: BorderSide(
                    color: ZenColors.gold.withValues(alpha: 0.7),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: isCompact ? 10 : 14,
                  ),
                  textStyle: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                    fontSize: isCompact ? 12 : 14,
                    letterSpacing: 2.0,
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.openGuide),
              ),

              SizedBox(height: zen.gap(3) * gapScale),

              // Цели
              if (!_loading) ...[
                GoalsPanel(
                  goalsProgress: _goalsProgress,
                  onGoalsChanged: _loadProgression,
                ),
                SizedBox(height: zen.gap(3) * gapScale),
              ],

              // Уведомления
              TextButton.icon(
                onPressed: _navigateToNotificationSettings,
                icon: Icon(
                  Icons.notifications_outlined,
                  size: 18,
                  color: ZenColors.gold.withValues(alpha: 0.7),
                ),
                label: Text(
                  AppLocalizations.of(context)!.notifications,
                  style: TextStyle(
                    color: ZenColors.gold.withValues(alpha: 0.7),
                  ),
                ),
              ),

              SizedBox(height: zen.gap(1) * gapScale),

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

  Widget _buildDurationPresets(ThemeData theme, ZenStyles zen, [bool isCompact = false]) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.chooseDuration,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: ZenColors.textSecondary,
          ),
        ),
        SizedBox(height: isCompact ? zen.spacingUnit : zen.spacingUnit * 2),
        Wrap(
          spacing: isCompact ? zen.spacingUnit : zen.spacingUnit * 1.5,
          runSpacing: isCompact ? zen.spacingUnit : zen.spacingUnit * 1.5,
          alignment: WrapAlignment.center,
          children: [
            DurationPreset(
              minutes: 5,
              icon: Icons.coffee_outlined,
              label: AppLocalizations.of(context)!.presetQuick,
              subtitle: AppLocalizations.of(context)!.presetQuickSub,
              isSelected: _durationMinutes == 5,
              onTap: () => setState(() => _durationMinutes = 5),
            ),
            DurationPreset(
              minutes: 10,
              icon: Icons.self_improvement,
              label: AppLocalizations.of(context)!.presetStandard,
              subtitle: AppLocalizations.of(context)!.presetStandardSub,
              isSelected: _durationMinutes == 10,
              onTap: () => setState(() => _durationMinutes = 10),
            ),
            DurationPreset(
              minutes: 15,
              icon: Icons.water_drop_outlined,
              label: AppLocalizations.of(context)!.presetDeep,
              subtitle: AppLocalizations.of(context)!.presetDeepSub,
              isSelected: _durationMinutes == 15,
              onTap: () => setState(() => _durationMinutes = 15),
            ),
            DurationPreset(
              minutes: 20,
              icon: Icons.auto_awesome_outlined,
              label: AppLocalizations.of(context)!.presetMaster,
              subtitle: AppLocalizations.of(context)!.presetMasterSub,
              isSelected: _durationMinutes == 20,
              onTap: () => setState(() => _durationMinutes = 20),
            ),
          ],
        ),
      ],
    );
  }
}
