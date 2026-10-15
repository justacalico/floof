import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:floof/models/account.dart';
import 'package:floof/models/app_update.dart';
import 'package:floof/models/post.dart';
import 'package:floof/platform/window_ops.dart';
import 'package:floof/services/booru_client.dart';
import 'package:floof/services/version_checker.dart';
import 'package:floof/utils/version_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

Map<String, dynamic> postJson({
  int id = 1,
  String ext = 'webm',
  List<String> general = const ['canine'],
  List<String> artist = const ['someartist'],
  List<String> species = const ['wolf'],
  int favs = 10,
  int scoreUp = 20,
  String rating = 's',
  bool deleted = false,
}) {
  return {
    'id': id,
    'created_at': '2026-10-01T10:00:00.000-04:00',
    'updated_at': '2026-10-01T10:00:00.000-04:00',
    'change_seq': 1,
    'files': {
      'meta': {
        'md5': 'a' * 32,
        'ext': ext,
        'size': 1000,
        'duration': 12.5,
        'has_sample': true,
      },
      'original': {
        'width': 800,
        'height': 600,
        'url': 'https://static1.e926.net/data/aa/aa/$id.$ext',
      },
      'preview': {
        'width': 100,
        'height': 75,
        'jpg': 'https://static1.e926.net/data/preview/$id.jpg',
        'webp': 'https://static1.e926.net/data/preview/$id.webp',
      },
      'sample': {
        'width': 400,
        'height': 300,
        'jpg': 'https://static1.e926.net/data/sample/$id.jpg',
        'webp': 'https://static1.e926.net/data/sample/$id.webp',
      },
      'video': {
        'has': true,
        'original': {
          'fps': 24.0,
          'codec': 'vp9',
          'size': 1000,
          'width': 800,
          'height': 600,
          'url': 'https://static1.e926.net/data/aa/aa/$id.$ext',
        },
        'variants': {
          'mp4': {
            'codec': 'avc1',
            'fps': 24.0,
            'size': 900,
            'width': 800,
            'height': 600,
            'url': 'https://static1.e926.net/data/aa/aa/${id}_alt.mp4',
          },
        },
        'samples': {},
      },
    },
    'uploader_id': 1,
    'uploader_name': 'uploader',
    'approver_id': null,
    'stats': {
      'score': {'up': scoreUp, 'down': -2, 'total': scoreUp - 2},
      'fav_count': favs,
      'is_favorited': false,
      'vote': 0,
      'comment_count': 3,
      'hotness': 1.5,
    },
    'flags': {
      'pending': false,
      'flagged': false,
      'note_locked': false,
      'status_locked': false,
      'rating_locked': false,
      'deleted': deleted,
    },
    'has': {'parent': false, 'children': false, 'active_children': false, 'notes': false, 'sample': true},
    'relationships': {'parent_id': null, 'children': []},
    'pools': [],
    'rating': rating,
    'locked_tags': [],
    'sources': ['https://example.com/src/$id'],
    'description': 'post $id',
    'tags': {
      'general': general,
      'artist': artist,
      'contributor': [],
      'copyright': [],
      'character': [],
      'species': species,
      'invalid': [],
      'meta': ['animated'],
      'lore': [],
    },
  };
}

Post makePost({
  int id = 1,
  List<String> general = const ['canine'],
  List<String> artist = const ['someartist'],
  List<String> species = const ['wolf'],
  int favs = 10,
  int scoreUp = 20,
  double? duration,
  String host = 'https://e926.net',
}) {
  final json = postJson(
    id: id,
    general: general,
    artist: artist,
    species: species,
    favs: favs,
    scoreUp: scoreUp,
  );
  if (duration != null) {
    (json['files'] as Map)['meta'] = {
      'ext': 'webm',
      'size': 1000,
      'duration': duration,
      'has_sample': true,
    };
  }
  return Post.fromJson(json, host: host);
}

class FakeBooruClient extends BooruClient {
  FakeBooruClient({List<Post>? posts, this.suggestions = const []})
      : posts = posts ?? [makePost(id: 1)];

  List<Post> posts;
  List<Post>? laterPosts;
  final List<TagSuggestion> suggestions;
  bool verifyResult = true;
  bool throwOnVerify = false;
  bool throwOnSearch = false;
  bool throwOnFav = false;
  int favCalls = 0;
  int unfavCalls = 0;
  String? lastSearchTags;
  int lastPage = -1;
  bool disposed = false;

  @override
  Future<List<Post>> searchPosts({String tags = '', int page = 1, int limit = 40}) async {
    if (throwOnSearch) throw const BooruException('search failed', 500);
    lastSearchTags = tags;
    lastPage = page;
    if (page > 1) return laterPosts ?? const [];
    return posts;
  }

  bool throwOnAutocomplete = false;

  @override
  Future<List<TagSuggestion>> autocomplete(String term,
      {int limit = 8}) async {
    if (throwOnAutocomplete) throw const BooruException('tags failed', 500);
    return suggestions;
  }

  @override
  Future<bool> verifyLogin() async {
    if (throwOnVerify) throw const BooruException('login check failed', 500);
    return verifyResult;
  }

  @override
  Future<void> favorite(int postId) async {
    favCalls++;
    if (throwOnFav) throw const BooruException('favorite failed', 500);
  }

  @override
  Future<void> unfavorite(int postId) async {
    unfavCalls++;
    if (throwOnFav) throw const BooruException('unfavorite failed', 500);
  }

  @override
  void dispose() {
    disposed = true;
  }
}

class FakeVersionChecker extends VersionChecker {
  FakeVersionChecker(this.result) : super(currentVersion: '0.1.0');
  final UpdateCheckResult result;
  int calls = 0;

  @override
  Future<UpdateCheckResult> check() async {
    calls++;
    return result;
  }
}

UpdateCheckResult availableResult() => UpdateCheckResult(AppUpdate(
      version: const Version(9, 9, 9),
      tag: 'v9.9.9',
      releaseUrl: 'https://gitlab.com/HttpAnimations/floof/-/releases/v9.9.9',
    ));

class FakeWindowOps implements WindowOps {
  int inits = 0;
  int closes = 0;
  int minimizes = 0;
  int maxCalls = 0;
  int titles = 0;
  bool maximized = false;

  @override
  Future<void> init() async => inits++;
  @override
  Future<void> close() async => closes++;
  @override
  Future<void> minimize() async => minimizes++;
  @override
  Future<void> maximizeOrRestore() async => maxCalls++;
  @override
  Future<bool> isMaximized() async => maximized;
  @override
  Future<void> setTitle(String title) async => titles++;
}

class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  int _next = 0;
  bool throwOnCreate = false;
  Size initSize = const Size(800, 450);
  Completer<void>? createGate;
  final Map<int, StreamController<VideoEvent>> streams = {};
  int playCalls = 0;
  int pauseCalls = 0;
  int creates = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    if (throwOnCreate) throw StateError('create failed');
    creates++;
    if (createGate != null) await createGate!.future;
    final id = _next++;
    streams[id] = StreamController<VideoEvent>();
    streams[id]!.add(VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 12),
      size: initSize,
    ));
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => streams[playerId]!.stream;

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {
    playCalls++;
    streams[playerId]?.add(VideoEvent(
      eventType: VideoEventType.isPlayingStateUpdate,
      isPlaying: true,
    ));
  }

  @override
  Future<void> pause(int playerId) async {
    pauseCalls++;
    streams[playerId]?.add(VideoEvent(
      eventType: VideoEventType.isPlayingStateUpdate,
      isPlaying: false,
    ));
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      SizedBox(key: ValueKey('video-${options.playerId}'));

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
}

class FakeImagePickerPlatform extends ImagePickerPlatform {
  XFile? nextFile;
  int calls = 0;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    calls++;
    return nextFile;
  }
}

class FakePathProviderPlatform extends PathProviderPlatform {
  String docsPath;
  Object? error;
  FakePathProviderPlatform(this.docsPath);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    final e = error;
    if (e != null) throw e;
    return docsPath;
  }
}

class FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  final List<String> launched = [];

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }

  @override
  LinkDelegate? get linkDelegate => null;
}

const transparentPng = [
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1,
  0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 10, 73, 68, 65, 84,
  120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78,
  68, 174, 66, 96, 130,
];

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest(this._response);
  final HttpClientResponse _response;

  @override
  Future<HttpClientResponse> close() async => _response;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse implements HttpClientResponse {
  _FakeHttpClientResponse(this.bytes);
  final List<int> bytes;

  @override
  int get contentLength => bytes.length;

  @override
  int get statusCode => 200;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([bytes]).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpClient implements HttpClient {
  FakeHttpClient([this.bytes = transparentPng]);
  final List<int> bytes;

  @override
  bool autoUncompress = true;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _FakeHttpClientRequest(_FakeHttpClientResponse(bytes));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpOverrides extends HttpOverrides {
  FakeHttpOverrides([this.bytes = transparentPng]);
  final List<int> bytes;

  @override
  HttpClient createHttpClient(SecurityContext? context) => FakeHttpClient(bytes);
}

class FakeAccount extends Account {
  const FakeAccount({super.id = 'fake', super.username = 'u', super.apiKey = 'k', super.guest = false});
}

Map<String, dynamic> releaseJson(String tag) => {
      'tag_name': tag,
      'name': 'release $tag',
      'released_at': '2026-10-01T00:00:00Z',
      'assets': {'links': []},
    };

String releasesBody(List<String> tags) => jsonEncode([for (final t in tags) releaseJson(t)]);
