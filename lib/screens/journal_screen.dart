import 'package:flutter/material.dart';

import '../core/theme/zen_theme.dart';
import '../data/analytics_repository.dart';
import '../data/database_provider.dart';
import '../data/session.dart';

/// Экран дневника медитаций.
///
/// Отображает список завершённых сессий с заметками, оценкой настроения
/// и тегами. Поддерживает пагинацию (подгрузка по 20 записей).
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

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  Future<void> _initRepository() async {
    try {
      final db = await DatabaseProvider.instance();
      _repository = AnalyticsRepository(db);
      await _loadSessions();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadSessions() async {
    if (!_hasMore || _repository == null) return;

    try {
      final sessions = await _repository!.getJournalSessions(
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

  @override
  Widget build(BuildContext context) {
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дневник медитаций'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const _EmptyJournal()
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _sessions.clear();
                      _offset = 0;
                      _hasMore = true;
                      _loading = true;
                    });
                    await _loadSessions();
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: zen.spacingUnit * 2,
                      vertical: zen.spacingUnit * 2,
                    ),
                    itemCount: _sessions.length + (_hasMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i >= _sessions.length) {
                        // Триггер подгрузки следующих страниц
                        _loadSessions();
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return _JournalCard(session: _sessions[i]);
                    },
                  ),
                ),
    );
  }
}

/// Карточка одной записи в дневнике.
class _JournalCard extends StatelessWidget {
  final Session session;

  const _JournalCard({required this.session});

  static const _moodEmojis = ['😔', '😐', '🙂', '😊', '🧘'];

  String _moodEmoji(int? rating) {
    if (rating == null || rating < 1 || rating > 5) return '🧘';
    return _moodEmojis[rating - 1];
  }

  String _formatDate(DateTime dt) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _durationLabel(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    if (min > 0) return '$min мин $sec сек';
    return '$sec сек';
  }

  @override
  Widget build(BuildContext context) {
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;
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
                          _formatDate(date),
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
                      _durationLabel(session.seconds),
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
    final date = DateTime.parse(session.timestamp);
    final min = session.seconds ~/ 60;
    final sec = session.seconds % 60;

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
                        '$min мин $sec сек',
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📖', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            Text(
              'Здесь пока пусто',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Заверши медитацию,\nчтобы появилась первая запись',
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
