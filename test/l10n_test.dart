import 'package:floof/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void exercise(AppLocalizations l) {
  final strings = [
    l.appName,
    l.navHome,
    l.navSearch,
    l.navProfiles,
    l.navHistory,
    l.navSettings,
    l.feedEmpty,
    l.feedError,
    l.retry,
    l.like,
    l.done,
    l.openPost,
    l.doneAskTitle,
    l.doneTakePhoto,
    l.doneSkip,
    l.doneRecorded,
    l.searchHint,
    l.searchEmpty,
    l.addProfile,
    l.profileNameHint,
    l.cancel,
    l.create,
    l.rename,
    l.renameProfile,
    l.deleteProfile,
    l.activeProfile,
    l.tapToSwitch,
    l.statsTitle,
    l.statsWatched(3),
    l.statsDone(2),
    l.tasteTitle,
    l.tasteEmpty,
    l.tasteLikes,
    l.tasteDislikes,
    l.historyEmpty,
    l.clearHistory,
    l.clearHistoryBody,
    l.clear,
    l.historyCleared,
    l.entryWatched('10:00', '80%'),
    l.entryDone('10:00'),
    l.settingsAccounts,
    l.addAccount,
    l.addGuestAccount,
    l.accountActive,
    l.removeAccount,
    l.accountAdded,
    l.signIn,
    l.signInFailed,
    l.username,
    l.apiKey,
    l.apiKeyHint,
    l.host,
    l.customHostUrl,
    l.settingsAppearance,
    l.themeSystem,
    l.themeLight,
    l.themeDark,
    l.themeOled,
    l.settingsLanguage,
    l.settingsContent,
    l.ratingSafe,
    l.ratingAll,
    l.ratingNote,
    l.settingsData,
    l.resetAlgorithm,
    l.resetAlgorithmBody,
    l.reset,
    l.algorithmReset,
    l.settingsAbout,
    l.version('0.1.0'),
    l.checkForUpdates,
    l.upToDate,
    l.updateAvailable('v9.9.9'),
    l.updateCheckFailed,
    l.allReleases,
  ];
  for (final s in strings) {
    expect(s, isNotEmpty);
  }
}

void main() {
  test('every locale loads and provides all strings', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l = await AppLocalizations.delegate.load(locale);
      exercise(l);
    }
  });

  test('delegate reports supported locales', () {
    expect(AppLocalizations.delegate.isSupported(const Locale('en')), isTrue);
    expect(AppLocalizations.delegate.isSupported(const Locale('xx')), isFalse);
    expect(AppLocalizations.supportedLocales, isNotEmpty);
    expect(AppLocalizations.delegate.shouldReload(AppLocalizations.delegate),
        isFalse);
  });
}
