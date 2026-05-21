import 'package:flutter/material.dart';

import '../core/theme/zen_theme.dart';

/// Маленький золотой бейдж "PREMIUM".
///
/// Используется для отображения статуса подписки в UI:
/// - NavSidebar
/// - Экран статуса подписки
class PremiumBadge extends StatelessWidget {
  /// Размер бейджа.
  final double fontSize;

  /// Показывать иконку короны.
  final bool showIcon;

  const PremiumBadge({
    super.key,
    this.fontSize = 9,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ZenColors.gold, ZenColors.goldLight],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.auto_awesome,
              size: fontSize + 2,
              color: ZenColors.background,
            ),
            const SizedBox(width: 3),
          ],
          Text(
            'PREMIUM',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: ZenColors.background,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
