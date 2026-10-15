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
  final Set<int> _returnedIds = {};
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
    while (candidates.length < batchSize && fetches < 8) {
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
      } on BooruException {
        continue;
      }
      _lanePages[laneIdx] = page + 1;
      if (posts.isEmpty) continue;
      candidates.addAll(posts.where(
        (p) => p.isVideo && !_returnedIds.contains(p.id),
      ));
    }
    if (candidates.isEmpty) {
      _exhausted = true;
      return const [];
    }
    final ranked = engine.rank(candidates, limit: batchSize);
    _returnedIds.addAll(ranked.map((p) => p.id));
    return ranked;
  }

  void reset() {
    _returnedIds.clear();
    _queries = [];
    _lanePages = [];
    _laneCursor = 0;
    _exhausted = false;
  }
}
