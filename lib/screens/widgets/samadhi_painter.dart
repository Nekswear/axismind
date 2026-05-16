import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/zen_theme.dart';

/// CustomPainter для бесконечных концентрических кругов Самадхи.
///
/// Рисует 7 концентрических окружностей золотого цвета, плавно
/// пульсирующих из центра экрана с периодом в 8 секунд.
///
/// [progress] — 0.0..1.0, 8-секундный цикл пульсации.
/// [maxRadius] — максимальный радиус пульсации.
/// [collapseProgress] — 0.0..1.0, прогресс анимации схлопывания (400ms).
///   При 1.0 все круги стянуты в центр.
class SamadhiPainter extends CustomPainter {
  final double progress;
  final double maxRadius;
  final double collapseProgress;

  SamadhiPainter({
    required this.progress,
    required this.maxRadius,
    this.collapseProgress = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ZenColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final phase = progress * 2 * pi;

    // 7 концентрических кругов
    for (int i = 0; i < 7; i++) {
      // Базовая пульсация: sin от 0.7 до 1.0
      final pulseFactor = 0.7 + 0.3 * sin(phase - i * 0.4);

      // Радиус с учётом схлопывания
      final baseRadius = maxRadius * (0.15 + i * 0.12) * pulseFactor;
      final radius = baseRadius * (1 - collapseProgress);

      // Прозрачность: затухает к периферии и при схлопывании
      final opacityFactor = 1.0 - (i / 7) * 0.5;
      final collapseOpacity = 1.0 - collapseProgress;
      paint.color = ZenColors.gold.withValues(
        alpha: opacityFactor * collapseOpacity,
      );

      // Толщина линии: тоньше к периферии
      paint.strokeWidth = (1.5 - i * 0.15).clamp(0.3, 1.5) * (1 - collapseProgress * 0.5);

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(SamadhiPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.collapseProgress != collapseProgress ||
        oldDelegate.maxRadius != maxRadius;
  }
}
