import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';
import '../models/app_update.dart';
import '../models/history_entry.dart';
import '../models/post.dart';
import '../models/profile.dart';
import '../services/booru_client.dart';
import '../services/feed_service.dart';
import '../services/taste_engine.dart';
import '../services/version_checker.dart';

enum AppTheme { system, light, dark, oled }

enum ContentRating { safe, all }

class AppState extends ChangeNotifier {
  final SharedPreferences prefs;
  final String docsDir;
  final BooruClient Function(Account account) clientFactory;
  final ImagePicker? imagePicker;
  final VersionChecker Function(String version) checkerFactory;
  final DateTime Function() now;

  AppState({
    required this.prefs,
    this.docsDir = '',
    BooruClient Function(Account)? clientFactory,
    this.imagePicker,
    VersionChecker Function(String)? checkerFactory,
    DateTime Function()? now,
    http.Client? httpClient,
  })  : clientFactory = clientFactory ??
            ((a) => BooruClient(
                  baseUrl: a.hostBaseUrl,
                  username: a.username,
                  apiKey: a.apiKey,
                  client: httpClient,
                )),
        checkerFactory = checkerFactory ??
            ((v) => VersionChecker(currentVersion: v, client: httpClient)),
        now = now ?? DateTime.now;

  List<Account> accounts = [Account.guest()];
  String activeAccountId = '';
  List<Profile> profiles = [];
  String activeProfileId = '';
  AppTheme theme = AppTheme.system;
  String localeTag = '';
  ContentRating contentRating = ContentRating.safe;
  String appVersion = '0.1.0';

  TasteEngine engine = TasteEngine();
  List<HistoryEntry> history = [];
  List<DoneEntry> dones = [];
  Set<int> likedPostIds = {};
  final List<Post> feedPosts = [];
  bool feedLoading = false;
  Object? feedError;
  FeedService? _feed;
  BooruClient? _client;
  UpdateCheckResult lastUpdateCheck = UpdateCheckResult.none;
  bool updateChecking = false;

  bool get loaded => profiles.isNotEmpty;

  BooruClient get client => _client ??= clientFactory(activeAccount);

  Account get activeAccount {
    for (final a in accounts) {
      if (a.id == activeAccountId) return a;
    }
    return accounts.first;
  }

  Profile get activeProfile => profiles.firstWhere(
        (p) => p.id == activeProfileId,
        orElse: () => profiles.first,
      );

  String get _profileKey => 'profile.$activeProfileId';
  static const _historyLimit = 500;

  void load() {
    final accJson = prefs.getString('accounts');
    if (accJson != null) {
      final list = jsonDecode(accJson) as List;
      accounts = list
          .whereType<Map<String, dynamic>>()
          .map(Account.fromJson)
          .toList();
    }
    if (accounts.isEmpty) accounts = [Account.guest()];
    activeAccountId = prefs.getString('activeAccountId') ?? accounts.first.id;

    final profJson = prefs.getString('profiles');
    if (profJson != null) {
      profiles = (jsonDecode(profJson) as List)
          .whereType<Map<String, dynamic>>()
          .map(Profile.fromJson)
          .toList();
    }
    if (profiles.isEmpty) {
      profiles = [
        Profile(id: 'default', name: 'Default', createdAt: now()),
      ];
    }
    activeProfileId = prefs.getString('activeProfileId') ?? profiles.first.id;

    theme = AppTheme.values[prefs.getInt('theme') ?? 0];
    localeTag = prefs.getString('locale') ?? '';
    contentRating =
        ContentRating.values[prefs.getInt('contentRating') ?? 0];

    _loadProfile();
    notifyListeners();
  }

  void _loadProfile() {
    final tasteJson = prefs.getString('$_profileKey.taste');
    engine = tasteJson != null
        ? TasteEngine.fromJson(jsonDecode(tasteJson) as Map<String, dynamic>)
        : TasteEngine();
    final histJson = prefs.getString('$_profileKey.history');
    history = histJson != null
        ? (jsonDecode(histJson) as List)
            .whereType<Map<String, dynamic>>()
            .map(HistoryEntry.fromJson)
            .toList()
        : [];
    final doneJson = prefs.getString('$_profileKey.done');
    dones = doneJson != null
        ? (jsonDecode(doneJson) as List)
            .whereType<Map<String, dynamic>>()
            .map(DoneEntry.fromJson)
            .toList()
        : [];
    likedPostIds = (prefs.getStringList('$_profileKey.liked') ?? [])
        .map(int.parse)
        .toSet();
    feedPosts.clear();
    _feed = null;
  }

  void _saveProfile() {
    prefs.setString('$_profileKey.taste', jsonEncode(engine.toJson()));
    prefs.setString(
      '$_profileKey.history',
      jsonEncode(history.map((e) => e.toJson()).toList()),
    );
    prefs.setString(
      '$_profileKey.done',
      jsonEncode(dones.map((e) => e.toJson()).toList()),
    );
  }

  void _saveAccounts() {
    prefs.setString(
      'accounts',
      jsonEncode(accounts.map((a) => a.toJson()).toList()),
    );
    prefs.setString('activeAccountId', activeAccountId);
  }

  void _saveProfiles() {
    prefs.setString(
      'profiles',
      jsonEncode(profiles.map((p) => p.toJson()).toList()),
    );
    prefs.setString('activeProfileId', activeProfileId);
  }

  void setTheme(AppTheme t) {
    theme = t;
    prefs.setInt('theme', t.index);
    notifyListeners();
  }

  void setLocale(String tag) {
    localeTag = tag;
    prefs.setString('locale', tag);
    notifyListeners();
  }

  void setContentRating(ContentRating r) {
    contentRating = r;
    prefs.setInt('contentRating', r.index);
    refreshFeed();
  }

  Future<void> addAccount(
      String username, String apiKey, String hostBaseUrl) async {
    final account = Account(
      id: '$username@$hostBaseUrl',
      username: username,
      apiKey: apiKey,
      hostBaseUrl: hostBaseUrl,
      guest: false,
    );
    final probe = clientFactory(account);
    final ok = await probe.verifyLogin();
    probe.dispose();
    if (!ok) throw const BooruException('login failed', 401);
    accounts = [
      ...accounts.where((a) => a.id != account.id),
      account,
    ];
    setActiveAccount(account.id);
  }

  void addGuestAccount(String hostBaseUrl) {
    final account = Account.guest(hostBaseUrl);
    if (accounts.every((a) => a.id != account.id)) {
      accounts = [...accounts, account];
    }
    setActiveAccount(account.id);
  }

  void setActiveAccount(String id) {
    activeAccountId = id;
    _client?.dispose();
    _client = null;
    _saveAccounts();
    refreshFeed();
  }

  void removeAccount(String id) {
    if (accounts.length <= 1) return;
    accounts = accounts.where((a) => a.id != id).toList();
    if (activeAccountId == id) {
      activeAccountId = accounts.first.id;
      _client?.dispose();
      _client = null;
      refreshFeed();
    }
    _saveAccounts();
    notifyListeners();
  }

  void addProfile(String name) {
    final id = 'p${now().millisecondsSinceEpoch}';
    profiles = [...profiles, Profile(id: id, name: name, createdAt: now())];
    _saveProfiles();
    switchProfile(id);
  }

  void switchProfile(String id) {
    if (activeProfileId == id) return;
    _saveProfile();
    activeProfileId = id;
    prefs.setString('activeProfileId', id);
    _loadProfile();
    notifyListeners();
  }

  void removeProfile(String id) {
    if (profiles.length <= 1) return;
    profiles = profiles.where((p) => p.id != id).toList();
    prefs.remove('profile.$id.taste');
    prefs.remove('profile.$id.history');
    prefs.remove('profile.$id.done');
    if (activeProfileId == id) {
      activeProfileId = profiles.first.id;
      prefs.setString('activeProfileId', activeProfileId);
      _loadProfile();
    }
    _saveProfiles();
    notifyListeners();
  }

  void renameProfile(String id, String name) {
    profiles = [
      for (final p in profiles)
        p.id == id ? Profile(id: p.id, name: name, createdAt: p.createdAt) : p,
    ];
    _saveProfiles();
    notifyListeners();
  }

  String get ratingFilter {
    final onSafeHost = activeAccount.hostBaseUrl == BooruHost.e926.baseUrl;
    if (onSafeHost || contentRating == ContentRating.all) return '';
    return 'rating:s';
  }

  FeedService get feed => _feed ??= FeedService(
        client: client,
        engine: engine,
        extraTagFilter: ratingFilter,
      );

  Future<void> loadMoreFeed({int batchSize = 20}) async {
    if (feedLoading) return;
    feedLoading = true;
    feedError = null;
    notifyListeners();
    try {
      final batch = await feed.nextBatch(batchSize: batchSize);
      feedPosts.addAll(batch);
    } catch (e) {
      feedError = e;
    } finally {
      feedLoading = false;
      notifyListeners();
    }
  }

  void refreshFeed() {
    feedPosts.clear();
    _feed = FeedService(
      client: client,
      engine: engine,
      extraTagFilter: ratingFilter,
    );
    feedError = null;
    notifyListeners();
    loadMoreFeed();
  }

  void recordSignal(Post post, Signal signal, {double ratio = 1}) {
    engine.record(post, signal, ratio: ratio);
    _saveProfile();
  }

  void recordWatch(
      Post post, double watchSeconds, double? duration, bool completed) {
    history = [
      HistoryEntry(
        postId: post.id,
        host: post.host,
        watchedAt: now(),
        watchSeconds: watchSeconds,
        durationSeconds: duration ?? post.duration,
        completed: completed,
        postSummary: post.toSummary(),
      ),
      ...history,
    ];
    if (history.length > _historyLimit) {
      history = history.sublist(0, _historyLimit);
    }
    if (completed) {
      engine.record(post, Signal.completed);
    } else if (watchSeconds < 1.5) {
      engine.record(post, Signal.quickSkip);
    } else {
      engine.record(post, Signal.watchProgress,
          ratio: duration != null && duration > 0
              ? watchSeconds / duration
              : watchSeconds / 20);
    }
    _saveProfile();
    notifyListeners();
  }

  bool isLiked(Post post) =>
      likedPostIds.contains(post.id) || post.isFavorited;

  Future<void> toggleLike(Post post) async {
    final liked = isLiked(post);
    if (liked) {
      likedPostIds.remove(post.id);
    } else {
      likedPostIds.add(post.id);
    }
    engine.record(post, liked ? Signal.unliked : Signal.liked);
    prefs.setStringList(
      '$_profileKey.liked',
      likedPostIds.map((e) => '$e').toList(),
    );
    _saveProfile();
    notifyListeners();
    if (activeAccount.canFavorite) {
      try {
        if (liked) {
          await client.unfavorite(post.id);
        } else {
          await client.favorite(post.id);
        }
      } on BooruException {
        // keep the local weight change; the remote call is best-effort
      }
    }
  }

  Future<String?> takePhoto() async {
    final picker = imagePicker;
    if (picker == null) return null;
    final file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
    );
    if (file == null) return null;
    return savePhoto(File(file.path));
  }

  Future<void> markDone(Post post, {bool skipPhoto = false}) async {
    String? photoPath;
    if (!skipPhoto) {
      photoPath = await takePhoto();
    }
    dones = [
      DoneEntry(
        postId: post.id,
        host: post.host,
        doneAt: now(),
        photoPath: photoPath,
        postSummary: post.toSummary(),
      ),
      ...dones,
    ];
    engine.record(post, Signal.done);
    _saveProfile();
    notifyListeners();
  }

  bool isDone(int postId) => dones.any((d) => d.postId == postId);

  int get doneCount => dones.length;
  int get watchedCount => history.length;

  Future<String?> savePhoto(File source) async {
    if (docsDir.isEmpty) return null;
    final dir = Directory('$docsDir/done_photos');
    await dir.create(recursive: true);
    final dest =
        '${dir.path}/done_${now().millisecondsSinceEpoch}${source.path.substring(source.path.lastIndexOf('.'))}';
    await source.copy(dest);
    return dest;
  }

  void clearHistory() {
    history = [];
    dones = [];
    _saveProfile();
    notifyListeners();
  }

  void resetAlgorithm() {
    engine.reset();
    _feed?.reset();
    feedPosts.clear();
    _saveProfile();
    refreshFeed();
  }

  Future<void> checkForUpdates() async {
    if (updateChecking) return;
    updateChecking = true;
    notifyListeners();
    lastUpdateCheck = await checkerFactory(appVersion).check();
    updateChecking = false;
    notifyListeners();
  }

  AppUpdate? get pendingUpdate => lastUpdateCheck.update;
}
