import 'package:flutter/material.dart';

import '../core/theme/zen_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/subscription_service.dart';

/// Экран подписки (Paywall).
///
/// Показывается, когда пользователь пытается получить доступ
/// к премиум-функции без активной подписки.
///
/// Содержит:
/// - Заголовок "Откройте полный потенциал ZenBalance"
/// - Список премиум-функций
/// - Кнопку "Попробовать 7 дней бесплатно"
/// - Кнопку восстановления покупок
/// - Кнопку "Продолжить бесплатно"
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _subscriptionService = SubscriptionService.instance;
  bool _loading = false;
  String _price = '\$7.00/месяц';

  @override
  void initState() {
    super.initState();
    _loadPrice();
  }

  Future<void> _loadPrice() async {
    final price = await _subscriptionService.getSubscriptionPrice();
    if (mounted) {
      setState(() => _price = price);
    }
  }

  String get _priceLabel => '\$7.00/${AppLocalizations.of(context)!.month}';

  Future<void> _purchase() async {
    setState(() => _loading = true);
    final success = await _subscriptionService.purchaseSubscription();
    if (mounted) {
      setState(() => _loading = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.purchaseFailed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    final success = await _subscriptionService.restorePurchases();
    if (mounted) {
      setState(() => _loading = false);
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.subscriptionRestored),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noActivePurchases),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zen = theme.extension<ZenStyles>() ?? ZenStyles.defaults;

    return Scaffold(
      backgroundColor: ZenColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
          tooltip: AppLocalizations.of(context)!.close,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: zen.spacingUnit * 4),
          child: Column(
            children: [
              SizedBox(height: zen.gap(4)),

              // Иконка
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ZenColors.gold, ZenColors.goldLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: ZenColors.background,
                ),
              ),

              SizedBox(height: zen.gap(4)),

              // Заголовок
              Text(
                AppLocalizations.of(context)!.paywallTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                ),
              ),

              SizedBox(height: zen.gap(2)),

              Text(
                AppLocalizations.of(context)!.try7DaysFree,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: ZenColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: zen.gap(6)),

              // Список премиум-функций
              _buildFeatureItem(
                theme: theme,
                icon: Icons.psychology_rounded,
                title: AppLocalizations.of(context)!.featureMotivationalNotifications,
                subtitle: AppLocalizations.of(context)!.featureMotivationalNotificationsSub,
              ),
              SizedBox(height: zen.gap(2)),
              _buildFeatureItem(
                theme: theme,
                icon: Icons.track_changes_rounded,
                title: AppLocalizations.of(context)!.featureGoalReminders,
                subtitle: AppLocalizations.of(context)!.featureGoalRemindersSub,
              ),
              SizedBox(height: zen.gap(2)),
              _buildFeatureItem(
                theme: theme,
                icon: Icons.flag_rounded,
                title: AppLocalizations.of(context)!.featureMeditationGoals,
                subtitle: AppLocalizations.of(context)!.featureMeditationGoalsSub,
              ),
              SizedBox(height: zen.gap(2)),
              _buildFeatureItem(
                theme: theme,
                icon: Icons.bar_chart_rounded,
                title: AppLocalizations.of(context)!.featureDetailedStats,
                subtitle: AppLocalizations.of(context)!.featureDetailedStatsSub,
              ),
              SizedBox(height: zen.gap(2)),
              _buildFeatureItem(
                theme: theme,
                icon: Icons.sync_rounded,
                title: AppLocalizations.of(context)!.featureDeviceSync,
                subtitle: AppLocalizations.of(context)!.featureDeviceSyncSub,
              ),

              SizedBox(height: zen.gap(6)),

              // Кнопка покупки
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _purchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ZenColors.gold,
                    foregroundColor: ZenColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ZenColors.background,
                          ),
                        )
                      : Text(
                          '${AppLocalizations.of(context)!.try7DaysFree}\n${AppLocalizations.of(context)!.thenPrice} $_priceLabel',
                          textAlign: TextAlign.center,
                        ),
                ),
              ),

              SizedBox(height: zen.gap(2)),

              // Текст об отмене
              Text(
                AppLocalizations.of(context)!.cancelAnytime,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ZenColors.textMuted,
                ),
              ),

              SizedBox(height: zen.gap(4)),

              // Кнопка восстановления
              TextButton(
                onPressed: _loading ? null : _restore,
                child: Text(
                  AppLocalizations.of(context)!.restorePurchases,
                  style: TextStyle(
                    color: ZenColors.gold.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ),

              // Кнопка "Продолжить бесплатно"
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  AppLocalizations.of(context)!.continueFree,
                  style: TextStyle(
                    color: ZenColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),

              SizedBox(height: zen.gap(4)),

              // Privacy Policy и Terms
              Text(
                AppLocalizations.of(context)!.paymentTerms,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ZenColors.textMuted.withValues(alpha: 0.6),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: ZenColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 22,
            color: ZenColors.gold,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ZenColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.star_rounded,
          size: 18,
          color: ZenColors.gold.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}
