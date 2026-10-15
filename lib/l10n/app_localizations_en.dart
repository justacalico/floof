// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'floof';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navProfiles => 'Profiles';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get feedEmpty => 'Nothing here yet. Pull some videos in.';

  @override
  String get feedError => 'Could not load the feed.';

  @override
  String get retry => 'Retry';

  @override
  String get like => 'Like';

  @override
  String get done => 'Done';

  @override
  String get openPost => 'Open in browser';

  @override
  String get doneAskTitle => 'Mark this video as done. Add a photo?';

  @override
  String get doneTakePhoto => 'Take a photo';

  @override
  String get doneSkip => 'Skip';

  @override
  String get doneRecorded => 'Marked as done';

  @override
  String get searchHint => 'Search tags, e.g. animated canine';

  @override
  String get searchEmpty => 'No videos matched that search.';

  @override
  String get addProfile => 'Add profile';

  @override
  String get profileNameHint => 'Profile name';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get rename => 'Rename';

  @override
  String get renameProfile => 'Rename profile';

  @override
  String get deleteProfile => 'Delete profile';

  @override
  String get activeProfile => 'Active profile';

  @override
  String get tapToSwitch => 'Tap to switch to this profile';

  @override
  String get statsTitle => 'This profile';

  @override
  String statsWatched(int count) {
    return '$count videos watched';
  }

  @override
  String statsDone(int count) {
    return '$count times done';
  }

  @override
  String get tasteTitle => 'What the algorithm learned';

  @override
  String get tasteEmpty =>
      'Watch some videos and the algorithm will learn your taste.';

  @override
  String get tasteLikes => 'Likes';

  @override
  String get tasteDislikes => 'Dislikes';

  @override
  String get historyEmpty => 'No history yet. Go watch something.';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get clearHistoryBody =>
      'Deletes your watch history and done marks for this profile.';

  @override
  String get clear => 'Clear';

  @override
  String get historyCleared => 'History cleared';

  @override
  String entryWatched(String time, String percent) {
    return 'Watched at $time · $percent';
  }

  @override
  String entryDone(String time) {
    return 'Done at $time';
  }

  @override
  String get settingsAccounts => 'Accounts';

  @override
  String get addAccount => 'Sign in';

  @override
  String get addGuestAccount => 'Add guest host';

  @override
  String get accountActive => 'Active account';

  @override
  String get removeAccount => 'Remove account';

  @override
  String get accountAdded => 'Signed in';

  @override
  String get signInFailed =>
      'Sign in failed. Check the username, API key and host.';

  @override
  String get username => 'Username';

  @override
  String get apiKey => 'API key';

  @override
  String get apiKeyHint => 'From your account settings on the site';

  @override
  String get host => 'Host';

  @override
  String get customHostUrl => 'Custom host URL';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeOled => 'OLED';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsContent => 'Content';

  @override
  String get ratingSafe => 'Safe only';

  @override
  String get ratingAll => 'Everything';

  @override
  String get ratingNote =>
      'Shows every rating the host serves. Off on e926, which only has safe posts.';

  @override
  String get settingsData => 'Data';

  @override
  String get resetAlgorithm => 'Reset recommendations';

  @override
  String get resetAlgorithmBody =>
      'Wipes what the algorithm learned about your taste for this profile.';

  @override
  String get reset => 'Reset';

  @override
  String get algorithmReset => 'Recommendations reset';

  @override
  String get settingsAbout => 'About';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get upToDate => 'You are on the latest release.';

  @override
  String updateAvailable(String tag) {
    return 'Version $tag is available';
  }

  @override
  String get updateCheckFailed => 'Could not check for updates.';

  @override
  String get allReleases => 'All releases';

  @override
  String get signIn => 'Sign in';
}

/// The translations for English, as used in the United Kingdom (`en_GB`).
class AppLocalizationsEnGb extends AppLocalizationsEn {
  AppLocalizationsEnGb() : super('en_GB');

  @override
  String get appName => 'floof';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navProfiles => 'Profiles';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get feedEmpty => 'Nothing here yet. Pull some videos in.';

  @override
  String get feedError => 'Could not load the feed.';

  @override
  String get retry => 'Retry';

  @override
  String get like => 'Like';

  @override
  String get done => 'Done';

  @override
  String get openPost => 'Open in browser';

  @override
  String get doneAskTitle => 'Mark this video as done. Add a photo?';

  @override
  String get doneTakePhoto => 'Take a photo';

  @override
  String get doneSkip => 'Skip';

  @override
  String get doneRecorded => 'Marked as done';

  @override
  String get searchHint => 'Search tags, e.g. animated canine';

  @override
  String get searchEmpty => 'No videos matched that search.';

  @override
  String get addProfile => 'Add profile';

  @override
  String get profileNameHint => 'Profile name';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get rename => 'Rename';

  @override
  String get renameProfile => 'Rename profile';

  @override
  String get deleteProfile => 'Delete profile';

  @override
  String get activeProfile => 'Active profile';

  @override
  String get tapToSwitch => 'Tap to switch to this profile';

  @override
  String get statsTitle => 'This profile';

  @override
  String statsWatched(int count) {
    return '$count videos watched';
  }

  @override
  String statsDone(int count) {
    return '$count times done';
  }

  @override
  String get tasteTitle => 'What the algorithm learned';

  @override
  String get tasteEmpty =>
      'Watch some videos and the algorithm will learn your taste.';

  @override
  String get tasteLikes => 'Likes';

  @override
  String get tasteDislikes => 'Dislikes';

  @override
  String get historyEmpty => 'No history yet. Go watch something.';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get clearHistoryBody =>
      'Deletes your watch history and done marks for this profile.';

  @override
  String get clear => 'Clear';

  @override
  String get historyCleared => 'History cleared';

  @override
  String entryWatched(String time, String percent) {
    return 'Watched at $time · $percent';
  }

  @override
  String entryDone(String time) {
    return 'Done at $time';
  }

  @override
  String get settingsAccounts => 'Accounts';

  @override
  String get addAccount => 'Sign in';

  @override
  String get addGuestAccount => 'Add guest host';

  @override
  String get accountActive => 'Active account';

  @override
  String get removeAccount => 'Remove account';

  @override
  String get accountAdded => 'Signed in';

  @override
  String get signInFailed =>
      'Sign in failed. Check the username, API key and host.';

  @override
  String get username => 'Username';

  @override
  String get apiKey => 'API key';

  @override
  String get apiKeyHint => 'From your account settings on the site';

  @override
  String get host => 'Host';

  @override
  String get customHostUrl => 'Custom host URL';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeOled => 'OLED';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsContent => 'Content';

  @override
  String get ratingSafe => 'Safe only';

  @override
  String get ratingAll => 'Everything';

  @override
  String get ratingNote =>
      'Shows every rating the host serves. Off on e926, which only has safe posts.';

  @override
  String get settingsData => 'Data';

  @override
  String get resetAlgorithm => 'Reset recommendations';

  @override
  String get resetAlgorithmBody =>
      'Wipes what the algorithm learned about your taste for this profile.';

  @override
  String get reset => 'Reset';

  @override
  String get algorithmReset => 'Recommendations reset';

  @override
  String get settingsAbout => 'About';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get upToDate => 'You are on the latest release.';

  @override
  String updateAvailable(String tag) {
    return 'Version $tag is available';
  }

  @override
  String get updateCheckFailed => 'Could not check for updates.';

  @override
  String get allReleases => 'All releases';

  @override
  String get signIn => 'Sign in';
}
