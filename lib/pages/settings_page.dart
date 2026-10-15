import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/account.dart';
import '../services/version_checker.dart';
import '../state/app_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _SectionHeader(title: l10n.settingsAccounts),
        _AccountsCard(state: state),
        _SectionHeader(title: l10n.settingsAppearance),
        _AppearanceCard(state: state),
        _SectionHeader(title: l10n.settingsLanguage),
        _LanguageCard(state: state),
        _SectionHeader(title: l10n.settingsContent),
        _ContentCard(state: state),
        _SectionHeader(title: l10n.settingsData),
        _DataCard(state: state),
        _SectionHeader(title: l10n.settingsAbout),
        _AboutCard(state: state),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 6),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _AccountsCard extends StatelessWidget {
  final AppState state;
  const _AccountsCard({required this.state});

  Future<void> _addLogin(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final state = context.read<AppState>();
    final userCtl = TextEditingController();
    final keyCtl = TextEditingController();
    final hostCtl = TextEditingController();
    var host = BooruHost.e926.baseUrl;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(l10n.addAccount),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: host,
                decoration: InputDecoration(labelText: l10n.host),
                items: [
                  for (final h in BooruHost.known)
                    DropdownMenuItem(value: h.baseUrl, child: Text(h.name)),
                  const DropdownMenuItem(value: 'custom', child: Text('custom')),
                ],
                onChanged: (v) => setDialog(() => host = v ?? host),
              ),
              if (host == 'custom')
                TextField(
                  controller: hostCtl,
                  decoration: InputDecoration(
                    labelText: l10n.customHostUrl,
                    hintText: 'https://',
                  ),
                ),
              TextField(
                controller: userCtl,
                decoration: InputDecoration(labelText: l10n.username),
              ),
              TextField(
                controller: keyCtl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.apiKey,
                  hintText: l10n.apiKeyHint,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.signIn),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !context.mounted) return;
    final hostUrl = host == 'custom' ? hostCtl.text.trim() : host;
    try {
      await state.addAccount(userCtl.text.trim(), keyCtl.text.trim(), hostUrl);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.accountAdded)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.signInFailed)));
      }
    }
  }

  Future<void> _addGuest(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final state = context.read<AppState>();
    var host = BooruHost.e621.baseUrl;
    final hostCtl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(l10n.addGuestAccount),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: host,
                decoration: InputDecoration(labelText: l10n.host),
                items: [
                  for (final h in BooruHost.known)
                    DropdownMenuItem(value: h.baseUrl, child: Text(h.name)),
                  const DropdownMenuItem(value: 'custom', child: Text('custom')),
                ],
                onChanged: (v) => setDialog(() => host = v ?? host),
              ),
              if (host == 'custom')
                TextField(
                  controller: hostCtl,
                  decoration: InputDecoration(
                    labelText: l10n.customHostUrl,
                    hintText: 'https://',
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.create),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    state.addGuestAccount(host == 'custom' ? hostCtl.text.trim() : host);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Column(
        children: [
          for (final account in state.accounts)
            ListTile(
              leading: Icon(account.guest
                  ? Icons.person_outline
                  : Icons.verified_user),
              title: Text(account.displayName),
              subtitle: account.id == state.activeAccountId
                  ? Text(l10n.accountActive)
                  : Text(account.hostLabel),
              trailing: state.accounts.length <= 1
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: l10n.removeAccount,
                      onPressed: () => state.removeAccount(account.id),
                    ),
              onTap: () => state.setActiveAccount(account.id),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.login),
                    label: Text(l10n.addAccount),
                    onPressed: () => _addLogin(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_add_alt),
                    label: Text(l10n.addGuestAccount),
                    onPressed: () => _addGuest(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  final AppState state;
  const _AppearanceCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      AppTheme.system: l10n.themeSystem,
      AppTheme.light: l10n.themeLight,
      AppTheme.dark: l10n.themeDark,
      AppTheme.oled: l10n.themeOled,
    };
    return Card(
      child: RadioGroup<AppTheme>(
        groupValue: state.theme,
        onChanged: (v) => state.setTheme(v ?? AppTheme.system),
        child: Column(
          children: [
            for (final t in AppTheme.values)
              RadioListTile<AppTheme>(
                title: Text(labels[t]!),
                value: t,
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final AppState state;
  const _LanguageCard({required this.state});

  static const _locales = [
    ('', 'System'),
    ('en_GB', 'Traditional English'),
    ('zh', '简体中文'),
    ('ru', 'Русский'),
    ('ga', 'Gaeilge'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: RadioGroup<String>(
        groupValue: state.localeTag,
        onChanged: (v) => state.setLocale(v ?? ''),
        child: Column(
          children: [
            for (final (tag, name) in _locales)
              RadioListTile<String>(
                title: Text(name),
                value: tag,
              ),
          ],
        ),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final AppState state;
  const _ContentCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSafeHost = state.activeAccount.hostBaseUrl == BooruHost.e926.baseUrl;
    return Card(
      child: RadioGroup<ContentRating>(
        groupValue: state.contentRating,
        onChanged: (v) {
          if (!isSafeHost) {
            state.setContentRating(v ?? ContentRating.safe);
          }
        },
        child: Column(
          children: [
            RadioListTile<ContentRating>(
              title: Text(l10n.ratingSafe),
              enabled: !isSafeHost,
              value: ContentRating.safe,
            ),
            RadioListTile<ContentRating>(
              title: Text(l10n.ratingAll),
              subtitle: Text(l10n.ratingNote),
              enabled: !isSafeHost,
              value: ContentRating.all,
            ),
          ],
        ),
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  final AppState state;
  const _DataCard({required this.state});

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required VoidCallback action,
    required String doneMessage,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      action();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(doneMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.history_toggle_off),
            title: Text(l10n.clearHistory),
            subtitle: Text(l10n.clearHistoryBody),
            onTap: () => _confirm(
              context,
              title: l10n.clearHistory,
              body: l10n.clearHistoryBody,
              confirmLabel: l10n.clear,
              action: state.clearHistory,
              doneMessage: l10n.historyCleared,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.model_training),
            title: Text(l10n.resetAlgorithm),
            subtitle: Text(l10n.resetAlgorithmBody),
            onTap: () => _confirm(
              context,
              title: l10n.resetAlgorithm,
              body: l10n.resetAlgorithmBody,
              confirmLabel: l10n.reset,
              action: state.resetAlgorithm,
              doneMessage: l10n.algorithmReset,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final AppState state;
  const _AboutCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final check = state.lastUpdateCheck;
    Widget status;
    switch (check.status) {
      case UpdateCheckStatus.none:
        status = const SizedBox.shrink();
      case UpdateCheckStatus.upToDate:
        status = ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text(l10n.upToDate),
        );
      case UpdateCheckStatus.available:
        final update = check.update!;
        status = ListTile(
          leading: const Icon(Icons.system_update_alt, color: Colors.amber),
          title: Text(l10n.updateAvailable(update.tag)),
          subtitle: Text(update.releaseUrl),
          onTap: () => launchUrl(Uri.parse(update.releaseUrl)),
        );
      case UpdateCheckStatus.failed:
        status = ListTile(
          leading: const Icon(Icons.error_outline, color: Colors.red),
          title: Text(l10n.updateCheckFailed),
        );
    }
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('floof'),
            subtitle: Text(l10n.version(state.appVersion)),
          ),
          ListTile(
            leading: state.updateChecking
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            title: Text(l10n.checkForUpdates),
            onTap: state.updateChecking ? null : state.checkForUpdates,
          ),
          status,
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l10n.allReleases),
            onTap: () =>
                launchUrl(Uri.parse(VersionChecker.releasesPage)),
          ),
        ],
      ),
    );
  }
}
