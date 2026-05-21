import 'package:flutter/material.dart';

import '../core/theme/zen_theme.dart';
import '../screens/paywall_screen.dart';
import '../services/subscription_service.dart';

/// Виджет для блокировки премиум-контента.
///
/// Если подписка активна — показывает [child].
/// Если нет — показывает [lockedChild] или перенаправляет на PaywallScreen.
///
/// Пример использования:
/// ```dart
/// SubscriptionGate(
///   child: PremiumFeatureWidget(),
///   lockedChild: Text('Доступно в ZenBalance Premium'),
/// )
/// ```
class SubscriptionGate extends StatefulWidget {
  /// Что показать, если есть подписка.
  final Widget child;

  /// Что показать вместо [child], если подписки нет.
  /// Если null — при тапе открывается PaywallScreen.
  final Widget? lockedChild;

  /// Показывать ли иконку замка на [lockedChild].
  final bool showLockIcon;

  /// Колбэк при попытке доступа без подписки.
  /// Если null — открывается PaywallScreen.
  final VoidCallback? onLockedTap;

  const SubscriptionGate({
    super.key,
    required this.child,
    this.lockedChild,
    this.showLockIcon = true,
    this.onLockedTap,
  });

  @override
  State<SubscriptionGate> createState() => _SubscriptionGateState();
}

class _SubscriptionGateState extends State<SubscriptionGate> {
  final _subscriptionService = SubscriptionService.instance;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _isPremium = _subscriptionService.isPremium;
    _subscriptionService.statusStream.listen((status) {
      if (mounted) {
        setState(() => _isPremium = status.isPremium);
      }
    });
  }

  Future<void> _handleLockedTap() async {
    if (widget.onLockedTap != null) {
      widget.onLockedTap!();
      return;
    }

    if (!mounted) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PaywallScreen(),
      ),
    );

    if (result == true && mounted) {
      setState(() => _isPremium = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPremium) {
      return widget.child;
    }

    if (widget.lockedChild != null) {
      return GestureDetector(
        onTap: _handleLockedTap,
        child: widget.lockedChild,
      );
    }

    // Если lockedChild не указан — показываем child с затемнением
    return GestureDetector(
      onTap: _handleLockedTap,
      child: Stack(
        children: [
          // Затемнённый контент
          Opacity(
            opacity: 0.4,
            child: AbsorbPointer(
              absorbing: true,
              child: widget.child,
            ),
          ),
          // Иконка замка по центру
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ZenColors.gold.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: 28,
                      color: ZenColors.background,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ZenBalance Premium',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ZenColors.background,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
