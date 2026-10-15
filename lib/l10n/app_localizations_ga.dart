// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Irish (`ga`).
class AppLocalizationsGa extends AppLocalizations {
  AppLocalizationsGa([String locale = 'ga']) : super(locale);

  @override
  String get appName => 'floof';

  @override
  String get navHome => 'Baile';

  @override
  String get navSearch => 'Cuardaigh';

  @override
  String get navProfiles => 'Próifílí';

  @override
  String get navHistory => 'Stair';

  @override
  String get navSettings => 'Socruithe';

  @override
  String get feedEmpty =>
      'Tá an áit seo folamh go fóil. Tarraing físeáin isteach.';

  @override
  String get feedError => 'Níorbh fhéidir an fotha a lódáil.';

  @override
  String get retry => 'Bain triail eile as';

  @override
  String get like => 'Is maith liom';

  @override
  String get done => 'Críochnaithe';

  @override
  String get openPost => 'Oscail sa bhrabhsálaí';

  @override
  String get doneAskTitle =>
      'Marcáil an físeán seo mar chríochnaithe. Grianghraf a chur leis?';

  @override
  String get doneTakePhoto => 'Tóg grianghraf';

  @override
  String get doneSkip => 'Léim thart';

  @override
  String get doneRecorded => 'Marcáilte mar chríochnaithe';

  @override
  String get searchHint => 'Cuardaigh clibeanna, m.sh. animated canine';

  @override
  String get searchEmpty => 'Níor aimsíodh físeáin don chuardach sin.';

  @override
  String get addProfile => 'Cuir próifíl leis';

  @override
  String get profileNameHint => 'Ainm na próifíle';

  @override
  String get cancel => 'Cealaigh';

  @override
  String get create => 'Cruthaigh';

  @override
  String get rename => 'Athainmnigh';

  @override
  String get renameProfile => 'Athainmnigh an phróifíl';

  @override
  String get deleteProfile => 'Scrios an phróifíl';

  @override
  String get activeProfile => 'An phróifíl ghníomhach';

  @override
  String get tapToSwitch => 'Tapáil chun aistriú go dtí an phróifíl seo';

  @override
  String get statsTitle => 'An phróifíl seo';

  @override
  String statsWatched(int count) {
    return '$count físeán feicthe';
  }

  @override
  String statsDone(int count) {
    return 'Críochnaithe $count uair';
  }

  @override
  String get tasteTitle => 'Rudaí a d\'fhoghlaim an t-algartam';

  @override
  String get tasteEmpty =>
      'Féach ar chúpla físeán agus foghlaimeoidh an t-algartam do bhlasta.';

  @override
  String get tasteLikes => 'Rudaí is maith leat';

  @override
  String get tasteDislikes => 'Rudaí nach maith leat';

  @override
  String get historyEmpty => 'Níl stair ann go fóil. Féach ar rud éigin.';

  @override
  String get clearHistory => 'Glan an stair';

  @override
  String get clearHistoryBody =>
      'Scriosann sé seo do stair faire agus marcanna críochnaithe don phróifíl seo.';

  @override
  String get clear => 'Glan';

  @override
  String get historyCleared => 'Stair glanta';

  @override
  String entryWatched(String time, String percent) {
    return 'Feicthe ag $time · $percent';
  }

  @override
  String entryDone(String time) {
    return 'Críochnaithe ag $time';
  }

  @override
  String get settingsAccounts => 'Cuntais';

  @override
  String get addAccount => 'Sínigh isteach';

  @override
  String get addGuestAccount => 'Cuir óstach aoi leis';

  @override
  String get accountActive => 'An cuntas gníomhach';

  @override
  String get removeAccount => 'Bain an cuntas';

  @override
  String get accountAdded => 'Sínithe isteach';

  @override
  String get signInFailed =>
      'Theip ar an tsíniú isteach. Seiceáil an t-ainm, an eochair API agus an t-óstach.';

  @override
  String get username => 'Ainm úsáideora';

  @override
  String get apiKey => 'Eochair API';

  @override
  String get apiKeyHint => 'Ó shocruithe do chuntais ar an suíomh';

  @override
  String get host => 'Óstach';

  @override
  String get customHostUrl => 'URL óstaigh shaincheaptha';

  @override
  String get settingsAppearance => 'Cuma';

  @override
  String get themeSystem => 'Córas';

  @override
  String get themeLight => 'Solasach';

  @override
  String get themeDark => 'Dorcha';

  @override
  String get themeOled => 'OLED';

  @override
  String get settingsLanguage => 'Teanga';

  @override
  String get settingsContent => 'Ábhar';

  @override
  String get ratingSafe => 'Sábháilte amháin';

  @override
  String get ratingAll => 'Gach rud';

  @override
  String get ratingNote =>
      'Taispeánann sé gach rátáil a fhreastalaíonn an t-óstach. Níl sé ar fáil ar e926, nach bhfuil ann ach postaí sábháilte.';

  @override
  String get settingsData => 'Sonraí';

  @override
  String get resetAlgorithm => 'Athshocraigh moltaí';

  @override
  String get resetAlgorithmBody =>
      'Glanann sé seo gach rud a d\'fhoghlaim an t-algartam faoi do bhlasta sa phróifíl seo.';

  @override
  String get reset => 'Athshocraigh';

  @override
  String get algorithmReset => 'Moltaí athshocraithe';

  @override
  String get settingsAbout => 'Faoi';

  @override
  String version(String version) {
    return 'Leagan $version';
  }

  @override
  String get checkForUpdates => 'Seiceáil le haghaidh nuashonruithe';

  @override
  String get upToDate => 'Tá an leagan is déanaí agat.';

  @override
  String updateAvailable(String tag) {
    return 'Tá leagan $tag ar fáil';
  }

  @override
  String get updateCheckFailed => 'Níorbh fhéidir nuashonruithe a sheiceáil.';

  @override
  String get allReleases => 'Gach eisiúint';

  @override
  String get signIn => 'Sínigh isteach';
}
