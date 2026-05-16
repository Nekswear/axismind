import 'package:flutter/material.dart';

/// Custom painter for the dot chart (activity dynamics).
///
/// Draws:
/// - Dashed average line
/// - Connecting lines between points
/// - Circle dots for each day
/// - Gradient fill under the line
class DotChartPainter extends CustomPainter {
  final List<Offset> points;
  final double averageY;
  final Color primaryColor;
  final Color surfaceColor;
  final Color onSurfaceColor;

  DotChartPainter({
    required this.points,
    required this.averageY,
    required this.primaryColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // 1. Dashed average line
    final dashPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, averageY),
        Offset((startX + dashWidth).clamp(0, size.width), averageY),
        dashPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // 2. Gradient fill under the line
    if (points.length >= 2) {
      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withValues(alpha: 0.12),
            primaryColor.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      final fillPath = Path();
      fillPath.moveTo(points.first.dx, 56);
      for (final point in points) {
        fillPath.lineTo(point.dx, point.dy);
      }
      fillPath.lineTo(points.last.dx, 56);
      fillPath.close();

      canvas.drawPath(fillPath, gradientPaint);
    }

    // 3. Connecting lines
    if (points.length >= 2) {
      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(linePath, linePaint);
    }

    // 4. Dots
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final isActive = point.dy < 54;

      if (isActive) {
        canvas.drawCircle(
          point,
          3.5,
          Paint()
            ..color = surfaceColor
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(point, 2.5, dotPaint);
      } else {
        canvas.drawCircle(
          point,
          1.5,
          Paint()
            ..color = onSurfaceColor.withValues(alpha: 0.15)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.averageY != averageY;
  }
}
