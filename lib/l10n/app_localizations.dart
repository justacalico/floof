import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ga.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'GB'),
    Locale('ga'),
    Locale('ru'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ];

  /// No description provided for @appName.
  ///
  /// In en_GB, this message translates to:
  /// **'floof'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en_GB, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en_GB, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navProfiles.
  ///
  /// In en_GB, this message translates to:
  /// **'Profiles'**
  String get navProfiles;

  /// No description provided for @navHistory.
  ///
  /// In en_GB, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en_GB, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @feedEmpty.
  ///
  /// In en_GB, this message translates to:
  /// **'Nothing here yet. Pull some videos in.'**
  String get feedEmpty;

  /// No description provided for @feedError.
  ///
  /// In en_GB, this message translates to:
  /// **'Could not load the feed.'**
  String get feedError;

  /// No description provided for @retry.
  ///
  /// In en_GB, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @like.
  ///
  /// In en_GB, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @done.
  ///
  /// In en_GB, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @openPost.
  ///
  /// In en_GB, this message translates to:
  /// **'Open in browser'**
  String get openPost;

  /// No description provided for @doneAskTitle.
  ///
  /// In en_GB, this message translates to:
  /// **'Mark this video as done. Add a photo?'**
  String get doneAskTitle;

  /// No description provided for @doneTakePhoto.
  ///
  /// In en_GB, this message translates to:
  /// **'Take a photo'**
  String get doneTakePhoto;

  /// No description provided for @doneSkip.
  ///
  /// In en_GB, this message translates to:
  /// **'Skip'**
  String get doneSkip;

  /// No description provided for @doneRecorded.
  ///
  /// In en_GB, this message translates to:
  /// **'Marked as done'**
  String get doneRecorded;

  /// No description provided for @searchHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Search tags, e.g. animated canine'**
  String get searchHint;

  /// No description provided for @searchEmpty.
  ///
  /// In en_GB, this message translates to:
  /// **'No videos matched that search.'**
  String get searchEmpty;

  /// No description provided for @addProfile.
  ///
  /// In en_GB, this message translates to:
  /// **'Add profile'**
  String get addProfile;

  /// No description provided for @profileNameHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Profile name'**
  String get profileNameHint;

  /// No description provided for @cancel.
  ///
  /// In en_GB, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en_GB, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @rename.
  ///
  /// In en_GB, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @renameProfile.
  ///
  /// In en_GB, this message translates to:
  /// **'Rename profile'**
  String get renameProfile;

  /// No description provided for @deleteProfile.
  ///
  /// In en_GB, this message translates to:
  /// **'Delete profile'**
  String get deleteProfile;

  /// No description provided for @activeProfile.
  ///
  /// In en_GB, this message translates to:
  /// **'Active profile'**
  String get activeProfile;

  /// No description provided for @tapToSwitch.
  ///
  /// In en_GB, this message translates to:
  /// **'Tap to switch to this profile'**
  String get tapToSwitch;

  /// No description provided for @statsTitle.
  ///
  /// In en_GB, this message translates to:
  /// **'This profile'**
  String get statsTitle;

  /// No description provided for @statsWatched.
  ///
  /// In en_GB, this message translates to:
  /// **'{count} videos watched'**
  String statsWatched(int count);

  /// No description provided for @statsDone.
  ///
  /// In en_GB, this message translates to:
  /// **'{count} times done'**
  String statsDone(int count);

  /// No description provided for @tasteTitle.
  ///
  /// In en_GB, this message translates to:
  /// **'What the algorithm learned'**
  String get tasteTitle;

  /// No description provided for @tasteEmpty.
  ///
  /// In en_GB, this message translates to:
  /// **'Watch some videos and the algorithm will learn your taste.'**
  String get tasteEmpty;

  /// No description provided for @tasteLikes.
  ///
  /// In en_GB, this message translates to:
  /// **'Likes'**
  String get tasteLikes;

  /// No description provided for @tasteDislikes.
  ///
  /// In en_GB, this message translates to:
  /// **'Dislikes'**
  String get tasteDislikes;

  /// No description provided for @historyEmpty.
  ///
  /// In en_GB, this message translates to:
  /// **'No history yet. Go watch something.'**
  String get historyEmpty;

  /// No description provided for @clearHistory.
  ///
  /// In en_GB, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @clearHistoryBody.
  ///
  /// In en_GB, this message translates to:
  /// **'Deletes your watch history and done marks for this profile.'**
  String get clearHistoryBody;

  /// No description provided for @clear.
  ///
  /// In en_GB, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @historyCleared.
  ///
  /// In en_GB, this message translates to:
  /// **'History cleared'**
  String get historyCleared;

  /// No description provided for @entryWatched.
  ///
  /// In en_GB, this message translates to:
  /// **'Watched at {time} · {percent}'**
  String entryWatched(String time, String percent);

  /// No description provided for @entryDone.
  ///
  /// In en_GB, this message translates to:
  /// **'Done at {time}'**
  String entryDone(String time);

  /// No description provided for @settingsAccounts.
  ///
  /// In en_GB, this message translates to:
  /// **'Accounts'**
  String get settingsAccounts;

  /// No description provided for @addAccount.
  ///
  /// In en_GB, this message translates to:
  /// **'Sign in'**
  String get addAccount;

  /// No description provided for @addGuestAccount.
  ///
  /// In en_GB, this message translates to:
  /// **'Add guest host'**
  String get addGuestAccount;

  /// No description provided for @accountActive.
  ///
  /// In en_GB, this message translates to:
  /// **'Active account'**
  String get accountActive;

  /// No description provided for @removeAccount.
  ///
  /// In en_GB, this message translates to:
  /// **'Remove account'**
  String get removeAccount;

  /// No description provided for @accountAdded.
  ///
  /// In en_GB, this message translates to:
  /// **'Signed in'**
  String get accountAdded;

  /// No description provided for @signInFailed.
  ///
  /// In en_GB, this message translates to:
  /// **'Sign in failed. Check the username, API key and host.'**
  String get signInFailed;

  /// No description provided for @username.
  ///
  /// In en_GB, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @apiKey.
  ///
  /// In en_GB, this message translates to:
  /// **'API key'**
  String get apiKey;

  /// No description provided for @apiKeyHint.
  ///
  /// In en_GB, this message translates to:
  /// **'From your account settings on the site'**
  String get apiKeyHint;

  /// No description provided for @host.
  ///
  /// In en_GB, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @customHostUrl.
  ///
  /// In en_GB, this message translates to:
  /// **'Custom host URL'**
  String get customHostUrl;

  /// No description provided for @settingsAppearance.
  ///
  /// In en_GB, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In en_GB, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en_GB, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en_GB, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeOled.
  ///
  /// In en_GB, this message translates to:
  /// **'OLED'**
  String get themeOled;

  /// No description provided for @settingsLanguage.
  ///
  /// In en_GB, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsContent.
  ///
  /// In en_GB, this message translates to:
  /// **'Content'**
  String get settingsContent;

  /// No description provided for @ratingSafe.
  ///
  /// In en_GB, this message translates to:
  /// **'Safe only'**
  String get ratingSafe;

  /// No description provided for @ratingAll.
  ///
  /// In en_GB, this message translates to:
  /// **'Everything'**
  String get ratingAll;

  /// No description provided for @ratingNote.
  ///
  /// In en_GB, this message translates to:
  /// **'Shows every rating the host serves. Off on e926, which only has safe posts.'**
  String get ratingNote;

  /// No description provided for @settingsData.
  ///
  /// In en_GB, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @resetAlgorithm.
  ///
  /// In en_GB, this message translates to:
  /// **'Reset recommendations'**
  String get resetAlgorithm;

  /// No description provided for @resetAlgorithmBody.
  ///
  /// In en_GB, this message translates to:
  /// **'Wipes what the algorithm learned about your taste for this profile.'**
  String get resetAlgorithmBody;

  /// No description provided for @reset.
  ///
  /// In en_GB, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @algorithmReset.
  ///
  /// In en_GB, this message translates to:
  /// **'Recommendations reset'**
  String get algorithmReset;

  /// No description provided for @settingsAbout.
  ///
  /// In en_GB, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @version.
  ///
  /// In en_GB, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @checkForUpdates.
  ///
  /// In en_GB, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @upToDate.
  ///
  /// In en_GB, this message translates to:
  /// **'You are on the latest release.'**
  String get upToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In en_GB, this message translates to:
  /// **'Version {tag} is available'**
  String updateAvailable(String tag);

  /// No description provided for @updateCheckFailed.
  ///
  /// In en_GB, this message translates to:
  /// **'Could not check for updates.'**
  String get updateCheckFailed;

  /// No description provided for @allReleases.
  ///
  /// In en_GB, this message translates to:
  /// **'All releases'**
  String get allReleases;

  /// No description provided for @signIn.
  ///
  /// In en_GB, this message translates to:
  /// **'Sign in'**
  String get signIn;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ga', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
        }
        break;
      }
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'GB':
            return AppLocalizationsEnGb();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ga':
      return AppLocalizationsGa();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
