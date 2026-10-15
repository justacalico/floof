// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'floof';

  @override
  String get navHome => 'Главная';

  @override
  String get navSearch => 'Поиск';

  @override
  String get navProfiles => 'Профили';

  @override
  String get navHistory => 'История';

  @override
  String get navSettings => 'Настройки';

  @override
  String get feedEmpty => 'Здесь пока пусто. Подгрузите видео.';

  @override
  String get feedError => 'Не удалось загрузить ленту.';

  @override
  String get retry => 'Повторить';

  @override
  String get like => 'Нравится';

  @override
  String get done => 'Готово';

  @override
  String get openPost => 'Открыть в браузере';

  @override
  String get doneAskTitle => 'Отметить видео как завершённое. Добавить фото?';

  @override
  String get doneTakePhoto => 'Сделать фото';

  @override
  String get doneSkip => 'Пропустить';

  @override
  String get doneRecorded => 'Отмечено как завершённое';

  @override
  String get searchHint => 'Поиск по тегам, например animated canine';

  @override
  String get searchEmpty => 'По этому запросу видео не найдены.';

  @override
  String get addProfile => 'Добавить профиль';

  @override
  String get profileNameHint => 'Имя профиля';

  @override
  String get cancel => 'Отмена';

  @override
  String get create => 'Создать';

  @override
  String get rename => 'Переименовать';

  @override
  String get renameProfile => 'Переименовать профиль';

  @override
  String get deleteProfile => 'Удалить профиль';

  @override
  String get activeProfile => 'Активный профиль';

  @override
  String get tapToSwitch => 'Нажмите, чтобы переключиться';

  @override
  String get statsTitle => 'Этот профиль';

  @override
  String statsWatched(int count) {
    return 'Просмотрено видео: $count';
  }

  @override
  String statsDone(int count) {
    return 'Завершений: $count';
  }

  @override
  String get tasteTitle => 'Что выучил алгоритм';

  @override
  String get tasteEmpty => 'Посмотрите видео, и алгоритм узнает ваш вкус.';

  @override
  String get tasteLikes => 'Нравится';

  @override
  String get tasteDislikes => 'Не нравится';

  @override
  String get historyEmpty => 'Истории пока нет. Посмотрите что-нибудь.';

  @override
  String get clearHistory => 'Очистить историю';

  @override
  String get clearHistoryBody =>
      'Удаляет историю просмотров и отметки о завершении для этого профиля.';

  @override
  String get clear => 'Очистить';

  @override
  String get historyCleared => 'История очищена';

  @override
  String entryWatched(String time, String percent) {
    return 'Просмотр в $time · $percent';
  }

  @override
  String entryDone(String time) {
    return 'Завершено в $time';
  }

  @override
  String get settingsAccounts => 'Аккаунты';

  @override
  String get addAccount => 'Войти';

  @override
  String get addGuestAccount => 'Добавить гостевой хост';

  @override
  String get accountActive => 'Активный аккаунт';

  @override
  String get removeAccount => 'Удалить аккаунт';

  @override
  String get accountAdded => 'Вход выполнен';

  @override
  String get signInFailed =>
      'Не удалось войти. Проверьте имя, ключ API и хост.';

  @override
  String get username => 'Имя пользователя';

  @override
  String get apiKey => 'Ключ API';

  @override
  String get apiKeyHint => 'Из настроек аккаунта на сайте';

  @override
  String get host => 'Хост';

  @override
  String get customHostUrl => 'URL своего хоста';

  @override
  String get settingsAppearance => 'Внешний вид';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeOled => 'OLED';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsContent => 'Контент';

  @override
  String get ratingSafe => 'Только безопасное';

  @override
  String get ratingAll => 'Всё подряд';

  @override
  String get ratingNote =>
      'Показывает все рейтинги хоста. Недоступно на e926, где только безопасные посты.';

  @override
  String get settingsData => 'Данные';

  @override
  String get resetAlgorithm => 'Сбросить рекомендации';

  @override
  String get resetAlgorithmBody =>
      'Стирает всё, что алгоритм узнал о вашем вкусе в этом профиле.';

  @override
  String get reset => 'Сбросить';

  @override
  String get algorithmReset => 'Рекомендации сброшены';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String version(String version) {
    return 'Версия $version';
  }

  @override
  String get checkForUpdates => 'Проверить обновления';

  @override
  String get upToDate => 'У вас последняя версия.';

  @override
  String updateAvailable(String tag) {
    return 'Доступна версия $tag';
  }

  @override
  String get updateCheckFailed => 'Не удалось проверить обновления.';

  @override
  String get allReleases => 'Все релизы';

  @override
  String get signIn => 'Войти';
}
