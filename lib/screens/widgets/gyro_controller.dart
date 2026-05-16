import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Контроллер гироскопа для 3D-параллакса на мобильных устройствах.
///
/// Использует low-pass filter для сглаживания тремора рук.
/// Возвращает нормализованные значения наклона в диапазоне [-0.15, 0.15].
///
/// **Важно:** Импортируется только на мобильных платформах.
/// На Web/Desktop используется [MouseTiltController].
class GyroController {
  StreamSubscription<GyroscopeEvent>? _subscription;

  double _smoothedX = 0;
  double _smoothedY = 0;

  /// Коэффициент low-pass фильтра (0.0–1.0).
  /// Чем ниже, тем сильнее сглаживание.
  static const double _filterFactor = 0.15;

  /// Максимальное смещение по осям.
  static const double _maxTilt = 0.15;

  /// Запускает прослушивание гироскопа.
  ///
  /// [onUpdate] вызывается с нормализованными значениями (tiltX, tiltY).
  void start(void Function(double x, double y) onUpdate) {
    _subscription?.cancel();

    _subscription = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen(
      (event) {
        // Low-pass filter: smoothed = smoothed * (1 - alpha) + raw * alpha
        _smoothedX = _smoothedX * (1 - _filterFactor) + event.x * _filterFactor;
        _smoothedY = _smoothedY * (1 - _filterFactor) + event.y * _filterFactor;

        // Clamp to max tilt range
        final tiltX = _smoothedX.clamp(-_maxTilt, _maxTilt);
        final tiltY = _smoothedY.clamp(-_maxTilt, _maxTilt);

        onUpdate(tiltX, tiltY);
      },
      onError: (error) {
        debugPrint('GyroController error: $error');
      },
    );
  }

  /// Останавливает прослушивание и освобождает ресурсы.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
