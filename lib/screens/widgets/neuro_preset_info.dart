import 'package:flutter/material.dart';

import '../../core/theme/zen_theme.dart';
import '../../l10n/app_localizations.dart';

/// Контекстная подсказка с нейробиологическим обоснованием выбранного пресета.
///
/// Использует [AnimatedSize] и [AnimatedSwitcher] для плавного раскрытия
/// контента без Layout Jumps.
class NeuroPresetInfo extends StatelessWidget {
  final int minutes;

  const NeuroPresetInfo({super.key, required this.minutes});

  String _getDescription(AppLocalizations l10n) {
    switch (minutes) {
      case 5:
        return l10n.neuroPreset5;
      case 10:
        return l10n.neuroPreset10;
      case 15:
        return l10n.neuroPreset15;
      case 20:
        return l10n.neuroPreset20;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final description = l10n != null ? _getDescription(l10n) : '';

    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: description.isEmpty
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
                  description,
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
