import 'package:flutter/material.dart';

import '../core/theme/zen_theme.dart';
import '../data/goals_repository.dart';
import '../data/meditation_goal.dart';
import '../l10n/app_localizations.dart';
import '../services/app_service_locator.dart';

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
      debugPrint('Error loading goals: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zen = theme.extension<ZenStyles>() ?? ZenStyles.defaults;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.goalSettingsTitle),
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
                Text(
                  l10n.goalSettingsSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                if (_goals.isNotEmpty) ...[
                  Text(
                    l10n.goalsCurrentListTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._goals.map((goal) => _buildGoalCard(context, theme, zen, goal, l10n)),
                  const SizedBox(height: 24),
                ],
                Center(
                  child: FilledButton.tonalIcon(
                    onPressed: _goals.length >= 4
                        ? null
                        : () => _showAddGoalDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      _goals.length >= 4
                          ? l10n.goalsMaxLimit
                          : l10n.goalsAddBtn,
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
    AppLocalizations l10n,
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
                      _labelForType(goal.type, l10n),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_labelForType(goal.type, l10n)}: ${goal.targetValue.toInt()} ${_unitForType(goal.type, l10n)} · +${goal.bonusXp} XP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18),
                onPressed: () => _showEditGoalDialog(context, goal),
                tooltip: l10n.goalsEditTooltip,
                style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                onPressed: () => _confirmDeleteGoal(context, goal, l10n),
                tooltip: l10n.goalsDeleteTooltip,
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

  String _labelForType(GoalType type, AppLocalizations l10n) {
    switch (type) {
      case GoalType.dailyMinutes:
        return l10n.goalTypeDailyMinutes;
      case GoalType.weeklySessions:
        return l10n.goalTypeWeeklySessions;
      case GoalType.weeklyMinutes:
        return l10n.goalTypeWeeklyMinutes;
      case GoalType.streakDays:
        return l10n.goalTypeStreakDays;
    }
  }

  String _unitForType(GoalType type, AppLocalizations l10n) {
    switch (type) {
      case GoalType.dailyMinutes:
        return l10n.goalUnitMinPerDay;
      case GoalType.weeklySessions:
        return l10n.goalUnitSessPerWeek;
      case GoalType.weeklyMinutes:
        return l10n.goalUnitMinPerWeek;
      case GoalType.streakDays:
        return l10n.goalUnitDays;
    }
  }

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
      BuildContext context, MeditationGoal goal, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: Text(l10n.goalsDeleteDialogTitle),
        content: Text(
          l10n.goalsDeleteDialogContent(_labelForType(goal.type, l10n)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.goalDialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.goalsDialogDelete),
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
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text(widget.isEditing ? l10n.goalDialogTitleEdit : l10n.goalDialogTitleNew),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<GoalType>(
            initialValue: _selectedType,
            decoration: InputDecoration(
              labelText: l10n.goalDialogSelectType,
              border: const OutlineInputBorder(),
            ),
            items: GoalType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_labelForType(type, l10n)),
              );
            }).toList(),
            onChanged: widget.isEditing
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.goalDialogTargetValue,
              helperText: _helperForType(_selectedType, l10n),
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
          child: Text(l10n.goalDialogCancel),
        ),
        FilledButton(
          onPressed: _targetValue > 0
              ? () {
                  Navigator.of(context).pop(
                    MapEntry(_selectedType, _targetValue),
                  );
                }
              : null,
          child: Text(l10n.goalDialogSave),
        ),
      ],
    );
  }

  String _labelForType(GoalType type, AppLocalizations l10n) {
    switch (type) {
      case GoalType.dailyMinutes:
        return l10n.goalTypeDailyMinutes;
      case GoalType.weeklySessions:
        return l10n.goalTypeWeeklySessions;
      case GoalType.weeklyMinutes:
        return l10n.goalTypeWeeklyMinutes;
      case GoalType.streakDays:
        return l10n.goalTypeStreakDays;
    }
  }

  String _helperForType(GoalType type, AppLocalizations l10n) {
    switch (type) {
      case GoalType.dailyMinutes:
        return l10n.goalsHelperDaily;
      case GoalType.weeklySessions:
        return l10n.goalsHelperWeeklySessions;
      case GoalType.weeklyMinutes:
        return l10n.goalsHelperWeeklyMinutes;
      case GoalType.streakDays:
        return l10n.goalsHelperStreak;
    }
  }
}