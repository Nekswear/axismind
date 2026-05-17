import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/zen_theme.dart';
import 'nav_sidebar.dart';
import 'neuro_preset_info.dart';

/// Widescreen Split-Layout для Desktop/Web (ширина > 800px).
///
/// Содержит:
/// - [NavSidebar] слева (72px) — навигация по разделам
/// - Левая панель (flex: 4) — вертикальный ряд кнопок пресетов времени
/// - Правая панель (flex: 6) — медитативное пространство визуализации
///   с золотым градиентом и нейробиологическим текстом
class WidescreenLayout extends StatefulWidget {
  final double durationMinutes;
  final ValueChanged<double> onDurationChanged;
  final VoidCallback onStartPractice;
  final VoidCallback onJournalTap;
  final VoidCallback onStatisticsTap;
  final VoidCallback onGuideTap;

  /// Пользователь авторизован через Google?
  final bool isAuthenticated;

  /// Колбэк для открытия экрана входа.
  final VoidCallback? onAuthTap;

  /// Отображаемое имя пользователя (если авторизован).
  final String? displayName;

  /// URL аватара пользователя (если авторизован).
  final String? photoUrl;

  const WidescreenLayout({
    super.key,
    required this.durationMinutes,
    required this.onDurationChanged,
    required this.onStartPractice,
    required this.onJournalTap,
    required this.onStatisticsTap,
    required this.onGuideTap,
    this.isAuthenticated = false,
    this.onAuthTap,
    this.displayName,
    this.photoUrl,
  });

  @override
  State<WidescreenLayout> createState() => _WidescreenLayoutState();
}

class _WidescreenLayoutState extends State<WidescreenLayout> {
  int _hoveredMinutes = 5;

  static const _presets = [
    (minutes: 5, icon: Icons.coffee_outlined, label: 'Быстрая', subtitle: 'Перерыв'),
    (minutes: 10, icon: Icons.self_improvement, label: 'Стандарт', subtitle: 'Ежедневная'),
    (minutes: 15, icon: Icons.water_drop_outlined, label: 'Глубокая', subtitle: 'Вечерняя'),
    (minutes: 20, icon: Icons.auto_awesome_outlined, label: 'Мастер', subtitle: 'Выходная'),
  ];

  @override
  Widget build(BuildContext context) {
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;
    final theme = Theme.of(context);

    return Row(
      children: [
        // === Боковая панель навигации ===
        NavSidebar(
          activeIndex: 0,
          onPracticeTap: () {}, // уже на практике
          onJournalTap: widget.onJournalTap,
          onStatisticsTap: widget.onStatisticsTap,
          onGuideTap: widget.onGuideTap,
        ),

        // === Левая панель (40%) ===
        Expanded(
          flex: 4,
          child: Container(
            padding: EdgeInsets.all(zen.spacingUnit * 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Выбери длительность',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: ZenColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: zen.gap(4)),
                ..._presets.map((p) => _buildPresetButton(
                  zen: zen,
                  theme: theme,
                  minutes: p.minutes,
                  icon: p.icon,
                  label: p.label,
                  subtitle: p.subtitle,
                  isSelected: widget.durationMinutes == p.minutes,
                  isHovered: _hoveredMinutes == p.minutes,
                  onTap: () => widget.onDurationChanged(p.minutes.toDouble()),
                  onHover: (hovered) {
                    if (hovered) {
                      setState(() => _hoveredMinutes = p.minutes);
                    }
                  },
                )),
                // Кнопка входа / информация о пользователе
                _buildAuthSection(zen, theme),
                SizedBox(height: zen.gap(2)),
                // CTA-кнопка
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: widget.onStartPractice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ZenColors.gold,
                      foregroundColor: ZenColors.background,
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
              ],
            ),
          ),
        ),

        // === Разделитель ===
        Container(
          width: 1,
          color: ZenColors.border,
        ),

        // === Правая панель (60%) ===
        Expanded(
          flex: 6,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return ClipRect(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: 0,
                    sigmaY: 8 * (1 - animation.value),
                  ),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                ),
              );
            },
            child: _buildRightPanel(zen, theme, key: ValueKey('panel_$_hoveredMinutes')),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthSection(ZenStyles zen, ThemeData theme) {
    if (widget.isAuthenticated) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.photoUrl != null)
            CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(widget.photoUrl!),
            )
          else
            CircleAvatar(
              radius: 14,
              backgroundColor: ZenColors.gold.withValues(alpha: 0.2),
              child: Icon(Icons.person, size: 16, color: ZenColors.gold),
            ),
          const SizedBox(width: 8),
          Text(
            widget.displayName ?? 'Пользователь',
            style: theme.textTheme.bodySmall?.copyWith(
              color: ZenColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    if (widget.onAuthTap == null) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: widget.onAuthTap,
        icon: const Icon(Icons.login, size: 16),
        label: const Text(
          'Войти через Google',
          style: TextStyle(fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: ZenColors.gold,
          side: BorderSide(
            color: ZenColors.gold.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanel(ZenStyles zen, ThemeData theme, {required Key key}) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            ZenColors.gold.withValues(alpha: 0.15),
            Colors.transparent,
          ],
          radius: 1.5,
          center: Alignment.center,
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(zen.spacingUnit * 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Крупное время
              Text(
                '$_hoveredMinutes мин',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 96,
                  fontWeight: FontWeight.w200,
                  color: ZenColors.gold.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: zen.gap(4)),
              // Нейробиологическое обоснование
              NeuroPresetInfo(minutes: _hoveredMinutes),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton({
    required ZenStyles zen,
    required ThemeData theme,
    required int minutes,
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
    required bool isHovered,
    required VoidCallback onTap,
    required ValueChanged<bool> onHover,
  }) {
    final isActive = isSelected || isHovered;

    return Padding(
      padding: EdgeInsets.only(bottom: zen.spacingUnit * 2),
      child: MouseRegion(
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(
              vertical: zen.spacingUnit * 2,
              horizontal: zen.spacingUnit * 3,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? ZenColors.gold.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? ZenColors.gold.withValues(alpha: 0.3)
                    : ZenColors.border,
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? ZenColors.gold : ZenColors.textMuted,
                  size: 24,
                ),
                SizedBox(width: zen.spacingUnit * 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$minutes мин — $label',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive
                              ? ZenColors.textPrimary
                              : ZenColors.textSecondary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ZenColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: ZenColors.gold,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
