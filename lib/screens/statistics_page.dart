import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../l10n/app_localizations.dart';

import '../widgets/empty_dashboard.dart';
import '../widgets/error_view.dart';
import '../widgets/shimmer_loading.dart';
import 'statistics_cubit.dart';
import 'widgets/staggered_dashboard.dart';

/// Statistics screen with BLoC-driven state machine.
///
/// Uses [BlocProvider] + [BlocBuilder] with Dart 3 pattern matching
/// to switch between 4 states:
/// - [StatisticsLoading] → [ShimmerLoading]
/// - [StatisticsActive] → [StaggeredDashboard]
/// - [StatisticsEmpty] → [EmptyDashboard]
/// - [StatisticsError] → [ErrorView] with retry
///
/// This is a [StatelessWidget] — all business logic lives in [StatisticsCubit].
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StatisticsCubit()..loadStatistics(),
      child: const _StatisticsBody(),
    );
  }
}

/// Internal body widget that consumes [StatisticsCubit] state.
class _StatisticsBody extends StatelessWidget {
  const _StatisticsBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.statsTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: BlocBuilder<StatisticsCubit, StatisticsState>(
        builder: (context, state) {
          return switch (state) {
            StatisticsLoading() => const ShimmerLoading(),
            StatisticsActive s => StaggeredDashboard(state: s),
            StatisticsEmpty() => const EmptyDashboard(),
            StatisticsError e => ErrorView(
                message: e.message,
                onRetry: () => context.read<StatisticsCubit>().loadStatistics(),
              ),
          };
        },
      ),
    );
  }
}