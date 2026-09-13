import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../core/theme/zen_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';

/// Экран входа через Google аккаунт.
///
/// Показывается, когда пользователь не авторизован.
/// После успешного входа — возвращает результат через Navigator.pop.
///
/// На Windows/Linux/macOS Google Sign-In не поддерживается,
/// поэтому показывается информационное сообщение вместо кнопки.
class AuthScreen extends StatelessWidget {
  final AuthService _authService;

  AuthScreen({super.key, AuthService? authService})
    : _authService = authService ?? AuthService();

  /// Google Sign-In поддерживается только на Android, iOS и Web.
  bool _isGoogleSignInSupported(BuildContext context) {
    if (kIsWeb) return true;
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;

    return Scaffold(
      // AppBar с кнопкой закрытия — чтобы можно было вернуться на любой платформе
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
          tooltip: AppLocalizations.of(context)!.authCloseTooltip,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: zen.spacingUnit * 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Иконка приложения
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.self_improvement,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                ),

                SizedBox(height: zen.gap(4)), // 32px
                // Название
                Text(
                  'AxisMind',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: zen.spacingUnit), // 8px

                Text(
                  AppLocalizations.of(context)!.authTitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),

                SizedBox(height: zen.gap(8)), // 64px

                if (_isGoogleSignInSupported(context))
                  _GoogleSignInButton(
                    onPressed: () async {
                      try {
                        final user = await _authService.signInWithGoogle();
                        if (user != null && context.mounted) {
                          Navigator.pop(context, true);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.authError(e.toString()),
                              ),
                              backgroundColor: theme.colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
                  )
                else
                  // Информационное сообщение для десктопных платформ
                  _UnsupportedPlatformInfo(theme: theme, zen: zen),

                SizedBox(height: zen.gap(3)), // 24px
                // Текст о приватности
                Text(
                  AppLocalizations.of(context)!.authSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),

                SizedBox(height: zen.gap(4)), // 32px
                // Кнопка "Продолжить без входа" — доступна на всех платформах
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppLocalizations.of(context)!.authContinueWithout,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Информационный блок для платформ, где Google Sign-In не поддерживается.
class _UnsupportedPlatformInfo extends StatelessWidget {
  final ThemeData theme;
  final ZenStyles zen;

  const _UnsupportedPlatformInfo({required this.theme, required this.zen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(zen.spacingUnit * 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 32, color: theme.colorScheme.primary),
          SizedBox(height: zen.spacingUnit * 2),
          Text(
            AppLocalizations.of(context)!.authGoogleTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: zen.spacingUnit),
          Text(
            AppLocalizations.of(context)!.authGoogleSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Кнопка входа через Google в стиле Material Design.
/// Кнопка входа через Google в стиле Material Design.
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IgnorePointer(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'G',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.authGoogle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
