import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/history_entry.dart';
import '../state/app_state.dart';

class _TimelineItem {
  final DateTime when;
  final HistoryEntry? watch;
  final DoneEntry? done;
  const _TimelineItem.watch(this.when, this.watch) : done = null;
  const _TimelineItem.done(this.when, this.done) : watch = null;
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final state = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearHistory),
        content: Text(l10n.clearHistoryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.clear),
          ),
        ],
      ),
    );
    if (ok == true) state.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final items = <_TimelineItem>[
      for (final h in state.history) _TimelineItem.watch(h.watchedAt, h),
      for (final d in state.dones) _TimelineItem.done(d.doneAt, d),
    ]..sort((a, b) => b.when.compareTo(a.when));

    if (items.isEmpty) {
      return Center(child: Text(l10n.historyEmpty));
    }

    final dayFormat = DateFormat.yMMMMd(l10n.localeName);
    final timeFormat = DateFormat.Hm(l10n.localeName);
    final rows = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.delete_sweep_outlined, size: 20),
            label: Text(l10n.clearHistory),
            onPressed: () => _confirmClear(context),
          ),
        ),
      ),
    ];
    String? lastDay;
    for (final item in items) {
      final day = dayFormat.format(item.when);
      if (day != lastDay) {
        lastDay = day;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text(day, style: Theme.of(context).textTheme.titleSmall),
        ));
      }
      rows.add(item.watch != null
          ? _WatchTile(entry: item.watch!, timeFormat: timeFormat)
          : _DoneTile(entry: item.done!, timeFormat: timeFormat));
    }
    return ListView(children: rows);
  }
}

class _Thumb extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _Thumb({required this.summary});

  @override
  Widget build(BuildContext context) {
    final url = summary['thumb'] as String? ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 64,
        height: 64,
        child: url.isEmpty
            ? Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.videocam),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.videocam),
                ),
              ),
      ),
    );
  }
}

class _WatchTile extends StatelessWidget {
  final HistoryEntry entry;
  final DateFormat timeFormat;
  const _WatchTile({required this.entry, required this.timeFormat});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final artist = entry.postSummary['artist'] as String? ?? '';
    return ListTile(
      leading: _Thumb(summary: entry.postSummary),
      title: Text(
        artist.isEmpty ? '#${entry.postId}' : '$artist · #${entry.postId}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        l10n.entryWatched(
          timeFormat.format(entry.watchedAt),
          '${(entry.watchRatio * 100).round()}%',
        ),
      ),
      trailing: entry.completed
          ? const Icon(Icons.check_circle_outline, color: Colors.green)
          : null,
    );
  }
}

class _DoneTile extends StatelessWidget {
  final DoneEntry entry;
  final DateFormat timeFormat;
  const _DoneTile({required this.entry, required this.timeFormat});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final artist = entry.postSummary['artist'] as String? ?? '';
    return ListTile(
      leading: _Thumb(summary: entry.postSummary),
      title: Text(
        artist.isEmpty ? '#${entry.postId}' : '$artist · #${entry.postId}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(l10n.entryDone(timeFormat.format(entry.doneAt))),
      trailing: _DonePhoto(path: entry.photoPath),
    );
  }
}

class _DonePhoto extends StatelessWidget {
  final String? path;
  const _DonePhoto({required this.path});

  @override
  Widget build(BuildContext context) {
    final p = path;
    if (p == null || !File(p).existsSync()) {
      return const Icon(Icons.flag_outlined, color: Colors.amber);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.file(
        File(p),
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) =>
            const Icon(Icons.flag_outlined, color: Colors.amber),
      ),
    );
  }
}
