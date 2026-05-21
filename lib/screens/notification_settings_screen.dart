import 'package:flutter/material.dart';

import '../core/theme/zen_theme.dart';
import '../data/notification_repository.dart';
import '../data/notification_settings.dart';
import '../services/app_service_locator.dart';
import '../services/notification_service.dart';

// =============================================================================
// NotificationSettingsScreen — экран настройки пуш-уведомлений
// =============================================================================
//
// Позволяет пользователю:
//   - Включить/отключить уведомления глобально
//   - Настроить время ежедневного напоминания
//   - Включить/отключить мотивационные сообщения
//   - Включить/отключить напоминание о целях
//   - Настроить тихие часы (начало/конец)
//   - Отправить тестовое уведомление
//
// Открывается из HomeScreen по кнопке "Уведомления".
// =============================================================================

/// Экран настройки уведомлений.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationRepository? _repo;
  NotificationSettings _settings = NotificationSettings(
    updatedAt: DateTime(2000),
  );
  bool _loading = true;
  bool _saving = false;
  bool _settingsChanged = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final locator = AppServiceLocator.instance;
      final repo = locator.notificationRepo;
      if (repo == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      _repo = repo;
      final settings = await repo.getSettings();
      if (mounted) {
        setState(() {
          _settings = settings;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки настроек уведомлений: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings(NotificationSettings updated) async {
    if (_repo == null) return;

    setState(() => _saving = true);
    try {
      final saved = updated.copyWith(updatedAt: DateTime.now());
      await _repo!.saveSettings(saved);

      // Перепланируем уведомления (оборачиваем в отдельный try-catch,
      // чтобы ошибка планирования не блокировала сохранение настроек)
      try {
        await NotificationService.instance.rescheduleAll(saved);
      } catch (e) {
        debugPrint('Ошибка перепланирования уведомлений: $e');
      }

      if (mounted) {
        setState(() {
          _settings = saved;
          _settingsChanged = true;
          _saving = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка сохранения настроек: $e');
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime() async {
    final parts = _settings.reminderTime.split(':');
    final initialHour = int.parse(parts[0]);
    final initialMinute = int.parse(parts[1]);

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      helpText: 'Выберите время напоминания',
      cancelText: 'Отмена',
      confirmText: 'Готово',
    );

    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await _saveSettings(_settings.copyWith(reminderTime: timeStr));
    }
  }

  Future<void> _pickMotivationalTime() async {
    final parts = _settings.motivationalTime.split(':');
    final initialHour = int.parse(parts[0]);
    final initialMinute = int.parse(parts[1]);

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      helpText: 'Время мотивационных сообщений',
      cancelText: 'Отмена',
      confirmText: 'Готово',
    );

    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await _saveSettings(_settings.copyWith(motivationalTime: timeStr));
    }
  }

  Future<void> _pickGoalReminderTime() async {
    final parts = _settings.goalReminderTime.split(':');
    final initialHour = int.parse(parts[0]);
    final initialMinute = int.parse(parts[1]);

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      helpText: 'Время напоминания о целях',
      cancelText: 'Отмена',
      confirmText: 'Готово',
    );

    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await _saveSettings(_settings.copyWith(goalReminderTime: timeStr));
    }
  }

  Future<void> _pickQuietHoursStart() async {
    final initial = _settings.quietHoursStart != null
        ? _parseTime(_settings.quietHoursStart!)
        : const TimeOfDay(hour: 22, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Начало тихих часов',
      cancelText: 'Отмена',
      confirmText: 'Готово',
    );

    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await _saveSettings(_settings.copyWith(quietHoursStart: timeStr));
    }
  }

  Future<void> _pickQuietHoursEnd() async {
    final initial = _settings.quietHoursEnd != null
        ? _parseTime(_settings.quietHoursEnd!)
        : const TimeOfDay(hour: 7, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Конец тихих часов',
      cancelText: 'Отмена',
      confirmText: 'Готово',
    );

    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await _saveSettings(_settings.copyWith(quietHoursEnd: timeStr));
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _sendTestNotification() async {
    // Проверяем тихие часы
    if (_settings.isInQuietHours(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Сейчас тихие часы (${_settings.quietHoursStart}–${_settings.quietHoursEnd}). '
              'Уведомление не будет показано.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
      return;
    }
    await NotificationService.instance.showMotivationalNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Тестовое уведомление отправлено!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zen = theme.extension<ZenStyles>() ?? ZenStyles.defaults;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(_settingsChanged),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  children: [
                    // Описание
                    Text(
                      'Настройте пуш-уведомления, чтобы не пропускать '
                      'практику и отслеживать прогресс.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // =========================================================
                    // Глобальный переключатель
                    // =========================================================
                    _buildSectionHeader(theme, 'Общие'),
                    const SizedBox(height: 8),
                    _buildSwitchTile(
                      theme: theme,
                      icon: Icons.notifications_active_rounded,
                      title: 'Уведомления',
                      subtitle: 'Включить или отключить все уведомления',
                      value: _settings.enabled,
                      onChanged: (v) =>
                          _saveSettings(_settings.copyWith(enabled: v)),
                    ),

                    if (_settings.enabled) ...[
                      const SizedBox(height: 24),

                      // =========================================================
                      // Время напоминания
                      // =========================================================
                      _buildSectionHeader(theme, 'Ежедневное напоминание'),
                      const SizedBox(height: 8),
                      _buildTimeTile(
                        theme: theme,
                        icon: Icons.schedule_rounded,
                        title: 'Время напоминания',
                        subtitle: 'Ежедневное уведомление о медитации',
                        time: _settings.reminderTime,
                        onTap: _pickTime,
                      ),
                      const SizedBox(height: 24),

                      // =========================================================
                      // Мотивационные сообщения
                      // =========================================================
                      _buildSectionHeader(theme, 'Мотивация'),
                      const SizedBox(height: 8),
                      _buildSwitchTile(
                        theme: theme,
                        icon: Icons.psychology_rounded,
                        title: 'Мотивационные сообщения',
                        subtitle: 'Вдохновляющие цитаты и статистика прогресса',
                        value: _settings.motivationalEnabled,
                        onChanged: (v) => _saveSettings(
                          _settings.copyWith(motivationalEnabled: v),
                        ),
                      ),
                      if (_settings.motivationalEnabled) ...[
                        const SizedBox(height: 4),
                        _buildTimeTile(
                          theme: theme,
                          icon: Icons.schedule_rounded,
                          title: 'Время мотивации',
                          subtitle: 'Ежедневное мотивационное уведомление',
                          time: _settings.motivationalTime,
                          onTap: _pickMotivationalTime,
                        ),
                      ],
                      const SizedBox(height: 24),

                      // =========================================================
                      // Напоминание о целях
                      // =========================================================
                      _buildSectionHeader(theme, 'Цели'),
                      const SizedBox(height: 8),
                      _buildSwitchTile(
                        theme: theme,
                        icon: Icons.track_changes_rounded,
                        title: 'Напоминание о целях',
                        subtitle: 'Напоминание вечером, если цель дня не выполнена',
                        value: _settings.goalReminderEnabled,
                        onChanged: (v) => _saveSettings(
                          _settings.copyWith(goalReminderEnabled: v),
                        ),
                      ),
                      if (_settings.goalReminderEnabled) ...[
                        const SizedBox(height: 4),
                        _buildTimeTile(
                          theme: theme,
                          icon: Icons.schedule_rounded,
                          title: 'Время напоминания',
                          subtitle: 'Ежедневное напоминание о целях',
                          time: _settings.goalReminderTime,
                          onTap: _pickGoalReminderTime,
                        ),
                      ],
                      const SizedBox(height: 24),

                      // =========================================================
                      // Тихие часы
                      // =========================================================
                      _buildSectionHeader(theme, 'Тихие часы'),
                      const SizedBox(height: 8),
                      _buildQuietHoursTile(theme, zen),
                      const SizedBox(height: 24),

                      // =========================================================
                      // Тестовое уведомление
                      // =========================================================
                      _buildSectionHeader(theme, 'Проверка'),
                      const SizedBox(height: 8),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _sendTestNotification,
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Отправить тестовое'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: zen.goldGradient.colors.first,
                            side: BorderSide(
                              color: zen.goldGradient.colors.first
                                  .withValues(alpha: 0.4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Индикатор сохранения
                if (_saving)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(
                        zen.goldGradient.colors.first,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSwitchTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: SwitchListTile(
          secondary: Icon(icon, size: 22),
          title: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          value: value,
          onChanged: onChanged,
          activeTrackColor: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTimeTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: ListTile(
          leading: Icon(icon, size: 22),
          title: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildQuietHoursTile(ThemeData theme, ZenStyles zen) {
    final hasStart = _settings.quietHoursStart != null;
    final hasEnd = _settings.quietHoursEnd != null;
    final isActive = hasStart && hasEnd;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                isActive
                    ? Icons.dark_mode_rounded
                    : Icons.dark_mode_outlined,
                size: 22,
              ),
              title: Text(
                'Тихие часы',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                isActive
                    ? 'Не беспокоить с ${_settings.quietHoursStart} до ${_settings.quietHoursEnd}'
                    : 'Отключить уведомления на ночь',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Switch(
                value: isActive,
                onChanged: (v) {
                  if (v) {
                    _saveSettings(
                      _settings.copyWith(
                        quietHoursStart: '22:00',
                        quietHoursEnd: '07:00',
                      ),
                    );
                  } else {
                    _saveSettings(
                      _settings.copyWith(
                        quietHoursStart: null,
                        quietHoursEnd: null,
                      ),
                    );
                  }
                },
                activeTrackColor: theme.colorScheme.primary,
              ),
            ),
            if (isActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuietHourButton(
                        theme: theme,
                        label: 'Начало',
                        time: _settings.quietHoursStart!,
                        onTap: _pickQuietHoursStart,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: _buildQuietHourButton(
                        theme: theme,
                        label: 'Конец',
                        time: _settings.quietHoursEnd!,
                        onTap: _pickQuietHoursEnd,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHourButton({
    required ThemeData theme,
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
