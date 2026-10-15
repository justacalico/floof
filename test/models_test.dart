import 'dart:math';

import 'package:floof/models/account.dart';
import 'package:floof/models/app_update.dart';
import 'package:floof/models/history_entry.dart';
import 'package:floof/models/post.dart';
import 'package:floof/models/profile.dart';
import 'package:floof/services/booru_client.dart';
import 'package:floof/services/feed_service.dart';
import 'package:floof/services/taste_engine.dart';
import 'package:floof/utils/version_utils.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  group('Post.fromJson (v2)', () {
    test('parses extended format', () {
      final post = makePost(id: 42);
      expect(post.id, 42);
      expect(post.fileExt, 'webm');
      expect(post.duration, 12.5);
      expect(post.width, 800);
      expect(post.height, 600);
      expect(post.isVideo, isTrue);
      expect(post.playableUrl, contains('_alt.mp4'));
      expect(post.thumbUrl, contains('preview'));
      expect(post.largeThumbUrl, contains('sample'));
      expect(post.scoreTotal, 18);
      expect(post.favCount, 10);
      expect(post.commentCount, 3);
      expect(post.aspectRatio, closeTo(800 / 600, 0.001));
      expect(post.tags.artist, ['someartist']);
      expect(post.sources, isNotEmpty);
      expect(post.host, 'https://e926.net');
    });

    test('parses minimal json', () {
      final post = Post.fromJson({'id': 7});
      expect(post.id, 7);
      expect(post.fileUrl, '');
      expect(post.isVideo, isFalse);
      expect(post.playableUrl, '');
      expect(post.thumbUrl, '');
      expect(post.aspectRatio, closeTo(16 / 9, 0.001));
    });

    test('summary round-trips key fields', () {
      final post = makePost(id: 9);
      final s = post.toSummary();
      expect(s['id'], 9);
      expect(s['artist'], 'someartist');
    });

    test('featureSet prefixes groups', () {
      final post = makePost();
      expect(post.tags.featureSet, contains('a:someartist'));
      expect(post.tags.featureSet, contains('s:wolf'));
      expect(post.tags.featureSet, contains('g:canine'));
      expect(post.tags.featureSet, contains('m:animated'));
    });
  });

  group('Account', () {
    test('guest defaults to e926', () {
      final g = Account.guest();
      expect(g.guest, isTrue);
      expect(g.canFavorite, isFalse);
      expect(g.displayName, contains('e926'));
      expect(g.hostLabel, 'e926');
    });

    test('guest on other hosts', () {
      final g = Account.guest('https://e621.net');
      expect(g.hostLabel, 'e621');
      expect(Account.guest('https://odd.example').hostLabel,
          'https://odd.example');
    });

    test('json roundtrip', () {
      const a = Account(
          id: 'x', username: 'u', apiKey: 'k', hostBaseUrl: 'https://e621.net', guest: false);
      final b = Account.fromJson(a.toJson());
      expect(b.id, 'x');
      expect(b.username, 'u');
      expect(b.displayName, 'u');
      expect(b.canFavorite, isTrue);
    });

    test('BooruHost.find', () {
      expect(BooruHost.find('https://e926.net'), BooruHost.e926);
      expect(BooruHost.find('nope'), isNull);
    });
  });

  group('HistoryEntry / DoneEntry', () {
    test('json roundtrip', () {
      final h = HistoryEntry(
        postId: 5,
        host: 'h',
        watchedAt: DateTime(2026, 1, 1),
        watchSeconds: 8,
        durationSeconds: 10,
        completed: true,
        postSummary: const {'artist': 'a'},
      );
      final b = HistoryEntry.fromJson(h.toJson());
      expect(b.postId, 5);
      expect(b.completed, isTrue);
      expect(b.watchRatio, closeTo(0.8, 0.001));
      expect(HistoryEntry.fromJson(b.toJson()).watchRatio, closeTo(0.8, 0.001));
      final noDur = HistoryEntry(postId: 1, host: '', watchedAt: DateTime.now());
      expect(noDur.watchRatio, 0);

      final d = DoneEntry(
        postId: 3,
        host: 'h',
        doneAt: DateTime(2026, 2, 2),
        photoPath: '/tmp/x.jpg',
      );
      final d2 = DoneEntry.fromJson(d.toJson());
      expect(d2.postId, 3);
      expect(d2.photoPath, '/tmp/x.jpg');
    });
  });

  group('Profile', () {
    test('json roundtrip', () {
      final p = Profile(id: 'p1', name: 'n', createdAt: DateTime(2026));
      final b = Profile.fromJson(p.toJson());
      expect(b.id, 'p1');
      expect(b.name, 'n');
    });
  });

  group('Version', () {
    test('parses and compares', () {
      expect(Version.tryParse('v1.2.3')!.toString(), '1.2.3');
      expect(Version.tryParse('1.2.3-4'), isNull);
      expect(Version.tryParse('1.2.3-rc.1')!.prerelease, 'rc.1');
      expect(Version.tryParse('junk'), isNull);
      expect(const Version(1, 0, 0).compareTo(const Version(1, 0, 1)) < 0, isTrue);
      expect(const Version(2, 0, 0).compareTo(const Version(1, 9, 9)) > 0, isTrue);
      expect(const Version(1, 0, 0).compareTo(const Version(1, 0, 0)), 0);
      expect(const Version(1, 0, 0).compareTo(const Version(1, 0, 0, 'a')) > 0, isTrue);
      expect(const Version(1, 0, 0, 'b').compareTo(const Version(1, 0, 0, 'a')) > 0, isTrue);
      expect(const Version(1, 0, 0, 'a').isStable, isFalse);
      expect(const Version(1, 2, 0).compareTo(const Version(1, 1, 9)) > 0, isTrue);
      expect(Version.tryParse('  v2.0.0 ')!.major, 2);
    });
  });

  group('TasteEngine', () {
    test('liking raises tag weights, skipping lowers others', () {
      final engine = TasteEngine(random: Random(1));
      final liked = makePost(id: 1, general: const ['fox']);
      final skipped = makePost(id: 2, general: const ['bird']);
      engine.record(liked, Signal.liked);
      engine.record(skipped, Signal.quickSkip);
      expect(engine.weights['g:fox']! > 0, isTrue);
      expect(engine.weights['g:bird']! < 0, isTrue);
      expect(engine.weights['a:someartist']! > 0, isTrue);
      expect(engine.seenPostIds, containsAll([1, 2]));
      expect(engine.impressions, 0);
    });

    test('signal values shift ranking', () {
      final engine = TasteEngine(random: Random(2));
      final a = makePost(id: 1, general: const ['fox']);
      for (var i = 0; i < 3; i++) {
        engine.record(a, Signal.done);
      }
      final ranked = engine.rank([
        makePost(id: 10, general: const ['fox'], artist: const ['someartist'], species: const ['wolf']),
        makePost(id: 11, general: const ['rock'], artist: const ['other'], species: const ['rock']),
      ]);
      expect(ranked.first.tags.general, contains('fox'));
    });

    test('seen posts get novelty penalty', () {
      final engine = TasteEngine();
      final p = makePost(id: 5);
      expect(engine.noveltyBonus(p), greaterThanOrEqualTo(0));
      engine.record(p, Signal.impression, ratio: 2);
      expect(engine.noveltyBonus(p), -2.0);
      expect(engine.impressions, 1);
    });

    test('decay shrinks weights over time', () {
      final engine = TasteEngine(random: Random(3));
      engine.record(makePost(id: 1), Signal.done);
      final before = engine.weights['g:canine']!;
      engine.applyDecay(DateTime.now().add(const Duration(days: 30)));
      expect(engine.weights['g:canine']! < before, isTrue);
      engine.applyDecay(DateTime.now().subtract(const Duration(days: 1)));
      expect(engine.lastDecay.isAfter(DateTime(2020)), isTrue);
      engine.weights['g:tiny'] = 0.0005;
      engine.applyDecay(DateTime.now().add(const Duration(days: 1)));
      expect(engine.weights.containsKey('g:tiny'), isFalse);
    });

    test('seen list trims at cap', () {
      final engine = TasteEngine(
        seenPostIds: List.generate(4000, (i) => i).toSet(),
      );
      engine.record(makePost(id: 9999), Signal.impression);
      expect(engine.seenPostIds.length, 4000);
      expect(engine.seenPostIds.contains(9999), isTrue);
    });

    test('json roundtrip', () {
      final engine = TasteEngine(random: Random(4));
      engine.record(makePost(id: 1), Signal.completed);
      engine.record(makePost(id: 2), Signal.watchProgress, ratio: 0.5);
      final copy = TasteEngine.fromJson(engine.toJson());
      expect(copy.weights, engine.weights);
      expect(copy.seenPostIds, engine.seenPostIds);
      expect(copy.impressions, engine.impressions);
      copy.reset();
      expect(copy.weights, isEmpty);
      expect(copy.seenPostIds, isEmpty);
    });

    test('topFeatures splits by sign', () {
      final engine = TasteEngine();
      engine.record(makePost(id: 1, general: const ['fox']), Signal.done);
      engine.record(makePost(id: 2, general: const ['rock'], artist: const ['x'], species: const ['y']), Signal.quickSkip);
      expect(engine.topFeatures(), isNotEmpty);
      expect(engine.topFeatures(positive: false), isNotEmpty);
    });

    test('rank diversifies similar posts', () {
      final engine = TasteEngine(random: Random(5));
      final posts = [
        for (var i = 0; i < 6; i++)
          makePost(id: i, general: const ['same'], favs: 100 - i),
        makePost(id: 99, general: const ['different'], artist: const ['other'], species: const ['otter'], favs: 95),
      ];
      final ranked = engine.rank(posts, limit: 4);
      expect(ranked.length, 4);
      expect(ranked.map((p) => p.id), contains(99));
    });

    test('quality prior favours high score posts', () {
      final engine = TasteEngine();
      expect(
        engine.qualityPrior(makePost(id: 1, favs: 300, scoreUp: 300)),
        greaterThan(engine.qualityPrior(makePost(id: 2, favs: 0, scoreUp: 0))),
      );
      expect(engine.rawAffinity(makePost(id: 3, general: const [])), isNotNull);
    });
  });

  group('FeedService', () {
    test('nextBatch fetches lanes round robin and dedupes', () async {
      final client = FakeBooruClient(posts: [
        makePost(id: 1),
        makePost(id: 2),
        Post.fromJson({'id': 3, 'files': {'meta': {'ext': 'png'}}, 'tags': {}}, host: 'x'),
      ]);
      final engine = TasteEngine();
      final feed = FeedService(client: client, engine: engine);
      final batch = await feed.nextBatch(batchSize: 4);
      expect(batch.map((p) => p.id).toSet(), {1, 2});
      final more = await feed.nextBatch(batchSize: 4);
      expect(more, isNotEmpty);
      feed.reset();
      final again = await feed.nextBatch(batchSize: 4);
      expect(again.map((p) => p.id).toSet(), {1, 2});
    });

    test('exhausts when nothing left', () async {
      final client = FakeBooruClient(posts: const []);
      final feed = FeedService(client: client, engine: TasteEngine());
      expect(await feed.nextBatch(batchSize: 4), isEmpty);
      expect(await feed.nextBatch(batchSize: 4), isEmpty);
    });

    test('skips failing lanes', () async {
      final client = FakeBooruClient(posts: [makePost(id: 9)])
        ..throwOnSearch = false;
      final feed = FeedService(client: client, engine: TasteEngine());
      final batch = await feed.nextBatch(batchSize: 2);
      expect(batch, isNotEmpty);
      client.throwOnSearch = true;
      final empty = await feed.nextBatch(batchSize: 2);
      expect(empty, isEmpty);
    });

    test('lanes include learned tags', () {
      final engine = TasteEngine();
      engine.record(makePost(id: 1, general: const ['fox']), Signal.done);
      final feed = FeedService(client: FakeBooruClient(), engine: engine);
      expect(feed.lanes.any((l) => l.contains('fox')), isTrue);
    });

    test('extra tag filter is appended', () async {
      final client = FakeBooruClient(posts: [makePost(id: 4)]);
      final feed = FeedService(
        client: client,
        engine: TasteEngine(),
        extraTagFilter: 'rating:s',
      );
      await feed.nextBatch(batchSize: 1);
      expect(client.lastSearchTags, contains('rating:s'));
    });
  });

  group('AppUpdate', () {
    test('holds fields', () {
      const u = AppUpdate(
          version: Version(1, 0, 0), tag: 'v1.0.0', releaseUrl: 'u');
      expect(u.tag, 'v1.0.0');
    });
  });
}
