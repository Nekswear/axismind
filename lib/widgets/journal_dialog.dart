import 'package:flutter/material.dart';

import '../core/theme/zen_theme.dart';
import '../l10n/app_localizations.dart';

/// Результат, возвращаемый из [JournalDialog].
///
/// Содержит данные, введённые пользователем после завершения сессии.
class JournalResult {
  /// Текстовая заметка о сессии.
  final String? note;

  /// Оценка настроения (1–5).
  final int moodRating;

  /// Категория сессии (например, "Утро", "Стресс").
  final String? tag;

  const JournalResult({
    this.note,
    required this.moodRating,
    this.tag,
  });
}

/// Диалог для записи ощущений после завершения медитации.
///
/// Позволяет пользователю:
/// - Оценить настроение эмодзи (1–5)
/// - Написать текстовую заметку
/// - Выбрать тег (категорию) сессии
///
/// Если передан [initialResult] — диалог работает в режиме **редактирования**,
/// предзаполняя поля существующими данными.
///
/// Возвращает [JournalResult] при нажатии "Сохранить"
/// или `null` при нажатии "Пропустить".
class JournalDialog extends StatefulWidget {
  /// Длительность завершённой сессии в секундах (для отображения).
  final int durationSeconds;

  /// Опциональные начальные данные — для режима редактирования.
  ///
  /// Если передан, диалог предзаполняет поля и меняет заголовок на
  /// "Редактировать запись".
  final JournalResult? initialResult;

  const JournalDialog({
    super.key,
    required this.durationSeconds,
    this.initialResult,
  });

  @override
  State<JournalDialog> createState() => _JournalDialogState();
}

class _JournalDialogState extends State<JournalDialog> {
  late final TextEditingController _noteController;
  late int _moodRating;
  String? _selectedTag;

  bool get _isEditing => widget.initialResult != null;

  List<String> _tags(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.tagMorning,
      l10n.tagDay,
      l10n.tagEvening,
      l10n.tagStress,
      l10n.tagCalm,
      l10n.tagGratitude,
    ];
  }

  static const _moodEmojis = ['😔', '😐', '🙂', '😊', '🧘'];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialResult;
    _noteController = TextEditingController(text: initial?.note ?? '');
    _moodRating = initial?.moodRating ?? 3;
    _selectedTag = initial?.tag;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _durationLabel(BuildContext context) {
    final min = widget.durationSeconds ~/ 60;
    final sec = widget.durationSeconds % 60;
    final l10n = AppLocalizations.of(context)!;
    if (min > 0) return l10n.min(min.toString());
    return '$sec sec';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(zen.cardRadius),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isEditing ? AppLocalizations.of(context)!.journalEdit : AppLocalizations.of(context)!.journalNew),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.journalSession(_durationLabel(context)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Оценка настроения (1-5) ===
            Text(
              AppLocalizations.of(context)!.journalMood,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final rating = i + 1;
                final isSelected = _moodRating == rating;
                return GestureDetector(
                  onTap: () => setState(() => _moodRating = rating),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSelected ? 1.0 : 0.3,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: isSelected ? 1.2 : 1.0,
                      child: Text(
                        _moodEmojis[i],
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // === Текстовое поле для заметки ===
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.journalNote,
                border: const OutlineInputBorder(),
                counterText: '',
                contentPadding: const EdgeInsets.all(12),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 16),

            // === Теги ===
            Text(
              AppLocalizations.of(context)!.journalTag,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _tags(context).map((tag) {
                final selected = _selectedTag == tag;
                return ChoiceChip(
                  label: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? Colors.white : null,
                    ),
                  ),
                  selected: selected,
                  selectedColor: theme.colorScheme.primary,
                  onSelected: (_) {
                    setState(() {
                      _selectedTag = selected ? null : tag;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(AppLocalizations.of(context)!.skip),
        ),
        FilledButton(
          onPressed: () {
            final note = _noteController.text.trim();
            Navigator.of(context).pop(JournalResult(
              note: note.isEmpty ? null : note,
              moodRating: _moodRating,
              tag: _selectedTag,
            ));
          },
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}
