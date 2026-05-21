import 'package:flutter/foundation.dart';

/// Статус подписки пользователя.
///
/// Хранится в SQLite в таблице `subscription`.
/// Позволяет приложению работать офлайн и не показывать paywall
/// при каждом запуске.
@immutable
class SubscriptionStatus {
  /// Уникальный ID (всегда 'default' — одна запись).
  final String id;

  /// Активна ли подписка (оплаченный период или пробный).
  final bool isActive;

  /// Активен ли пробный период.
  final bool isTrial;

  /// Дата истечения подписки (null если не активна).
  final DateTime? expirationDate;

  /// RevenueCat product ID.
  final String? productId;

  /// Дата покупки.
  final DateTime? purchasedAt;

  /// Дата последнего обновления.
  final DateTime updatedAt;

  const SubscriptionStatus({
    this.id = 'default',
    this.isActive = false,
    this.isTrial = false,
    this.expirationDate,
    this.productId,
    this.purchasedAt,
    required this.updatedAt,
  });

  /// Пользователь имеет премиум-доступ (подписка или пробный период).
  bool get isPremium => isActive;

  /// Создаёт [SubscriptionStatus] из мапы SQLite.
  factory SubscriptionStatus.fromMap(Map<String, dynamic> map) {
    return SubscriptionStatus(
      id: map['id'] as String? ?? 'default',
      isActive: map.containsKey('is_active')
          ? (map['is_active'] as num).toInt() == 1
          : false,
      isTrial: map.containsKey('is_trial')
          ? (map['is_trial'] as num).toInt() == 1
          : false,
      expirationDate: map['expiration_date'] != null
          ? DateTime.parse(map['expiration_date'] as String)
          : null,
      productId: map['product_id'] as String?,
      purchasedAt: map['purchased_at'] != null
          ? DateTime.parse(map['purchased_at'] as String)
          : null,
      updatedAt: map.containsKey('updated_at')
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Сериализует в мапу для SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'is_active': isActive ? 1 : 0,
      'is_trial': isTrial ? 1 : 0,
      'expiration_date': expirationDate?.toIso8601String(),
      'product_id': productId,
      'purchased_at': purchasedAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Возвращает копию с обновлёнными полями.
  SubscriptionStatus copyWith({
    String? id,
    bool? isActive,
    bool? isTrial,
    DateTime? expirationDate,
    String? productId,
    DateTime? purchasedAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionStatus(
      id: id ?? this.id,
      isActive: isActive ?? this.isActive,
      isTrial: isTrial ?? this.isTrial,
      expirationDate: expirationDate ?? this.expirationDate,
      productId: productId ?? this.productId,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionStatus &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SubscriptionStatus(isActive: $isActive, isTrial: $isTrial, '
      'expirationDate: $expirationDate, productId: $productId)';
}
