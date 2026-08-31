import 'package:flutter/material.dart';

import '../domain/level_up_event.dart';
import '../l10n/app_localizations.dart';
import '../l10n/rank_localization.dart';

/// Диалог повышения уровня с высококонтрастным текстом.
///
/// Отображается после завершения сессии, если уровень пользователя вырос.
/// Требования: FontWeight.w900, Colors.black87 для максимальной читаемости.
class LevelUpDialog extends StatelessWidget {
  final LevelUpEvent event;

  const LevelUpDialog({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.levelUpTitle(event.level.toString()),
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: Colors.black87,
          fontSize: 22,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.rankLevel(event.level.toString()),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              fontSize: 48,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            event.rank.title(AppLocalizations.of(context)!),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            child: Text(AppLocalizations.of(context)!.continueLabel),
          ),
        ),
      ],
    );
  }
}
