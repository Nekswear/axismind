import 'package:flutter/material.dart';

/// Пустое состояние панели статистики.
///
/// Отображается, когда у пользователя ещё нет ни одной сессии.
/// Содержит декоративную иконку, приветственное сообщение
/// и подсказку начать первую медитацию.
class EmptyDashboard extends StatelessWidget {
  const EmptyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Декоративный круг с иконкой
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.spa_outlined,
                size: 48,
                color: primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),

            // Главное сообщение
            Text(
              'Ваш путь к спокойствию\nначинается с первой минуты',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Подсказка
            Text(
              'Завершите свою первую медитацию,\nчтобы увидеть здесь свою статистику',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Декоративные точки
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.3 + (i * 0.15)),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
