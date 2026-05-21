import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Отображение ошибки с иконкой, сообщением и кнопкой повтора.
///
/// Сообщение об ошибке переводится на русский язык.
/// Технические детали (Dart/DeepSeek ошибки) оборачиваются
/// в человекочитаемый текст.
class ErrorView extends StatelessWidget {
  /// Сообщение об ошибке для пользователя.
  final String message;

  /// Коллбэк при нажатии на кнопку "Повторить".
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  /// Парсит техническую ошибку и возвращает человекочитаемое сообщение.
  ///
  /// Пробует извлечь понятный текст из исключений различных типов.
  /// Если распознать не удалось — возвращает переданное [message].
  static String formatError(dynamic error, {String fallback = 'An unknown error occurred'}) {
    if (error == null) return fallback;

    final msg = error.toString();

    // Ошибки БД
    if (msg.contains('DatabaseException') || msg.contains('Database error')) {
      return 'Database error. Please restart the app.';
    }

    // Ошибки сети/API
    if (msg.contains('SocketException') || msg.contains('HttpException')) {
      return 'Connection issue. Check your internet connection.';
    }

    // Ошибки аналитики
    if (msg.contains('AnalyticsException')) {
      // Извлекаем текст после ":"
      final colonIndex = msg.indexOf(':');
      if (colonIndex > 0 && colonIndex < msg.length - 1) {
        return msg.substring(colonIndex + 2).trim();
      }
      return 'Failed to load statistics.';
    }

    // StaleRequest — не показываем пользователю, это не ошибка
    if (msg.contains('StaleRequestException')) {
      return 'Data is updating...';
    }

    // Любая другая ошибка
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Иконка ошибки
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: errorColor.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: errorColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),

            // Сообщение
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Кнопка повтора
            if (onRetry != null)
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(AppLocalizations.of(context)!.retry),
              ),
          ],
        ),
      ),
    );
  }
}
