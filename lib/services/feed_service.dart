import '../models/post.dart';
import 'booru_client.dart';
import 'taste_engine.dart';

class FeedService {
  final BooruClient client;
  final TasteEngine engine;
  final String extraTagFilter;

  static const _baseLanes = [
    'order:score type:webm',
    'order:fav_count type:webm',
    'order:random type:webm',
    'order:rank type:webm',
  ];

  List<String> _queries = [];
  List<int> _lanePages = [];
  final Set<String> _returnedKeys = {};
  final Set<int> _laneDone = {};
  int _laneCursor = 0;
  bool _exhausted = false;

  FeedService({
    required this.client,
    required this.engine,
    this.extraTagFilter = '',
  });

  List<String> get lanes {
    final personalised = engine
        .topFeatures(count: 3)
        .map((e) => e.key.substring(2))
        .where((t) => t.isNotEmpty)
        .map((t) => '$t type:webm order:score')
        .toList();
    return [...personalised, ..._baseLanes];
  }

  List<String> get queries {
    if (_queries.isEmpty) {
      _queries = lanes;
      _lanePages = List.filled(_queries.length, 1);
    }
    return _queries;
  }

  String _withFilter(String tags) =>
      extraTagFilter.isEmpty ? tags : '$tags $extraTagFilter';

  Future<List<Post>> nextBatch({int batchSize = 20}) async {
    if (_exhausted) return const [];
    final candidates = <Post>[];
    final allLanes = queries;
    var fetches = 0;
    final seenLanes = <int>{};
    BooruException? lastError;
    while (candidates.length < batchSize &&
        seenLanes.length < allLanes.length &&
        fetches < 8) {
      final laneIdx = _laneCursor % allLanes.length;
      _laneCursor++;
      if (seenLanes.contains(laneIdx)) continue;
      seenLanes.add(laneIdx);
      fetches++;

      final page = _lanePages[laneIdx];
      List<Post> posts;
      try {
        posts = await client.searchPosts(
          tags: _withFilter(allLanes[laneIdx]),
          page: page,
          limit: 40,
        );
      } on BooruException catch (e) {
        lastError = e;
        continue;
      }
      _lanePages[laneIdx] = page + 1;
      if (posts.isEmpty) {
        _laneDone.add(laneIdx);
        continue;
      }
      candidates.addAll(posts.where(
        (p) => p.isVideo && !_returnedKeys.contains(p.key),
      ));
    }
    if (candidates.isEmpty) {
      if (lastError != null && seenLanes.length >= allLanes.length) {
        throw lastError;
      }
      _exhausted = _laneDone.length >= allLanes.length;
      return const [];
    }
    final deduped = <Post>[];
    final batchKeys = <String>{};
    for (final p in candidates) {
      if (batchKeys.add(p.key)) deduped.add(p);
    }
    final ranked = engine.rank(deduped, limit: batchSize);
    _returnedKeys.addAll(ranked.map((p) => p.key));
    return ranked;
  }

  void reset() {
    _returnedKeys.clear();
    _laneDone.clear();
    _queries = [];
    _lanePages = [];
    _laneCursor = 0;
    _exhausted = false;
  }
}
