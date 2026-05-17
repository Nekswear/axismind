import 'package:flutter/material.dart';

import '../../core/theme/zen_theme.dart';

/// Контекстная подсказка с нейробиологическим обоснованием выбранного пресета.
///
/// Использует [AnimatedSize] и [AnimatedSwitcher] для плавного раскрытия
/// контента без Layout Jumps.
class NeuroPresetInfo extends StatelessWidget {
  final int minutes;

  const NeuroPresetInfo({super.key, required this.minutes});

  static const _descriptions = {
    5: 'Снижение активности дефолт-системы мозга.\n'
        'Быстрый возврат контроля над вниманием.',
    10: 'Преодоление стадии адаптации.\n'
        'Стабилизация сердечного ритма и запуск альфа-волн.',
    15: 'Глубокое ментальное погружение.\n'
        'Созерцание и упорядочивание внутренних процессов.',
    20: 'Классический Дзадзен.\n'
        'Устойчивое торможение симпатической нервной системы\n'
        'и вход в чистую ясность.',
  };

  String get _description => _descriptions[minutes] ?? '';

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: _description.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _description,
                  key: ValueKey('neuro_$minutes'),
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 15,
                    height: 1.6,
                    color: ZenColors.gold.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}
