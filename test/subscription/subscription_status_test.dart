// =============================================================================
// ZenBalance — Unit-тесты для SubscriptionStatus
// =============================================================================
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         ЗАПУСК ТЕСТОВ                                  ║
// ╠══════════════════════════════════════════════════════════════════════════╣
// ║  flutter test test/subscription/subscription_status_test.dart            ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Проверяет:
//   • Конструктор с параметрами по умолчанию
//   • isPremium геттер
//   • fromMap / toMap сериализация
//   • copyWith
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:zenbalance/data/subscription_status.dart';

void main() {
  group('SubscriptionStatus', () {
    test('должен создаваться с параметрами по умолчанию', () {
      final status = SubscriptionStatus(updatedAt: DateTime(2025, 1, 1));

      expect(status.id, 'default');
      expect(status.isActive, false);
      expect(status.isTrial, false);
      expect(status.expirationDate, isNull);
      expect(status.productId, isNull);
      expect(status.purchasedAt, isNull);
      expect(status.updatedAt, DateTime(2025, 1, 1));
    });

    test('isPremium должен возвращать isActive', () {
      final inactive = SubscriptionStatus(updatedAt: DateTime(2025, 1, 1));
      expect(inactive.isPremium, false);

      final active = SubscriptionStatus(
        isActive: true,
        updatedAt: DateTime(2025, 1, 1),
      );
      expect(active.isPremium, true);
    });

    test('toMap и fromMap должны быть обратными операциями', () {
      final original = SubscriptionStatus(
        id: 'default',
        isActive: true,
        isTrial: true,
        expirationDate: DateTime(2025, 6, 1),
        productId: 'test_product',
        purchasedAt: DateTime(2025, 5, 1),
        updatedAt: DateTime(2025, 5, 15),
      );

      final map = original.toMap();
      final restored = SubscriptionStatus.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.isActive, original.isActive);
      expect(restored.isTrial, original.isTrial);
      expect(restored.expirationDate, original.expirationDate);
      expect(restored.productId, original.productId);
      expect(restored.purchasedAt, original.purchasedAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('fromMap должен обрабатывать отсутствующие поля', () {
      final map = <String, dynamic>{};
      final status = SubscriptionStatus.fromMap(map);

      expect(status.id, 'default');
      expect(status.isActive, false);
      expect(status.isTrial, false);
      expect(status.expirationDate, isNull);
      expect(status.productId, isNull);
      expect(status.purchasedAt, isNull);
      expect(status.updatedAt, isNotNull);
    });

    test('fromMap должен обрабатывать числовые значения is_active и is_trial', () {
      final map = {
        'id': 'default',
        'is_active': 1,
        'is_trial': 0,
        'updated_at': '2025-01-01T00:00:00.000',
      };
      final status = SubscriptionStatus.fromMap(map);

      expect(status.isActive, true);
      expect(status.isTrial, false);
    });

    test('copyWith должен создавать копию с изменениями', () {
      final original = SubscriptionStatus(updatedAt: DateTime(2025, 1, 1));
      final modified = original.copyWith(
        isActive: true,
        productId: 'premium_monthly',
      );

      expect(modified.isActive, true);
      expect(modified.productId, 'premium_monthly');
      expect(modified.id, original.id); // не изменилось
      expect(modified.isTrial, original.isTrial); // не изменилось
    });

    test('toMap должен правильно сериализовать null даты', () {
      final status = SubscriptionStatus(updatedAt: DateTime(2025, 1, 1));
      final map = status.toMap();

      expect(map['expiration_date'], isNull);
      expect(map['purchased_at'], isNull);
      expect(map['updated_at'], isNotNull);
    });
  });
}
