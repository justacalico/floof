// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'floof';

  @override
  String get navHome => '首页';

  @override
  String get navSearch => '搜索';

  @override
  String get navProfiles => '档案';

  @override
  String get navHistory => '历史';

  @override
  String get navSettings => '设置';

  @override
  String get feedEmpty => '这里还没有内容,拉取一些视频吧。';

  @override
  String get feedError => '无法加载推荐流。';

  @override
  String get retry => '重试';

  @override
  String get like => '喜欢';

  @override
  String get done => '完成';

  @override
  String get openPost => '在浏览器中打开';

  @override
  String get doneAskTitle => '把这个视频标记为完成,要加一张照片吗?';

  @override
  String get doneTakePhoto => '拍一张照片';

  @override
  String get doneSkip => '跳过';

  @override
  String get doneRecorded => '已标记为完成';

  @override
  String get searchHint => '搜索标签,例如 animated canine';

  @override
  String get searchEmpty => '没有视频匹配这个搜索。';

  @override
  String get addProfile => '添加档案';

  @override
  String get profileNameHint => '档案名称';

  @override
  String get cancel => '取消';

  @override
  String get create => '创建';

  @override
  String get rename => '重命名';

  @override
  String get renameProfile => '重命名档案';

  @override
  String get deleteProfile => '删除档案';

  @override
  String get activeProfile => '当前档案';

  @override
  String get tapToSwitch => '点按切换到此档案';

  @override
  String get statsTitle => '此档案';

  @override
  String statsWatched(int count) {
    return '已观看 $count 个视频';
  }

  @override
  String statsDone(int count) {
    return '完成 $count 次';
  }

  @override
  String get tasteTitle => '算法学到了什么';

  @override
  String get tasteEmpty => '看一些视频,算法就会了解你的口味。';

  @override
  String get tasteLikes => '喜欢';

  @override
  String get tasteDislikes => '不喜欢';

  @override
  String get historyEmpty => '还没有历史记录,去看点什么吧。';

  @override
  String get clearHistory => '清除历史';

  @override
  String get clearHistoryBody => '删除此档案的观看历史和完成标记。';

  @override
  String get clear => '清除';

  @override
  String get historyCleared => '历史已清除';

  @override
  String entryWatched(String time, String percent) {
    return '观看于 $time · $percent';
  }

  @override
  String entryDone(String time) {
    return '完成于 $time';
  }

  @override
  String get settingsAccounts => '账户';

  @override
  String get addAccount => '登录';

  @override
  String get addGuestAccount => '添加访客站点';

  @override
  String get accountActive => '当前账户';

  @override
  String get removeAccount => '移除账户';

  @override
  String get accountAdded => '已登录';

  @override
  String get signInFailed => '登录失败,请检查用户名、API 密钥和站点。';

  @override
  String get username => '用户名';

  @override
  String get apiKey => 'API 密钥';

  @override
  String get apiKeyHint => '在站点的账户设置中获取';

  @override
  String get host => '站点';

  @override
  String get customHostUrl => '自定义站点地址';

  @override
  String get settingsAppearance => '外观';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeOled => 'OLED';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsContent => '内容';

  @override
  String get ratingSafe => '仅安全内容';

  @override
  String get ratingAll => '全部内容';

  @override
  String get ratingNote => '显示站点提供的所有分级。e926 上不可用,它只有安全帖子。';

  @override
  String get settingsData => '数据';

  @override
  String get resetAlgorithm => '重置推荐';

  @override
  String get resetAlgorithmBody => '清除算法在此档案上学到的口味偏好。';

  @override
  String get reset => '重置';

  @override
  String get algorithmReset => '推荐已重置';

  @override
  String get settingsAbout => '关于';

  @override
  String version(String version) {
    return '版本 $version';
  }

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get upToDate => '已是最新版本。';

  @override
  String updateAvailable(String tag) {
    return '新版本 $tag 可用';
  }

  @override
  String get updateCheckFailed => '无法检查更新。';

  @override
  String get allReleases => '所有版本';

  @override
  String get signIn => '登录';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get appName => 'floof';

  @override
  String get navHome => '首页';

  @override
  String get navSearch => '搜索';

  @override
  String get navProfiles => '档案';

  @override
  String get navHistory => '历史';

  @override
  String get navSettings => '设置';

  @override
  String get feedEmpty => '这里还没有内容,拉取一些视频吧。';

  @override
  String get feedError => '无法加载推荐流。';

  @override
  String get retry => '重试';

  @override
  String get like => '喜欢';

  @override
  String get done => '完成';

  @override
  String get openPost => '在浏览器中打开';

  @override
  String get doneAskTitle => '把这个视频标记为完成,要加一张照片吗?';

  @override
  String get doneTakePhoto => '拍一张照片';

  @override
  String get doneSkip => '跳过';

  @override
  String get doneRecorded => '已标记为完成';

  @override
  String get searchHint => '搜索标签,例如 animated canine';

  @override
  String get searchEmpty => '没有视频匹配这个搜索。';

  @override
  String get addProfile => '添加档案';

  @override
  String get profileNameHint => '档案名称';

  @override
  String get cancel => '取消';

  @override
  String get create => '创建';

  @override
  String get rename => '重命名';

  @override
  String get renameProfile => '重命名档案';

  @override
  String get deleteProfile => '删除档案';

  @override
  String get activeProfile => '当前档案';

  @override
  String get tapToSwitch => '点按切换到此档案';

  @override
  String get statsTitle => '此档案';

  @override
  String statsWatched(int count) {
    return '已观看 $count 个视频';
  }

  @override
  String statsDone(int count) {
    return '完成 $count 次';
  }

  @override
  String get tasteTitle => '算法学到了什么';

  @override
  String get tasteEmpty => '看一些视频,算法就会了解你的口味。';

  @override
  String get tasteLikes => '喜欢';

  @override
  String get tasteDislikes => '不喜欢';

  @override
  String get historyEmpty => '还没有历史记录,去看点什么吧。';

  @override
  String get clearHistory => '清除历史';

  @override
  String get clearHistoryBody => '删除此档案的观看历史和完成标记。';

  @override
  String get clear => '清除';

  @override
  String get historyCleared => '历史已清除';

  @override
  String entryWatched(String time, String percent) {
    return '观看于 $time · $percent';
  }

  @override
  String entryDone(String time) {
    return '完成于 $time';
  }

  @override
  String get settingsAccounts => '账户';

  @override
  String get addAccount => '登录';

  @override
  String get addGuestAccount => '添加访客站点';

  @override
  String get accountActive => '当前账户';

  @override
  String get removeAccount => '移除账户';

  @override
  String get accountAdded => '已登录';

  @override
  String get signInFailed => '登录失败,请检查用户名、API 密钥和站点。';

  @override
  String get username => '用户名';

  @override
  String get apiKey => 'API 密钥';

  @override
  String get apiKeyHint => '在站点的账户设置中获取';

  @override
  String get host => '站点';

  @override
  String get customHostUrl => '自定义站点地址';

  @override
  String get settingsAppearance => '外观';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeOled => 'OLED';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsContent => '内容';

  @override
  String get ratingSafe => '仅安全内容';

  @override
  String get ratingAll => '全部内容';

  @override
  String get ratingNote => '显示站点提供的所有分级。e926 上不可用,它只有安全帖子。';

  @override
  String get settingsData => '数据';

  @override
  String get resetAlgorithm => '重置推荐';

  @override
  String get resetAlgorithmBody => '清除算法在此档案上学到的口味偏好。';

  @override
  String get reset => '重置';

  @override
  String get algorithmReset => '推荐已重置';

  @override
  String get settingsAbout => '关于';

  @override
  String version(String version) {
    return '版本 $version';
  }

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get upToDate => '已是最新版本。';

  @override
  String updateAvailable(String tag) {
    return '新版本 $tag 可用';
  }

  @override
  String get updateCheckFailed => '无法检查更新。';

  @override
  String get allReleases => '所有版本';

  @override
  String get signIn => '登录';
}
