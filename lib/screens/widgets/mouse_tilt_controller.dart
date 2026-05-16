import 'package:flutter/material.dart';

/// Контроллер эффекта «Магнитного Тилта» для Desktop/Web.
///
/// На основе координат курсора мыши относительно центра виджета
/// рассчитывает углы наклона плоскости и применяет Lerp-сглаживание
/// для плавного 3D-следования за указателем.
class MouseTiltController extends ChangeNotifier {
  Matrix4 _transform = Matrix4.identity();
  Matrix4 get transform => _transform;

  /// Целевая матрица для Lerp-интерполяции.
  Matrix4 _target = Matrix4.identity();

  /// Коэффициент сглаживания (0.0–1.0). Чем ниже, тем плавнее.
  static const double _smoothFactor = 0.08;

  /// Максимальный угол наклона в радианах.
  static const double _maxAngle = 0.1;

  /// Обновляет трансформацию на основе позиции курсора.
  ///
  /// [localPosition] — координаты курсора относительно виджета.
  /// [widgetSize] — размер виджета.
  void update(Offset localPosition, Size widgetSize) {
    final center = Offset(widgetSize.width / 2, widgetSize.height / 2);

    // Нормализация координат относительно центра: -1..1
    final dx = (localPosition.dx - center.dx) / center.dx;
    final dy = (localPosition.dy - center.dy) / center.dy;

    // Расчёт целевой матрицы наклона
    _target = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Перспектива
      ..rotateX(-dy * _maxAngle)
      ..rotateY(dx * _maxAngle);

    // Lerp-сглаживание
    _lerpTransform();

    notifyListeners();
  }

  /// Плавный возврат в исходное положение при уходе курсора.
  void reset() {
    _target = Matrix4.identity();
    _lerpTransform();
    notifyListeners();
  }

  void _lerpTransform() {
    final result = Matrix4.identity();
    for (int i = 0; i < 16; i++) {
      result[i] = _transform[i] * (1 - _smoothFactor) + _target[i] * _smoothFactor;
    }
    _transform = result;
  }

}
