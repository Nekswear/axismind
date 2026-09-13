import 'package:flutter_test/flutter_test.dart';
import 'package:axismind/engine/breath_counter.dart';

void main() {
  group('BreathCounter', () {
    test('initial value is 1, direction up', () {
      final counter = BreathCounter();
      expect(counter.value, equals(1));
      expect(counter.direction, equals(BreathDirection.up));
    });

    test('counts up to 10 after 9 exhales', () {
      final counter = BreathCounter();
      for (var i = 0; i < 9; i++) {
        counter.exhale();
      }
      expect(counter.value, equals(10));
      expect(counter.direction, equals(BreathDirection.up));
    });

    test('reverses at 10: value 9, direction down', () {
      final counter = BreathCounter();
      for (var i = 0; i < 10; i++) {
        counter.exhale();
      }
      expect(counter.value, equals(9));
      expect(counter.direction, equals(BreathDirection.down));
    });

    test('counts down to 1 after 18 exhales', () {
      final counter = BreathCounter();
      for (var i = 0; i < 18; i++) {
        counter.exhale();
      }
      expect(counter.value, equals(1));
      expect(counter.direction, equals(BreathDirection.down));
    });

    test('reverses at 1: value 2, direction up', () {
      final counter = BreathCounter();
      for (var i = 0; i < 19; i++) {
        counter.exhale();
      }
      expect(counter.value, equals(2));
      expect(counter.direction, equals(BreathDirection.up));
    });

    test('reset returns to 1 with direction up', () {
      final counter = BreathCounter();
      counter.exhale();
      counter.exhale();
      counter.exhale();
      counter.reset();
      expect(counter.value, equals(1));
      expect(counter.direction, equals(BreathDirection.up));
    });
  });
}
