import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/zen_theme.dart';
import '../../utils/time_utils.dart';
import '../statistics_cubit.dart';
import 'chart_section.dart';
import 'heatmap_section.dart';
import 'hero_section.dart';
import 'summary_cards.dart';

/// Staggered-animated dashboard that composes all statistics sections.
///
/// This is a small [StatefulWidget] that manages staggered entrance
/// animations via [TickerProviderStateMixin]. It receives fully
/// pre-computed data from [StatisticsActive] and delegates to
/// stateless section widgets.
///
/// The hero section does NOT re-animate on period change — only
/// when the entire state is fresh (new [StatisticsActive] instance).
class StaggeredDashboard extends StatefulWidget {
  final StatisticsActive state;

  const StaggeredDashboard({super.key, required this.state});

  @override
  State<StaggeredDashboard> createState() => _StaggeredDashboardState();
}

class _StaggeredDashboardState extends State<StaggeredDashboard>
    with TickerProviderStateMixin {
  late final List<AnimationController> _animControllers;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  /// Tracks whether animations have been started for the current state.
  bool _animationsStarted = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  @override
  void didUpdateWidget(StaggeredDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset and restart animations when state changes (new data loaded).
    // Period-only changes keep the same state reference pattern — we
    // detect via selectedPeriod change to avoid hero re-animation.
    if (oldWidget.state != widget.state) {
      _resetAnimations();
    }
  }

  @override
  void dispose() {
    for (final c in _animControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _initAnimations() {
    _animControllers = List.generate(6, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
    });
    _fadeAnimations = _animControllers.map((c) {
      return CurvedAnimation(parent: c, curve: Curves.easeOut);
    }).toList();
    _slideAnimations = _animControllers.map((c) {
      return Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic));
    }).toList();
  }

  void _resetAnimations() {
    _animationsStarted = false;
    for (final c in _animControllers) {
      c.reset();
    }
    _startStaggeredAnimation();
  }

  void _startStaggeredAnimation() {
    if (_animationsStarted) return;
    _animationsStarted = true;

    for (int i = 0; i < _animControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 80 * i), () {
        if (mounted) _animControllers[i].forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;
    final s = widget.state;

    // Start animations on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStaggeredAnimation();
    });

    return RefreshIndicator(
      onRefresh: () => context.read<StatisticsCubit>().refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: zen.spacingUnit * 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: zen.spacingUnit),

            // 1. Hero section
            _AnimatedSection(
              animation: _fadeAnimations[0],
              slideAnimation: _slideAnimations[0],
              child: HeroSection(
                progression: s.progression,
                xp: s.xpProgress,
                streak: s.streak,
              ),
            ),

            SizedBox(height: zen.gap(3)),

            // 2. Summary cards
            _AnimatedSection(
              animation: _fadeAnimations[1],
              slideAnimation: _slideAnimations[1],
              child: SummaryCards(
                totalMinutes: s.totalMinutes,
                sessionCount: s.sessionCount,
              ),
            ),

            SizedBox(height: zen.gap(3)),

            // 3. Streak + Growth mini-cards
            _AnimatedSection(
              animation: _fadeAnimations[2],
              slideAnimation: _slideAnimations[2],
              child: StreakGrowthCards(
                streak: s.streak,
                growth: s.growth,
                chartDays: _chartDays(s.selectedPeriod),
              ),
            ),

            SizedBox(height: zen.gap(4)),

            // 4. Heatmap
            _AnimatedSection(
              animation: _fadeAnimations[3],
              slideAnimation: _slideAnimations[3],
              child: HeatmapSection(
                data: s.heatmapData,
                maxMinutes: s.maxHeatmapMinutes,
                regularity: s.regularity,
                average: s.heatmapAverage,
                bestDay: s.bestDay,
                daysWithActivity: s.daysWithActivity,
              ),
            ),

            SizedBox(height: zen.gap(4)),

            // 5. Area Chart
            _AnimatedSection(
              animation: _fadeAnimations[4],
              slideAnimation: _slideAnimations[4],
              child: ChartSection(
                spots: s.chartSpots,
                dailyStats: s.dailyStats,
                chartMaxY: s.chartMaxY,
                peakIndices: s.peakIndices,
                chartAverage: s.chartAverage,
                selectedPeriod: s.selectedPeriod,
                onPeriodChanged: (period) {
                  context.read<StatisticsCubit>().changePeriod(period);
                },
              ),
            ),

            SizedBox(height: zen.gap(3)),

            // 6. Average metric
            _AnimatedSection(
              animation: _fadeAnimations[5],
              slideAnimation: _slideAnimations[5],
              child: _AverageMetric(
                average: s.averageMinutes,
              ),
            ),

            SizedBox(height: zen.gap(5)),
          ],
        ),
      ),
    );
  }

  int _chartDays(ChartPeriod period) => switch (period) {
        ChartPeriod.days7 => 7,
        ChartPeriod.days14 => 14,
        ChartPeriod.days30 => 30,
      };
}

// =============================================================================
// Animated section wrapper
// =============================================================================

class _AnimatedSection extends StatelessWidget {
  final Animation<double> animation;
  final Animation<Offset> slideAnimation;
  final Widget child;

  const _AnimatedSection({
    required this.animation,
    required this.slideAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
}

// =============================================================================
// Average metric block
// =============================================================================

class _AverageMetric extends StatelessWidget {
  final double average;

  const _AverageMetric({required this.average});

  @override
  Widget build(BuildContext context) {
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 0),
              child: TweenAnimationBuilder<double>(
                key: ValueKey(average),
                tween: Tween<double>(begin: 0, end: average),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Text(
                    TimeUtils.formatMinutes(value),
                    style: (theme.textTheme.headlineLarge ?? const TextStyle())
                        .copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: zen.metricWeight,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  );
                },
              ),
            ),
          ),
          SizedBox(height: zen.spacingUnit),
          Text(
            'в среднем в день',
            style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
