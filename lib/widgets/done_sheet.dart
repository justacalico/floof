import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum DoneChoice { photo, skip }

class DoneSheet extends StatelessWidget {
  const DoneSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.doneAskTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.photo_camera),
              label: Text(l10n.doneTakePhoto),
              onPressed: () => Navigator.of(context).pop(DoneChoice.photo),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(DoneChoice.skip),
              child: Text(l10n.doneSkip),
            ),
          ],
        ),
      ),
    );
  }
}
