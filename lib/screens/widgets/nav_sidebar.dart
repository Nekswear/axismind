import 'package:flutter/material.dart';

import '../../core/theme/zen_theme.dart';
import '../../core/version_info.dart';

/// Навигационный элемент боковой панели.
class _NavItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// Узкая боковая панель навигации для Desktop/Web.
///
/// Содержит:
/// - Верхняя группа: логотип/аватар пользователя
/// - Средняя группа: пункты навигации (Практика, Дневник, Статистика, Гид)
/// - Нижняя группа: версия приложения
///
/// Активный пункт подсвечивается золотой левой полоской.
class NavSidebar extends StatelessWidget {
  /// Индекс активного пункта (0 = Практика).
  final int activeIndex;

  final VoidCallback onPracticeTap;
  final VoidCallback onJournalTap;
  final VoidCallback onStatisticsTap;
  final VoidCallback onGuideTap;
  final VoidCallback? onNotificationSettingsTap;

  const NavSidebar({
    super.key,
    this.activeIndex = 0,
    required this.onPracticeTap,
    required this.onJournalTap,
    required this.onStatisticsTap,
    required this.onGuideTap,
    this.onNotificationSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(
        icon: Icons.self_improvement,
        label: 'Практика',
        onTap: onPracticeTap,
      ),
      _NavItem(
        icon: Icons.book_outlined,
        label: 'Дневник',
        onTap: onJournalTap,
      ),
      _NavItem(
        icon: Icons.bar_chart_outlined,
        label: 'Статистика',
        onTap: onStatisticsTap,
      ),
      _NavItem(
        icon: Icons.explore_outlined,
        label: 'Путь к ясности',
        onTap: onGuideTap,
      ),
    ];

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: ZenColors.surface.withValues(alpha: 0.3),
        border: Border(
          right: BorderSide(
            color: ZenColors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Верхняя группа: логотип
          const SizedBox(height: 24),
          _buildLogo(),
          const SizedBox(height: 32),

          // Средняя группа: навигация
          ...List.generate(items.length, (i) {
            final item = items[i];
            final isActive = i == activeIndex;
            return _buildNavItem(
              icon: item.icon,
              label: item.label,
              isActive: isActive,
              onTap: item.onTap,
            );
          }),

          const Spacer(),

          // Нижняя группа: уведомления и версия
          if (onNotificationSettingsTap != null)
            _buildNavItem(
              icon: Icons.notifications_outlined,
              label: 'Уведомления',
              isActive: false,
              onTap: onNotificationSettingsTap!,
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              VersionInfo.displayVersion,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 9,
                color: ZenColors.textMuted,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            ZenColors.gold,
            ZenColors.goldLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Z',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ZenColors.background,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: label,
        preferBelow: false,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 56,
            decoration: BoxDecoration(
              border: isActive
                  ? const Border(
                      left: BorderSide(
                        color: ZenColors.gold,
                        width: 3,
                      ),
                    )
                  : null,
              color: isActive
                  ? ZenColors.gold.withValues(alpha: 0.08)
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isActive
                      ? ZenColors.gold
                      : ZenColors.textMuted,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 8,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive
                        ? ZenColors.gold
                        : ZenColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
