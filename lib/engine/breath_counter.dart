// =============================================================================
// BreathCounter — логика счётчика дыхания Сусокукан
// =============================================================================
//
// Использует ValueNotifier<int> для реактивного обновления UI.
// Начальное значение: 1. Счёт идёт вверх до 10, затем вниз до 1, и так далее.
//
// Использование:
//   final counter = BreathCounter();
//   counter.addListener(() => print(counter.value));
//   counter.exhale();   // увеличить счёт
//   counter.reset();    // сбросить к 1
// =============================================================================

import 'package:flutter/foundation.dart';

/// Направление счёта.
enum BreathDirection {
  /// Прямой счёт: 1 → 2 → ... → 10
  up,

  /// Обратный счёт: 10 → 9 → ... → 1
  down,
}

/// Счётчик дыхания с [ValueNotifier].
///
/// - Начальное значение: `1`
/// - При достижении 10 направление меняется на обратное
/// - При достижении 1 направление меняется на прямое
/// - Метод [reset] возвращает к 1 и устанавливает направление `up`
class BreathCounter extends ValueNotifier<int> {
  BreathCounter() : super(1);

  /// Текущее направление счёта.
  BreathDirection _direction = BreathDirection.up;
  BreathDirection get direction => _direction;

  /// Увеличить счёт согласно текущему направлению.
  ///
  /// Если значение выходит за границы [1, 10] — направление меняется.
  void exhale() {
    if (_direction == BreathDirection.up) {
      if (value < 10) {
        value++;
      } else {
        _direction = BreathDirection.down;
        value--;
      }
    } else {
      if (value > 1) {
        value--;
      } else {
        _direction = BreathDirection.up;
        value++;
      }
    }
  }

  /// Сбросить счёт к 1 и установить направление вверх.
  void reset() {
    _direction = BreathDirection.up;
    value = 1;
  }
}
