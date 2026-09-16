import 'package:flutter/material.dart';

import '../core/theme/zen_theme.dart';
import '../data/analytics_repository.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';
import '../services/app_service_locator.dart';
import '../widgets/journal_dialog.dart';

/// Экран дневника медитаций.
///
/// Отображает список завершённых сессий с заметками, оценкой настроения
/// и тегами. Поддерживает:
/// - Пагинацию (подгрузка по 20 записей)
/// - Фильтрацию по тегам
/// - Поиск по заметкам
/// - Редактирование и удаление записей
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _sessions = <Session>[];
  bool _loading = true;
  bool _hasMore = true;
  int _offset = 0;
  static const _pageSize = 20;
  AnalyticsRepository? _repository;

  // === Фильтрация и поиск ===
  final _searchController = TextEditingController();
  List<String> _availableTags = [];
  String? _selectedTag;
  String? _searchQuery;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initRepository() async {
    final locator = AppServiceLocator.instance;
    final syncRepo = locator.syncRepo;
    if (syncRepo == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    _repository = AnalyticsRepository(syncRepo);

    await _loadTags();
    await _loadSessions();
  }

  Future<void> _loadTags() async {
    try {
      final tags = await _repository!.getDistinctTags();
      if (mounted) {
        setState(() => _availableTags = tags);
      }
    } catch (_) {}
  }

  Future<void> _loadSessions() async {
    if (!_hasMore || _repository == null) return;

    try {
      final sessions = await _repository!.getFilteredJournalSessions(
        tag: _selectedTag,
        searchQuery: _searchQuery,
        limit: _pageSize,
        offset: _offset,
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        if (sessions.length < _pageSize) {
          _hasMore = false;
        }
        _sessions.addAll(sessions);
        _offset += sessions.length;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _sessions.clear();
      _offset = 0;
      _hasMore = true;
      _loading = true;
    });
    await _loadTags();
    await _loadSessions();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim().isEmpty ? null : value.trim();
      _sessions.clear();
      _offset = 0;
      _hasMore = true;
      _loading = true;
    });
    _loadSessions();
  }

  void _onTagFilterChanged(String? tag) {
    setState(() {
      _selectedTag = tag;
      _sessions.clear();
      _offset = 0;
      _hasMore = true;
      _loading = true;
    });
    _loadSessions();
  }

  Future<void> _editSession(Session session) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<JournalResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => JournalDialog(
        durationSeconds: session.seconds,
        initialResult: JournalResult(
          note: session.note,
          moodRating: session.moodRating ?? 3,
          tag: session.tag,
        ),
      ),
    );

    if (result != null && context.mounted) {
      try {
        await _repository!.updateSessionJournal(
          session.id,
          note: result.note,
          moodRating: result.moodRating,
          tag: result.tag,
        );
        await _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.journalUpdateError)),
          );
        }
      }
    }
  }

  Future<void> _deleteSession(Session session) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.journalDeleteTitle),
        content: Text(l10n.journalDeleteContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.journalDeleteCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.journalDeleteConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await _repository!.deleteSession(session.id);
        await _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.journalDeleteSuccess)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.journalDeleteError)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.journalTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = null;
                  _refresh();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // === Поисковая строка ===
          if (_showSearch)
            Padding(
              padding: EdgeInsets.fromLTRB(
                zen.spacingUnit * 2,
                zen.spacingUnit,
                zen.spacingUnit * 2,
                0,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.journalSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
                onChanged: _onSearchChanged,
              ),
            ),

          // === Фильтр по тегам ===
          if (_availableTags.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: zen.spacingUnit * 2,
                  vertical: 8,
                ),
                children: [
                  _buildTagChip(null, l10n.journalTagAll),
                  ..._availableTags.map((tag) => _buildTagChip(tag, tag)),
                ],
              ),
            ),

          // === Список сессий ===
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _sessions.isEmpty
                    ? const _EmptyJournal()
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: zen.spacingUnit * 2,
                            vertical: zen.spacingUnit * 2,
                          ),
                          itemCount: _sessions.length + (_hasMore ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i >= _sessions.length) {
                              _loadSessions();
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return _JournalCard(
                              session: _sessions[i],
                              onEdit: () => _editSession(_sessions[i]),
                              onDelete: () => _deleteSession(_sessions[i]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String? tag, String label) {
    final isSelected = _selectedTag == tag;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : null,
          ),
        ),
        selected: isSelected,
        selectedColor: Theme.of(context).colorScheme.primary,
        onSelected: (_) => _onTagFilterChanged(isSelected ? null : tag),
      ),
    );
  }
}

/// Карточка одной записи в дневнике.
class _JournalCard extends StatelessWidget {
  final Session session;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _JournalCard({
    required this.session,
    required this.onEdit,
    required this.onDelete,
  });

  static const _moodEmojis = ['😔', '😐', '🙂', '😊', '🧘'];

  String _moodEmoji(int? rating) {
    if (rating == null || rating < 1 || rating > 5) return '🧘';
    return _moodEmojis[rating - 1];
  }

  String _formatDate(DateTime dt, AppLocalizations l10n) {
    final months = [
      l10n.journalMonthJan,
      l10n.journalMonthFeb,
      l10n.journalMonthMar,
      l10n.journalMonthApr,
      l10n.journalMonthMay,
      l10n.journalMonthJun,
      l10n.journalMonthJul,
      l10n.journalMonthAug,
      l10n.journalMonthSep,
      l10n.journalMonthOct,
      l10n.journalMonthNov,
      l10n.journalMonthDec,
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _durationLabel(int seconds, AppLocalizations l10n) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    if (min > 0) return l10n.journalDurationMinSec(min, sec);
    return l10n.journalDurationSec(sec);
  }

  @override
  Widget build(BuildContext context) {
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;
    final l10n = AppLocalizations.of(context)!;
    final date = DateTime.parse(session.timestamp);

    return Card(
      margin: EdgeInsets.only(bottom: zen.spacingUnit * 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(zen.cardRadius / 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(zen.cardRadius / 2),
        onTap: () => _showSessionDetail(context),
        child: Padding(
          padding: EdgeInsets.all(zen.spacingUnit * 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === Эмодзи настроения ===
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: zen.focusGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _moodEmoji(session.moodRating),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // === Дата + длительность + заметка ===
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Дата и время
                    Row(
                      children: [
                        Text(
                          _formatDate(date, l10n),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Длительность
                    Text(
                      _durationLabel(session.seconds, l10n),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),

                    // Заметка
                    if (session.note != null && session.note!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        session.note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[800],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // === Тег ===
              if (session.tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    session.tag!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionDetail(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateTime.parse(session.timestamp);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final zen = Theme.of(ctx).extension<ZenStyles>() ?? ZenStyles.defaults;
        return Padding(
          padding: EdgeInsets.all(zen.spacingUnit * 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    _moodEmoji(session.moodRating),
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${date.day}.${date.month}.${date.year}',
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                      Text(
                        _durationLabel(session.seconds, l10n),
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (session.note != null && session.note!.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  session.note!,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
              ],
              if (session.tag != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🏷 ${session.tag}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // === Кнопки действий ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onEdit();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l10n.journalEditBtn),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onDelete();
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(l10n.journalDeleteConfirm),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// Пустое состояние дневника — отображается, когда нет ни одной сессии.
class _EmptyJournal extends StatelessWidget {
  const _EmptyJournal();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📖', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            Text(
              l10n.journalEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.journalEmptySubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}