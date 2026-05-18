import 'package:flutter/material.dart';

import '../core/theme/zen_theme.dart';
import '../data/goals_repository.dart';
import '../data/meditation_goal.dart';
import '../services/app_service_locator.dart';

// =============================================================================
// GoalSettingsScreen — экран настройки целей
// =============================================================================
//
// Позволяет пользователю:
//   - Просматривать текущие цели
//   - Добавлять новую цель (выбор типа + целевого значения)
//   - Удалять существующие цели
//   - Изменять целевое значение существующей цели
//
// Открывается из GoalsPanel по кнопке "Настроить".
// =============================================================================

/// Экран настройки целей.
class GoalSettingsScreen extends StatefulWidget {
  const GoalSettingsScreen({super.key});

  @override
  State<GoalSettingsScreen> createState() => _GoalSettingsScreenState();
}

class _GoalSettingsScreenState extends State<GoalSettingsScreen> {
  GoalsRepository? _goalsRepo;
  List<MeditationGoal> _goals = [];
  bool _loading = true;
  bool _goalsChanged = false;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final locator = AppServiceLocator.instance;
      final repo = locator.goalsRepo;
      if (repo == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      _goalsRepo = repo;
      final goals = await repo.getGoals();
      if (mounted) {
        setState(() {
          _goals = goals;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки целей: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zen = theme.extension<ZenStyles>() ?? ZenStyles.defaults;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка целей'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(_goalsChanged),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Описание
                Text(
                  'Цели помогают отслеживать регулярность практики '
                  'и дают бонусные XP за выполнение.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

                // Список текущих целей
                if (_goals.isNotEmpty) ...[
                  Text(
                    'Текущие цели',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._goals.map((goal) => _buildGoalCard(context, theme, zen, goal)),
                  const SizedBox(height: 24),
                ],

                // Кнопка добавления новой цели
                Center(
                  child: FilledButton.tonalIcon(
                    onPressed: _goals.length >= 4
                        ? null
                        : () => _showAddGoalDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      _goals.length >= 4
                          ? 'Максимум 4 цели'
                          : 'Добавить цель',
                    ),
                    style: FilledButton.styleFrom(
                      foregroundColor: zen.goldGradient.colors.first,
                      backgroundColor:
                          zen.goldGradient.colors.first.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    ThemeData theme,
    ZenStyles zen,
    MeditationGoal goal,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.type.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Цель: ${goal.targetValue.toInt()} ${_unitForType(goal.type)} · '
                      '+${goal.bonusXp} XP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Кнопка редактирования
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18),
                onPressed: () => _showEditGoalDialog(context, goal),
                tooltip: 'Изменить',
                style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              // Кнопка удаления
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                onPressed: () => _confirmDeleteGoal(context, goal),
                tooltip: 'Удалить',
                style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _unitForType(GoalType type) {
    switch (type) {
      case GoalType.dailyMinutes:
        return 'мин/день';
      case GoalType.weeklySessions:
        return 'сесс./нед.';
      case GoalType.weeklyMinutes:
        return 'мин/нед.';
      case GoalType.streakDays:
        return 'дней';
    }
  }

  // ===========================================================================
  // Диалоги
  // ===========================================================================

  Future<void> _showAddGoalDialog(BuildContext context) async {
    final result = await showDialog<MapEntry<GoalType, double>>(
      context: context,
      builder: (_) => const _GoalFormDialog(isEditing: false),
    );

    if (result != null && _goalsRepo != null) {
      await _goalsRepo!.setGoal(result.key, result.value);
      _goalsChanged = true;
      await _loadGoals();
    }
  }

  Future<void> _showEditGoalDialog(
      BuildContext context, MeditationGoal goal) async {
    final result = await showDialog<MapEntry<GoalType, double>>(
      context: context,
      builder: (_) => _GoalFormDialog(
        isEditing: true,
        initialType: goal.type,
        initialValue: goal.targetValue,
      ),
    );

    if (result != null && _goalsRepo != null) {
      await _goalsRepo!.setGoal(result.key, result.value);
      _goalsChanged = true;
      await _loadGoals();
    }
  }

  Future<void> _confirmDeleteGoal(
      BuildContext context, MeditationGoal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: const Text('Удалить цель?'),
        content: Text(
          'Вы уверены, что хотите удалить цель '
          '«${goal.type.displayName}»?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && _goalsRepo != null) {
      await _goalsRepo!.removeGoal(goal.id);
      _goalsChanged = true;
      await _loadGoals();
    }
  }
}

// =============================================================================
// GoalFormDialog — диалог создания/редактирования цели
// =============================================================================

class _GoalFormDialog extends StatefulWidget {
  final bool isEditing;
  final GoalType? initialType;
  final double? initialValue;

  const _GoalFormDialog({
    required this.isEditing,
    this.initialType,
    this.initialValue,
  });

  @override
  State<_GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends State<_GoalFormDialog> {
  late GoalType _selectedType;
  late double _targetValue;
  late TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? GoalType.dailyMinutes;
    _targetValue = widget.initialValue ?? 10;
    _valueController = TextEditingController(
      text: _targetValue.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text(widget.isEditing ? 'Изменить цель' : 'Новая цель'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Выбор типа цели
          DropdownButtonFormField<GoalType>(
            initialValue: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Тип цели',
              border: OutlineInputBorder(),
            ),
            items: GoalType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.displayName),
              );
            }).toList(),
            onChanged: widget.isEditing
                ? null // Нельзя менять тип при редактировании
                : (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
          ),
          const SizedBox(height: 16),

          // Целевое значение
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Целевое значение',
              helperText: _helperForType(_selectedType),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              _targetValue = double.tryParse(value) ?? 0;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _targetValue > 0
              ? () {
                  Navigator.of(context).pop(
                    MapEntry(_selectedType, _targetValue),
                  );
                }
              : null,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  String _helperForType(GoalType type) {
    switch (type) {
      case GoalType.dailyMinutes:
        return 'Например: 10 минут в день';
      case GoalType.weeklySessions:
        return 'Например: 5 сессий в неделю';
      case GoalType.weeklyMinutes:
        return 'Например: 60 минут в неделю';
      case GoalType.streakDays:
        return 'Например: 7 дней подряд';
    }
  }
}
