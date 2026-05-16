import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme/zen_theme.dart';
import '../core/version_info.dart';
import '../core/widgets/zen_ui.dart';
import '../data/analytics_repository.dart';
import '../engine/timer_controller.dart';
import '../services/app_service_locator.dart';
import 'auth_screen.dart';
import 'journal_screen.dart';
import 'meditation_guide_screen.dart';
import 'timer_page.dart';
import 'statistics_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  /// Текущая выбранная длительность медитации в минутах.
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

  /// Анимация пульсации для CTA-кнопки.
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  /// Отслеживание подписки на auth state.
  bool _isAuthenticated = false;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();

    final auth = AppServiceLocator.instance.authService;
    _isAuthenticated = auth?.isAuthenticated ?? false;

    // Подписка на изменения auth state с сохранением StreamSubscription.
    // authStateChanges сразу эмитит текущее состояние при подписке,
    // поэтому отдельный вызов _loadProgression() не требуется.
    _authSubscription = auth?.authStateChanges.listen((user) {
      if (mounted) {
        setState(() {
          _isAuthenticated = user != null;
        });
        _loadProgression();
      }
    });

    // Пульсация кнопки "Начать практику"
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

  Future<void> _navigateToAuth() async {
    final auth = AppServiceLocator.instance.authService;
    if (auth == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(authService: auth),
      ),
    );
    // Если пользователь вошёл — мигрируем локальные данные в облако
    if (result == true && _repository != null) {
      final userId = auth.userId;
      if (userId != null) {
        await _repository!.syncRepo.migrateLocalToCloud(userId);
      }
      _loadProgression();
    }
  }

  Future<void> _handleSignOut() async {
    final auth = AppServiceLocator.instance.authService;
    if (auth == null) return;

    try {
      await auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вы вышли из аккаунта')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при выходе: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
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
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < 600;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: zen.spacingUnit * 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // =====================================================
                      // Hero-секция: ранг + XP + streak
                      // =====================================================
                      if (_loading)
                        _buildLoadingState(zen)
                      else
                        _buildHeroSection(theme, zen, isCompact),

                      SizedBox(height: zen.gap(5)), // 40px

                      // =====================================================
                      // Action-секция: пресеты + CTA
                      // =====================================================
                      _buildDurationPresets(theme, zen),

                      SizedBox(height: zen.gap(3)), // 24px

                      // Кнопка "Начать практику" с пульсацией
                      AnimatedScale(
                        scale: _pulseAnimation.value,
                        duration: const Duration(milliseconds: 2000),
                        child: ElevatedButton(
                          onPressed: _navigateToTimer,
                          child: const Text('Начать практику'),
                        ),
                      ),

                      SizedBox(height: zen.gap(2)), // 16px

                      // Кнопка "Дневник"
                      TextButton.icon(
                        onPressed: _navigateToJournal,
                        icon: Icon(
                          Icons.book_outlined,
                          size: 18,
                          color: primaryColor.withValues(alpha: 0.7),
                        ),
                        label: Text(
                          'Дневник',
                          style: TextStyle(
                            color: primaryColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ),

                      SizedBox(height: zen.gap(1)), // 8px

                      // Кнопка "Статистика"
                      TextButton.icon(
                        onPressed: _navigateToStatistics,
                        icon: Icon(
                          Icons.bar_chart_outlined,
                          size: 18,
                          color: primaryColor.withValues(alpha: 0.7),
                        ),
                        label: Text(
                          'Статистика',
                          style: TextStyle(
                            color: primaryColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ),

                      SizedBox(height: zen.gap(2)), // 16px

                      // Кнопка "Открыть путь к ясности"
                      OutlinedButton(
                        onPressed: _navigateToGuide,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: onSurface,
                          side: BorderSide(
                            color: primaryColor.withValues(alpha: 0.7),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          textStyle: const TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 2.0,
                          ),
                        ),
                        child: const Text('ОТКРЫТЬ ПУТЬ К ЯСНОСТИ'),
                      ),

                      SizedBox(height: zen.gap(4)), // 32px

                      // Версия приложения
                      Padding(
                        padding: EdgeInsets.only(bottom: zen.spacingUnit),
                        child: Text(
                          VersionInfo.displayVersion,
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.3),
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
        },
      ),
    );
  }

  /// Состояние загрузки — Shimmer-подобный скелетон.
  Widget _buildLoadingState(ZenStyles zen) {
    return ZenSurface(
      padding: EdgeInsets.all(zen.spacingUnit * 3),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          SizedBox(height: zen.spacingUnit * 2),
          Container(
            width: 200,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: zen.spacingUnit),
          Container(
            width: 140,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// Hero-секция с градиентом, рангом, XP bar и streak.
  Widget _buildHeroSection(ThemeData theme, ZenStyles zen, bool isCompact) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: zen.focusGradient,
        borderRadius: BorderRadius.circular(zen.cardRadius),
      ),
      padding: EdgeInsets.all(zen.spacingUnit * 3),
      child: Column(
        children: [
          // =====================================================
          // Профиль пользователя (аватар + имя / кнопка входа)
          // =====================================================
          _buildProfileRow(theme, zen),

          SizedBox(height: zen.gap(2)), // 16px

          // Ранг + иконка
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RankIcon(level: _progression.level, size: isCompact ? 36 : 48),
              SizedBox(width: zen.spacingUnit * 2),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _progression.rank,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontSize: isCompact ? 18 : 22,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Уровень ${_progression.level}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!isCompact) ...[
            SizedBox(height: zen.gap(3)), // 24px

            // XP Progress Bar
            _buildXpBar(theme, zen),

            SizedBox(height: zen.gap(2)), // 16px

            // Streak
            _buildStreakRow(theme, zen),
          ],
        ],
      ),
    );
  }

  /// XP Progress Bar с анимированным заполнением.
  Widget _buildXpBar(ThemeData theme, ZenStyles zen) {
    return Column(
      children: [
        // Шкала прогресса
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _xpProgress.progress),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 12,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.9),
                ),
              );
            },
          ),
        ),
        SizedBox(height: zen.spacingUnit),
        // Текст прогресса
        Text(
          'Осталось ${_xpProgress.remainingMinutes} мин до следующего уровня',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  /// Строка с streak (серия дней).
  Widget _buildStreakRow(ThemeData theme, ZenStyles zen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.local_fire_department,
          color: Colors.orange[300],
          size: 24,
        ),
        SizedBox(width: zen.spacingUnit),
        Text(
          '${_progression.streak} дней подряд',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Пресеты длительности вместо Slider.
  Widget _buildDurationPresets(ThemeData theme, ZenStyles zen) {
    return Column(
      children: [
        Text(
          'Выбери длительность:',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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

  /// Строка профиля: аватар + имя (если авторизован) или кнопка "Войти".
  Widget _buildProfileRow(ThemeData theme, ZenStyles zen) {
    final auth = AppServiceLocator.instance.authService;

    if (_isAuthenticated && auth != null) {
      final name = auth.displayName ?? 'Пользователь';
      final photoUrl = auth.photoUrl;

      return Row(
        children: [
          // Аватар
          CircleAvatar(
            radius: 18,
            backgroundImage:
                photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Icon(Icons.person, size: 20, color: Colors.white)
                : null,
          ),
          SizedBox(width: zen.spacingUnit * 1.5),
          // Имя пользователя
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Кнопка выхода
          SizedBox(
            height: 32,
            child: TextButton(
              onPressed: _handleSignOut,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Выйти',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      );
    }

    // Не авторизован — показываем кнопку "Войти"
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.account_circle_outlined,
          size: 20,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        SizedBox(width: zen.spacingUnit),
        Flexible(
          child: TextButton(
            onPressed: _navigateToAuth,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.9),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Войти через Google',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
