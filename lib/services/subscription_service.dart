import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../data/subscription_repository.dart';
import '../data/subscription_status.dart';

/// Сервис управления подпиской через RevenueCat.
///
/// Предоставляет:
/// - Проверку статуса подписки
/// - Покупку подписки
/// - Восстановление покупок
/// - Поток статуса для реактивного UI
///
/// Использует [SubscriptionRepository] для локального кэширования,
/// чтобы приложение работало офлайн.
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  SubscriptionRepository? _repo;

  /// RevenueCat API ключ для Android.
  /// В реальном приложении должен храниться в конфиге или .env.
  /// Замените на ваш ключ из RevenueCat Dashboard.
  static const String _revenueCatApiKeyAndroid = 'goog_XXXXXXXXXXXXXXXXXXXXX';

  /// Текущий статус подписки.
  SubscriptionStatus _status = SubscriptionStatus(updatedAt: DateTime(2000));

  /// Поток статуса подписки для реактивного UI.
  final _statusController = StreamController<SubscriptionStatus>.broadcast();
  Stream<SubscriptionStatus> get statusStream => _statusController.stream;

  /// Текущий статус (синхронный доступ).
  SubscriptionStatus get currentStatus => _status;

  /// Есть ли премиум-доступ (подписка активна или пробный период).
  bool get isPremium => _status.isPremium;

  /// Инициализация RevenueCat SDK.
  ///
  /// Должна быть вызвана после Firebase.initializeApp() в main.dart.
  /// [repo] — репозиторий для локального кэширования.
  Future<void> init(SubscriptionRepository repo) async {
    _repo = repo;

    try {
      // Загружаем кэшированный статус
      _status = await _repo!.getStatus();
      _statusController.add(_status);

      // Инициализируем RevenueCat
      await Purchases.setLogLevel(LogLevel.debug);
      final configuration = PurchasesConfiguration(_revenueCatApiKeyAndroid);
      await Purchases.configure(configuration);

      // Подписываемся на обновления от RevenueCat
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdate);

      // Проверяем текущий статус
      await _refreshStatus();

      debugPrint('[SUBSCRIPTION] Service initialized. isPremium: ${_status.isPremium}');
    } catch (e) {
      debugPrint('[SUBSCRIPTION] Init error (non-fatal): $e');
      // Продолжаем с кэшированным статусом
    }
  }

  /// Обработчик обновлений от RevenueCat.
  void _onCustomerInfoUpdate(CustomerInfo customerInfo) {
    debugPrint('[SUBSCRIPTION] Customer info updated');
    _updateStatusFromCustomerInfo(customerInfo);
  }

  /// Парсит строку даты от RevenueCat в [DateTime].
  ///
  /// Публичный для доступа из тестов.
  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Обновляет статус из RevenueCat CustomerInfo.
  void _updateStatusFromCustomerInfo(CustomerInfo customerInfo) {
    final entitlement = customerInfo.entitlements.all['premium'];
    final isActive = entitlement?.isActive == true;
    final isTrial = entitlement?.periodType == PeriodType.trial;
    final productId = entitlement?.productIdentifier;

    // RevenueCat v10 возвращает даты как String? — парсим в DateTime?
    final expirationDate = parseDate(entitlement?.expirationDate);
    final purchasedAt = parseDate(entitlement?.originalPurchaseDate);

    final newStatus = SubscriptionStatus(
      isActive: isActive,
      isTrial: isTrial,
      expirationDate: expirationDate,
      productId: productId,
      purchasedAt: purchasedAt,
      updatedAt: DateTime.now(),
    );

    _status = newStatus;
    _statusController.add(newStatus);

    // Кэшируем локально
    _repo?.saveStatus(newStatus);
  }

  /// Запрашивает актуальный статус у RevenueCat.
  Future<void> _refreshStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _updateStatusFromCustomerInfo(customerInfo);
    } catch (e) {
      debugPrint('[SUBSCRIPTION] Refresh status error: $e');
    }
  }

  /// Покупка подписки (получает monthly пакет из текущего offering).
  ///
  /// Возвращает `true`, если покупка успешна.
  Future<bool> purchaseSubscription() async {
    try {
      final offering = await getCurrentOffering();
      if (offering == null || offering.monthly == null) {
        debugPrint('[SUBSCRIPTION] No monthly package available');
        return false;
      }
      return purchasePackage(offering.monthly!);
    } catch (e) {
      debugPrint('[SUBSCRIPTION] Purchase error: $e');
      return false;
    }
  }

  /// Покупка подписки через пакет (offering).
  ///
  /// Возвращает `true`, если покупка успешна.
  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );

      _updateStatusFromCustomerInfo(result.customerInfo);
      return _status.isPremium;
    } catch (e) {
      debugPrint('[SUBSCRIPTION] Purchase package error: $e');
      return false;
    }
  }

  /// Восстановление покупок.
  ///
  /// Возвращает `true`, если найдена активная подписка.
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _updateStatusFromCustomerInfo(customerInfo);
      return _status.isPremium;
    } catch (e) {
      debugPrint('[SUBSCRIPTION] Restore error: $e');
      return false;
    }
  }

  /// Получает цену подписки для отображения в paywall.
  Future<String> getSubscriptionPrice() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current != null && current.monthly != null) {
        return current.monthly!.storeProduct.priceString;
      }
    } catch (e) {
      debugPrint('[SUBSCRIPTION] Get price error: $e');
    }
    return '\$7.00/месяц';
  }

  /// Получает текущее предложение (offering) для paywall.
  Future<Offering?> getCurrentOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (e) {
      debugPrint('[SUBSCRIPTION] Get offerings error: $e');
      return null;
    }
  }

  /// Принудительная проверка статуса (вызывается при запуске).
  Future<void> checkSubscriptionStatus() async {
    await _refreshStatus();
  }

  /// Освобождение ресурсов.
  void dispose() {
    _statusController.close();
  }
}
