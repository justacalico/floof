import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';
import '../models/app_update.dart';
import '../models/history_entry.dart';
import '../models/post.dart';
import '../models/profile.dart';
import '../platform/io_ops.dart' as io;
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
  Set<String> likedPostIds = {};
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
    try {
      final accJson = prefs.getString('accounts');
      if (accJson != null) {
        accounts = (jsonDecode(accJson) as List)
            .whereType<Map<String, dynamic>>()
            .map(Account.fromJson)
            .toList();
      }
    } catch (_) {
      accounts = [];
    }
    if (accounts.isEmpty) accounts = [Account.guest()];
    activeAccountId = prefs.getString('activeAccountId') ?? accounts.first.id;
    if (accounts.every((a) => a.id != activeAccountId)) {
      activeAccountId = accounts.first.id;
    }

    try {
      final profJson = prefs.getString('profiles');
      if (profJson != null) {
        profiles = (jsonDecode(profJson) as List)
            .whereType<Map<String, dynamic>>()
            .map(Profile.fromJson)
            .toList();
      }
    } catch (_) {
      profiles = [];
    }
    if (profiles.isEmpty) {
      profiles = [
        Profile(id: 'default', name: 'Default', createdAt: now()),
      ];
    }
    activeProfileId = prefs.getString('activeProfileId') ?? profiles.first.id;
    if (profiles.every((p) => p.id != activeProfileId)) {
      activeProfileId = profiles.first.id;
    }

    theme = AppTheme.values[
        (prefs.getInt('theme') ?? 0).clamp(0, AppTheme.values.length - 1)];
    localeTag = prefs.getString('locale') ?? '';
    contentRating = ContentRating.values[
        (prefs.getInt('contentRating') ?? 0)
            .clamp(0, ContentRating.values.length - 1)];

    _loadProfile();
    notifyListeners();
  }

  void _loadProfile() {
    try {
      final tasteJson = prefs.getString('$_profileKey.taste');
      engine = tasteJson != null
          ? TasteEngine.fromJson(
              jsonDecode(tasteJson) as Map<String, dynamic>)
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
    } catch (_) {
      engine = TasteEngine();
      history = [];
      dones = [];
    }
    likedPostIds =
        (prefs.getStringList('$_profileKey.liked') ?? []).toSet();
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
    bool ok;
    try {
      ok = await probe.verifyLogin();
    } finally {
      probe.dispose();
    }
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
    refreshFeed();
  }

  void removeProfile(String id) {
    if (profiles.length <= 1) return;
    profiles = profiles.where((p) => p.id != id).toList();
    prefs.remove('profile.$id.taste');
    prefs.remove('profile.$id.history');
    prefs.remove('profile.$id.done');
    prefs.remove('profile.$id.liked');
    if (activeProfileId == id) {
      activeProfileId = profiles.first.id;
      prefs.setString('activeProfileId', activeProfileId);
      _loadProfile();
      refreshFeed();
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

  int _feedGen = 0;

  Future<void> loadMoreFeed({int batchSize = 20}) async {
    if (feedLoading) return;
    final gen = _feedGen;
    feedLoading = true;
    feedError = null;
    notifyListeners();
    try {
      final batch = await feed.nextBatch(batchSize: batchSize);
      if (gen == _feedGen) feedPosts.addAll(batch);
    } catch (e) {
      if (gen == _feedGen) feedError = e;
    } finally {
      if (gen == _feedGen) feedLoading = false;
      notifyListeners();
    }
  }

  void refreshFeed() {
    _feedGen++;
    feedPosts.clear();
    feedLoading = false;
    _feed = FeedService(
      client: client,
      engine: engine,
      extraTagFilter: ratingFilter,
    );
    feedError = null;
    notifyListeners();
    loadMoreFeed();
  }

  void _recordWatchForProfile(String profileId, Post post,
      double watchSeconds, double? duration, bool completed) {
    final key = 'profile.$profileId';
    try {
      final e = _profileEngine(key);
      final hist = _profileHistory(key);
      hist.insert(
          0,
          HistoryEntry(
            postId: post.id,
            host: post.host,
            watchedAt: now(),
            watchSeconds: watchSeconds,
            durationSeconds: duration ?? post.duration,
            completed: completed,
            postSummary: post.toSummary(),
          ));
      if (hist.length > _historyLimit) {
        hist.removeRange(_historyLimit, hist.length);
      }
      _applyWatchSignal(e, post, watchSeconds, duration, completed);
      prefs.setString('$key.taste', jsonEncode(e.toJson()));
      prefs.setString('$key.history',
          jsonEncode(hist.map((h) => h.toJson()).toList()));
    } catch (_) {}
  }

  TasteEngine _profileEngine(String key) {
    final tasteJson = prefs.getString('$key.taste');
    return tasteJson != null
        ? TasteEngine.fromJson(
            jsonDecode(tasteJson) as Map<String, dynamic>)
        : TasteEngine();
  }

  List<HistoryEntry> _profileHistory(String key) {
    final histJson = prefs.getString('$key.history');
    return histJson != null
        ? (jsonDecode(histJson) as List)
            .whereType<Map<String, dynamic>>()
            .map(HistoryEntry.fromJson)
            .toList()
        : [];
  }

  void _applyWatchSignal(TasteEngine e, Post post, double watchSeconds,
      double? duration, bool completed) {
    if (completed) {
      e.record(post, Signal.completed);
    } else if (watchSeconds < 1.5) {
      e.record(post, Signal.quickSkip);
    } else {
      e.record(post, Signal.watchProgress,
          ratio: duration != null && duration > 0
              ? watchSeconds / duration
              : watchSeconds / 20);
    }
  }

  void recordSignal(Post post, Signal signal, {double ratio = 1}) {
    engine.record(post, signal, ratio: ratio);
    _saveProfile();
  }

  void recordWatch(
      Post post, double watchSeconds, double? duration, bool completed,
      {String? profileId}) {
    if (profileId != null && profileId != activeProfileId) {
      _recordWatchForProfile(
          profileId, post, watchSeconds, duration, completed);
      return;
    }
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
    _applyWatchSignal(engine, post, watchSeconds, duration, completed);
    _saveProfile();
    notifyListeners();
  }

  bool isLiked(Post post) =>
      likedPostIds.contains(post.key) || post.isFavorited;

  Future<void> toggleLike(Post post) async {
    final liked = isLiked(post);
    if (liked) {
      likedPostIds.remove(post.key);
    } else {
      likedPostIds.add(post.key);
    }
    engine.record(post, liked ? Signal.unliked : Signal.liked);
    prefs.setStringList('$_profileKey.liked', likedPostIds.toList());
    _saveProfile();
    notifyListeners();
    if (activeAccount.canFavorite) {
      try {
        if (liked) {
          await client.unfavorite(post.id);
        } else {
          await client.favorite(post.id);
        }
      } catch (_) {
        if (liked) {
          likedPostIds.add(post.key);
        } else {
          likedPostIds.remove(post.key);
        }
        engine.record(post, liked ? Signal.liked : Signal.unliked);
        prefs.setStringList('$_profileKey.liked', likedPostIds.toList());
        _saveProfile();
        notifyListeners();
      }
    }
  }

  Future<String?> takePhoto() async {
    final picker = imagePicker;
    if (picker == null) return null;
    XFile? file;
    try {
      file = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
      );
    } catch (_) {
      return null;
    }
    if (file == null) return null;
    return savePhoto(file.path);
  }

  Future<void> markDone(Post post, {bool skipPhoto = false}) async {
    if (isDone(post)) return;
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

  bool isDone(Post post) =>
      dones.any((d) => d.postId == post.id && d.host == post.host);

  int get doneCount => dones.length;
  int get watchedCount => history.length;

  Future<String?> savePhoto(String sourcePath) async {
    if (docsDir.isEmpty) return null;
    return io.copyPhoto(sourcePath, '$docsDir/done_photos');
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
    final checker = checkerFactory(appVersion);
    try {
      lastUpdateCheck = await checker.check();
    } finally {
      checker.dispose();
      updateChecking = false;
    }
    notifyListeners();
  }

  AppUpdate? get pendingUpdate => lastUpdateCheck.update;
}
