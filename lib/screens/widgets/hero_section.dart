import 'package:flutter/material.dart';

import '../../core/theme/zen_theme.dart';
import '../../core/widgets/zen_ui.dart';
import '../../data/analytics_repository.dart';

/// Hero section with gradient card, rank icon, XP bar, and streak.
class HeroSection extends StatelessWidget {
  final UserProgression progression;
  final XpProgress xp;
  final int streak;

  const HeroSection({
    super.key,
    required this.progression,
    required this.xp,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: zen.focusGradient,
        borderRadius: BorderRadius.circular(zen.cardRadius),
      ),
      padding: EdgeInsets.all(zen.spacingUnit * 3),
      child: Column(
        children: [
          // Rank + icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RankIcon(level: progression.level, size: 48),
              SizedBox(width: zen.spacingUnit * 2),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progression.rank,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Уровень ${progression.level}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: zen.gap(3)),
          // XP bar
          _buildXpBar(theme, zen, xp),
          SizedBox(height: zen.gap(2)),
          // Streak
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_fire_department,
                color: Colors.orange[300],
                size: 24,
              ),
              SizedBox(width: zen.spacingUnit),
              Text(
                '$streak дней подряд',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildXpBar(ThemeData theme, ZenStyles zen, XpProgress xp) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: xp.progress),
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
        Text(
          'Осталось ${xp.remainingMinutes} мин до следующего уровня',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
