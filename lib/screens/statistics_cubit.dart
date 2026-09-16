import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:axismind/data/analytics_repository.dart';
import 'package:axismind/services/app_service_locator.dart';

// =============================================================================
// Period enum
// =============================================================================

/// Period for chart display.
enum ChartPeriod { days7, days14, days30 }

// =============================================================================
// Sealed state hierarchy
// =============================================================================

/// State machine for the statistics screen.
///
/// 4 distinct states:
/// - [StatisticsLoading] — initial load, shows shimmer
/// - [StatisticsActive] — data loaded successfully
/// - [StatisticsEmpty] — no sessions in selected period
/// - [StatisticsError] — exception during loading
sealed class StatisticsState {
  const StatisticsState();
}

/// Initial loading state — triggers ShimmerLoading in UI.
class StatisticsLoading extends StatisticsState {
  const StatisticsLoading();
}

/// Active state with fully pre-computed data.
///
/// All metrics are calculated in the Cubit; UI only renders.
class StatisticsActive extends StatisticsState {
  /// Pre-computed FlSpot list for the area chart.
  final List<FlSpot> chartSpots;

  /// Raw daily stats (for chart labels and tooltips).
  final List<DailyStats> dailyStats;

  /// Heatmap data for the mini-calendar.
  final List<HeatmapDay> heatmapData;

  /// Current streak (days in a row).
  final int streak;

  /// Relative growth (nullable).
  final double? growth;

  /// Total minutes across all time.
  final int totalMinutes;

  /// Total session count.
  final int sessionCount;

  /// XP progress to next level.
  final XpProgress xpProgress;

  /// User progression (level, rank, etc.).
  final UserProgression progression;

  /// Currently selected chart period.
  final ChartPeriod selectedPeriod;

  /// Average minutes per day in the chart period.
  final double averageMinutes;

  // -- Pre-computed heatmap statistics --------------------------------

  /// Regularity ratio (days with activity / total days).
  final double regularity;

  /// Average minutes per day (heatmap period).
  final double heatmapAverage;

  /// Best day in the heatmap period.
  final HeatmapDay? bestDay;

  /// Number of days with activity in the heatmap period.
  final int daysWithActivity;

  /// Max minutes in the heatmap period (for intensity normalization).
  final double maxHeatmapMinutes;

  // -- Pre-computed chart metadata ------------------------------------

  /// Max Y value for the chart (with padding).
  final double chartMaxY;

  /// Indices of peak values in the chart.
  final List<int> peakIndices;

  /// Average value for the chart reference line.
  final double chartAverage;

  const StatisticsActive({
    required this.chartSpots,
    required this.dailyStats,
    required this.heatmapData,
    required this.streak,
    this.growth,
    required this.totalMinutes,
    required this.sessionCount,
    required this.xpProgress,
    required this.progression,
    required this.selectedPeriod,
    required this.averageMinutes,
    required this.regularity,
    required this.heatmapAverage,
    this.bestDay,
    required this.daysWithActivity,
    required this.maxHeatmapMinutes,
    required this.chartMaxY,
    required this.peakIndices,
    required this.chartAverage,
  });
}

/// Empty state — no sessions found for the selected period.
class StatisticsEmpty extends StatisticsState {
  const StatisticsEmpty();
}

/// Error state with a human-readable message.
class StatisticsError extends StatisticsState {
  final String message;

  const StatisticsError(this.message);
}

// =============================================================================
// Cubit
// =============================================================================

/// Cubit managing the statistics screen state machine.
///
/// Responsibilities:
/// - Load data from [AnalyticsRepository]
/// - Pre-compute all metrics (spots, averages, peaks, etc.)
/// - Handle period switching without resetting hero animation
/// - Expose [refresh] for pull-to-refresh and retry
class StatisticsCubit extends Cubit<StatisticsState> {
  StatisticsCubit() : super(const StatisticsLoading());

  AnalyticsRepository? _repository;
  ChartPeriod _selectedPeriod = ChartPeriod.days7;

  int get _chartDays => switch (_selectedPeriod) {
        ChartPeriod.days7 => 7,
        ChartPeriod.days14 => 14,
        ChartPeriod.days30 => 30,
      };

  /// Full statistics load — used for init, pull-to-refresh, and retry.
  Future<void> loadStatistics() async {
    emit(const StatisticsLoading());

    try {
      final locator = AppServiceLocator.instance;
      final syncRepo = locator.syncRepo;
      if (syncRepo == null) {
        throw Exception('SyncRepository не инициализирован');
      }
      
      _repository = AnalyticsRepository(syncRepo);
      
      // Безопасная инициализация goalsRepo, если она есть в локаторе
      try {
        _repository!.goalsRepo = locator.goalsRepo;
      } catch (_) {
        // Пропускаем, если цель репозитория отсутствует в данном контексте
      }

      final now = DateTime.now();
      final days = _chartDays;
      final start = DateTime(now.year, now.month, now.day - (days - 1));
      final range = DateRange(start: start, end: now);

      final result = await _repository!.fetchStatistics(range, chartDays: days);
      final dto = result.data;

      if (!dto.hasData) {
        emit(const StatisticsEmpty());
        return;
      }

      emit(_buildActiveState(dto));
    } catch (e) {
      if (e.toString().contains('StaleRequest')) return;

      final message = _formatError(e);
      emit(StatisticsError(message));
    }
  }

  /// Lightweight chart data reload when period changes.
  /// Does NOT emit [StatisticsLoading] — preserves hero animation.
  Future<void> changePeriod(ChartPeriod period) async {
    _selectedPeriod = period;

    if (_repository == null) return;

    try {
      final now = DateTime.now();
      final days = _chartDays;
      final start = DateTime(now.year, now.month, now.day - (days - 1));
      final range = DateRange(start: start, end: now);

      final result = await _repository!.fetchStatistics(range, chartDays: days);
      final dto = result.data;

      if (!dto.hasData) {
        emit(const StatisticsEmpty());
        return;
      }

      emit(_buildActiveState(dto));
    } catch (e) {
      if (e.toString().contains('StaleRequest')) return;
      debugPrint('Ошибка обновления графика: $e');
    }
  }

  /// Pull-to-refresh — full reload.
  Future<void> refresh() => loadStatistics();

  // ===========================================================================
  // Private helpers
  // ===========================================================================

  /// Builds [StatisticsActive] from [ExtendedStatisticsDTO] with all
  /// pre-computed values.
  StatisticsActive _buildActiveState(ExtendedStatisticsDTO dto) {
    final stats = dto.dailyStats;

    // -- Chart spots ----------------------------------------------------------
    final maxY = stats.fold<double>(
      0.0,
      (max, s) => s.minutes > max ? s.minutes : max,
    );
    final chartMaxY = (maxY < 5 ? 5.0 : maxY) * 1.3;

    final peakIndices = <int>{};
    if (maxY > 0) {
      for (int i = 0; i < stats.length; i++) {
        if (stats[i].minutes == maxY) {
          peakIndices.add(i);
        }
      }
    }

    final spots = stats
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.minutes))
        .toList();

    final chartAverage = stats.isEmpty
        ? 0.0
        : stats.fold<double>(0.0, (sum, d) => sum + d.minutes) / stats.length;

    // -- Heatmap stats --------------------------------------------------------
    final heatmap = dto.heatmapData;
    final maxHeatmapMinutes = heatmap.fold<double>(
      0.0,
      (max, d) => d.minutes > max ? d.minutes : max,
    );
    final totalHeatmapMinutes =
        heatmap.fold<double>(0.0, (sum, d) => sum + d.minutes);
    final heatmapAverage =
        heatmap.isEmpty ? 0.0 : totalHeatmapMinutes / heatmap.length;
    final bestDay = heatmap.fold<HeatmapDay?>(null, (best, d) {
      if (best == null || d.minutes > best.minutes) return d;
      return best;
    });
    final daysWithActivity = heatmap.where((d) => d.minutes > 0).length;
    final regularity =
        heatmap.isEmpty ? 0.0 : daysWithActivity / heatmap.length;

    // -- Average minutes ------------------------------------------------------
    final averageMinutes = stats.isEmpty
        ? 0.0
        : stats.fold<double>(0.0, (sum, d) => sum + d.minutes) / stats.length;

    return StatisticsActive(
      chartSpots: spots,
      dailyStats: stats,
      heatmapData: heatmap,
      streak: dto.streak,
      growth: dto.growth,
      totalMinutes: dto.totalMinutes,
      sessionCount: dto.sessionCount,
      xpProgress: dto.xpProgress,
      progression: dto.progression,
      selectedPeriod: _selectedPeriod,
      averageMinutes: averageMinutes,
      regularity: regularity,
      heatmapAverage: heatmapAverage,
      bestDay: bestDay,
      daysWithActivity: daysWithActivity,
      maxHeatmapMinutes: maxHeatmapMinutes,
      chartMaxY: chartMaxY,
      peakIndices: peakIndices.toList(),
      chartAverage: chartAverage,
    );
  }

  /// Formats an exception into a user-friendly error message.
  String _formatError(Object e) {
    final message = e.toString();
    if (message.contains('SyncRepository')) {
      return 'Не удалось загрузить статистику. Попробуйте снова.';
    }
    if (message.contains('DatabaseException')) {
      return 'Ошибка базы данных. Перезапустите приложение.';
    }
    return 'Не удалось загрузить статистику. Попробуйте снова.';
  }
}