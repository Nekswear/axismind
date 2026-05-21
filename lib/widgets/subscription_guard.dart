import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/paywall_screen.dart';
import '../services/subscription_service.dart';

/// Глобальный защитник подписки.
///
/// Оборачивает [child] (обычно [HomeScreen]) и проверяет статус подписки.
/// - Если подписка активна (или пробный период) — показывает [child].
/// - Если подписка неактивна — показывает [PaywallScreen].
/// - Пока статус загружается — показывает экран загрузки.
///
/// Используется в [MaterialApp.home] для блокировки всего приложения
/// без активной подписки.
class SubscriptionGuard extends StatefulWidget {
  final Widget child;

  const SubscriptionGuard({super.key, required this.child});

  @override
  State<SubscriptionGuard> createState() => _SubscriptionGuardState();
}

class _SubscriptionGuardState extends State<SubscriptionGuard> {
  final _subscriptionService = SubscriptionService.instance;
  StreamSubscription? _statusSubscription;
  bool _checking = true;

  @override
  void initState() {
    super.initState();

    // Слушаем изменения статуса подписки
    _statusSubscription = _subscriptionService.statusStream.listen((_) {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    });

    // Даём время на инициализацию (если стрим уже пришёл — обновится выше)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _checking) {
        setState(() {
          _checking = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Пока проверяем статус — показываем загрузку
    if (_checking) {
      return const _LoadingScreen();
    }

    // Если подписка активна — показываем контент
    if (_subscriptionService.isPremium) {
      return widget.child;
    }

    // Если нет подписки — показываем paywall
    return const PaywallScreen();
  }
}

/// Экран загрузки, пока проверяется статус подписки.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка приложения
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Text(
                  'ZB',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.subscriptionGuardLoading,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
