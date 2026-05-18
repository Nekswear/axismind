import 'package:flutter/material.dart';

import '../../core/theme/zen_theme.dart';
import '../../domain/progress_calculator.dart';

// =============================================================================
// RankRoadmap — визуальная дорожная карта всех рангов
// =============================================================================
//
// Показывает все 11 тиров от "Новичок осознанности" до "Божественный"
// в виде вертикального списка с коннекторами. Текущий ранг подсвечен,
// пройденные — с галочкой, будущие — затемнены.
//
// Анимация: Staggered-появление снизу вверх.
// Интерактивность: Tap на тир → BottomSheet с деталями.
// =============================================================================

/// Статус тира относительно текущего уровня пользователя.
enum RankTierStatus {
  /// Уровень пользователя выше максимального уровня тира — ранг пройден.
  completed,

  /// Уровень пользователя находится в диапазоне тира — текущий ранг.
  current,

  /// Уровень пользователя ниже минимального уровня тира — ранг ещё не доступен.
  locked,
}

/// Определяет статус тира на основе текущего уровня.
RankTierStatus _statusForTier(RankTier tier, int currentLevel) {
  if (tier.maxLevel != null && currentLevel > tier.maxLevel!) {
    return RankTierStatus.completed;
  }
  if (currentLevel >= tier.minLevel) {
    if (tier.maxLevel == null || currentLevel <= tier.maxLevel!) {
      return RankTierStatus.current;
    }
  }
  return RankTierStatus.locked;
}

/// Roadmap всех рангов — модальный bottom sheet или диалог.
class RankRoadmap extends StatefulWidget {
  /// Текущий уровень пользователя.
  final int currentLevel;

  /// Общее количество минут медитации.
  final int totalMinutes;

  const RankRoadmap({
    super.key,
    required this.currentLevel,
    required this.totalMinutes,
  });

  /// Показывает Roadmap как модальный bottom sheet (mobile) или диалог (desktop).
  static Future<void> show(BuildContext context, {
    required int currentLevel,
    required int totalMinutes,
  }) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: RankRoadmap(
            currentLevel: currentLevel,
            totalMinutes: totalMinutes,
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RankRoadmap(
        currentLevel: currentLevel,
        totalMinutes: totalMinutes,
      ),
    );
  }

  @override
  State<RankRoadmap> createState() => _RankRoadmapState();
}

class _RankRoadmapState extends State<RankRoadmap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _itemAnimations;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    final tiers = ProgressCalculator.allTiers;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Staggered-анимация: каждый элемент появляется с задержкой
    _itemAnimations = List.generate(tiers.length, (i) {
      final start = i * 0.05;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, start + 0.3, curve: Curves.easeOutCubic),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;
    final tiers = ProgressCalculator.allTiers;

    // Определяем высоту в зависимости от платформы
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final maxHeight = isDesktop
        ? MediaQuery.of(context).size.height * 0.85
        : MediaQuery.of(context).size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: ZenColors.surface,
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(32),
          bottom: isDesktop ? const Radius.circular(32) : Radius.zero,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle (только для bottom sheet)
          if (!isDesktop)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ZenColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

          // Заголовок
          Padding(
            padding: EdgeInsets.fromLTRB(
              zen.spacingUnit * 3,
              isDesktop ? zen.spacingUnit * 3 : zen.spacingUnit,
              zen.spacingUnit * 3,
              zen.spacingUnit,
            ),
            child: Row(
              children: [
                Text(
                  '🗺️',
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(width: zen.spacingUnit),
                Expanded(
                  child: Text(
                    'Roadmap рангов',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: ZenColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: ZenColors.textSecondary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Подзаголовок с прогрессом
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: zen.spacingUnit * 3,
            ),
            child: Row(
              children: [
                Text(
                  'Уровень ${widget.currentLevel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ZenColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 12,
                  color: ZenColors.textMuted.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatMinutes(widget.totalMinutes),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ZenColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: zen.spacingUnit * 2),

          // Список тиров
          Flexible(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: zen.spacingUnit * 2,
              ),
              itemCount: tiers.length,
              itemBuilder: (context, index) {
                final tier = tiers[index];
                final status = _statusForTier(tier, widget.currentLevel);
                final isLast = index == tiers.length - 1;

                return AnimatedBuilder(
                  animation: _itemAnimations[index],
                  builder: (context, child) {
                    return Opacity(
                      opacity: _itemAnimations[index].value,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          30 * (1 - _itemAnimations[index].value),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: _TierRow(
                    tier: tier,
                    status: status,
                    isLast: isLast,
                    currentLevel: widget.currentLevel,
                    totalMinutes: widget.totalMinutes,
                  ),
                );
              },
            ),
          ),

          // Footer
          Padding(
            padding: EdgeInsets.all(zen.spacingUnit * 2),
            child: Text(
              'Продолжайте практику, чтобы открыть новые ранги',
              style: theme.textTheme.bodySmall?.copyWith(
                color: ZenColors.textMuted,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes >= 1000) {
      final thousands = (minutes / 1000).toStringAsFixed(1);
      return '$thousands тыс. мин всего';
    }
    return '$minutes мин всего';
  }
}

// =============================================================================
// _TierRow — одна строка тира в Roadmap
// =============================================================================

class _TierRow extends StatelessWidget {
  final RankTier tier;
  final RankTierStatus status;
  final bool isLast;
  final int currentLevel;
  final int totalMinutes;

  const _TierRow({
    required this.tier,
    required this.status,
    required this.isLast,
    required this.currentLevel,
    required this.totalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isCompleted = status == RankTierStatus.completed;
    final isCurrent = status == RankTierStatus.current;
    final isLocked = status == RankTierStatus.locked;

    final opacity = isLocked ? 0.35 : 1.0;
    final bgColor = isCurrent
        ? ZenColors.gold.withValues(alpha: 0.08)
        : Colors.transparent;
    final borderColor = isCurrent
        ? ZenColors.gold.withValues(alpha: 0.4)
        : Colors.transparent;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: () => _showTierDetails(context),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Левая колонка: коннектор + иконка
              SizedBox(
                width: 56,
                child: Column(
                  children: [
                    // Коннектор сверху
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isCompleted
                              ? ZenColors.gold.withValues(alpha: 0.3)
                              : ZenColors.textMuted.withValues(alpha: 0.15),
                        ),
                      )
                    else
                      const Spacer(),
                    // Иконка статуса
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? ZenColors.gold.withValues(alpha: 0.15)
                            : isCurrent
                                ? ZenColors.gold.withValues(alpha: 0.2)
                                : ZenColors.textMuted.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(
                                color: ZenColors.gold,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: ZenColors.gold,
                              )
                            : isCurrent
                                ? Text(
                                    tier.emoji,
                                    style: const TextStyle(fontSize: 16),
                                  )
                                : const Icon(
                                    Icons.lock_rounded,
                                    size: 16,
                                    color: ZenColors.textMuted,
                                  ),
                      ),
                    ),
                    // Коннектор снизу
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isCompleted
                            ? ZenColors.gold.withValues(alpha: 0.3)
                            : ZenColors.textMuted.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),

              // Правая колонка: контент тира
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Эмодзи (только для текущего/заблокированного)
                          if (!isCompleted) ...[
                            Text(
                              tier.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // Название
                          Expanded(
                            child: Text(
                              tier.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isCurrent
                                    ? ZenColors.gold
                                    : ZenColors.textPrimary,
                                fontSize: 15,
                                fontWeight:
                                    isCurrent ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                          ),
                          // Бейдж "Вы здесь"
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ZenColors.gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Вы здесь',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: ZenColors.gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Описание
                      Text(
                        tier.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isCurrent
                              ? ZenColors.textSecondary
                              : ZenColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Уровни и минуты
                      Row(
                        children: [
                          Icon(
                            Icons.stairs_rounded,
                            size: 14,
                            color: isCurrent
                                ? ZenColors.gold.withValues(alpha: 0.7)
                                : ZenColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tier.levelRange,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isCurrent
                                  ? ZenColors.gold.withValues(alpha: 0.7)
                                  : ZenColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: isCurrent
                                ? ZenColors.gold.withValues(alpha: 0.7)
                                : ZenColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tier.minutesFormatted,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isCurrent
                                  ? ZenColors.gold.withValues(alpha: 0.7)
                                  : ZenColors.textMuted,
                              fontSize: 11,
                            ),
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
    );
  }

  /// Показывает детальную информацию о тире в BottomSheet.
  void _showTierDetails(BuildContext context) {
    final theme = Theme.of(context);
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;

    final isCompleted = status == RankTierStatus.completed;
    final isCurrent = status == RankTierStatus.current;

    // Рассчитываем прогресс до следующего тира (если текущий)
    int? progressPercent;
    int? remainingMinutes;
    if (isCurrent) {
      final tiers = ProgressCalculator.allTiers;
      final currentIndex = tiers.indexOf(tier);
      if (currentIndex < tiers.length - 1) {
        final nextTier = tiers[currentIndex + 1];
        final currentTierMin = tier.minLevel;
        final nextTierMin = nextTier.minLevel;
        final levelRange = nextTierMin - currentTierMin;
        final levelProgress = currentLevel - currentTierMin;
        progressPercent = ((levelProgress / levelRange) * 100).round();
        // Примерное количество минут до следующего тира
        final minutesInCurrentTier = totalMinutes - tier.minutesRequired;
        final minutesToNext = nextTier.minutesRequired - tier.minutesRequired;
        remainingMinutes = minutesToNext - minutesInCurrentTier;
        if (remainingMinutes < 0) remainingMinutes = 0;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(zen.spacingUnit * 3),
        decoration: const BoxDecoration(
          color: ZenColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: ZenColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Эмодзи + статус
            Text(
              tier.emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 12),

            // Название
            Text(
              tier.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: isCurrent ? ZenColors.gold : ZenColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Статус
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withValues(alpha: 0.15)
                    : isCurrent
                        ? ZenColors.gold.withValues(alpha: 0.15)
                        : ZenColors.textMuted.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isCompleted
                    ? '✅ Пройден'
                    : isCurrent
                        ? '⭐ Текущий ранг'
                        : '🔒 Ещё не доступен',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isCompleted
                      ? Colors.green[300]
                      : isCurrent
                          ? ZenColors.gold
                          : ZenColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Описание
            Text(
              tier.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: ZenColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Детали
            _DetailRow(
              icon: Icons.stairs_rounded,
              label: 'Уровни',
              value: tier.levelRange,
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.timer_outlined,
              label: 'Требуется практики',
              value: tier.minutesFormatted,
            ),

            if (isCurrent && progressPercent != null) ...[
              const SizedBox(height: 16),
              // Прогресс до следующего тира
              Row(
                children: [
                  Text(
                    'Прогресс до следующего ранга',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ZenColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progressPercent / 100,
                  minHeight: 10,
                  backgroundColor: ZenColors.textMuted.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ZenColors.gold.withValues(alpha: 0.9),
                  ),
                ),
              ),
              if (remainingMinutes != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Осталось ~$remainingMinutes мин до следующего ранга',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ZenColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ],

            const SizedBox(height: 20),

            // Кнопка закрытия
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZenColors.gold,
                  foregroundColor: ZenColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Закрыть'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _DetailRow — строка с иконкой, меткой и значением
// =============================================================================

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: ZenColors.gold.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: ZenColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: ZenColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
