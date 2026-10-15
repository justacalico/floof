import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';

class ProfilesPage extends StatelessWidget {
  const ProfilesPage({super.key});

  Future<void> _addProfile(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addProfile),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.profileNameHint),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (name != null && name.trim().isNotEmpty) {
      context.read<AppState>().addProfile(name.trim());
    }
  }

  Future<void> _renameProfile(BuildContext context, String id) async {
    final l10n = AppLocalizations.of(context)!;
    final state = context.read<AppState>();
    final current = state.profiles.firstWhere((p) => p.id == id).name;
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameProfile),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.rename),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      state.renameProfile(id, name.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final profile in state.profiles)
          Card(
            child: ListTile(
              leading: Icon(
                profile.id == state.activeProfileId
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: Text(profile.name),
              subtitle: profile.id == state.activeProfileId
                  ? Text(l10n.activeProfile)
                  : Text(l10n.tapToSwitch),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: l10n.rename,
                    onPressed: () => _renameProfile(context, profile.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: l10n.deleteProfile,
                    onPressed: state.profiles.length <= 1
                        ? null
                        : () => state.removeProfile(profile.id),
                  ),
                ],
              ),
              onTap: () => state.switchProfile(profile.id),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: FilledButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l10n.addProfile),
            onPressed: () => _addProfile(context),
          ),
        ),
        _StatsCard(state: state),
        _TasteCard(state: state),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final AppState state;
  const _StatsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.statsTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.statsWatched(state.watchedCount)),
            Text(l10n.statsDone(state.doneCount)),
          ],
        ),
      ),
    );
  }
}

class _TasteCard extends StatelessWidget {
  final AppState state;
  const _TasteCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final likes = state.engine.topFeatures(count: 8);
    final dislikes = state.engine.topFeatures(count: 6, positive: false);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.tasteTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (likes.isEmpty && dislikes.isEmpty)
              Text(l10n.tasteEmpty)
            else ...[
              Text(l10n.tasteLikes,
                  style: Theme.of(context).textTheme.labelLarge),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final e in likes)
                    Chip(
                      label: Text(
                          '${e.key.substring(2)} ${e.value.toStringAsFixed(1)}'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (dislikes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(l10n.tasteDislikes,
                    style: Theme.of(context).textTheme.labelLarge),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final e in dislikes)
                      Chip(
                        label: Text(
                            '${e.key.substring(2)} ${e.value.toStringAsFixed(1)}'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
