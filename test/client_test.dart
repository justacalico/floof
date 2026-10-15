import 'dart:convert';

import 'package:floof/services/booru_client.dart';
import 'package:floof/services/version_checker.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  group('BooruClient', () {
    test('searchPosts uses v2 extended format', () async {
      Uri? seen;
      final client = BooruClient(
        client: MockClient((req) async {
          seen = req.url;
          return http.Response(jsonEncode([postJson(id: 1)]), 200);
        }),
      );
      final posts = await client.searchPosts(tags: 'fox', page: 2, limit: 10);
      expect(posts, hasLength(1));
      expect(seen!.path, '/posts.json');
      expect(seen!.queryParameters['v2'], 'true');
      expect(seen!.queryParameters['mode'], 'extended');
      expect(seen!.queryParameters['tags'], 'fox');
      expect(seen!.queryParameters['page'], '2');
      client.dispose();
    });

    test('handles wrapped posts map and bad status', () async {
      final wrapped = BooruClient(
        client: MockClient((req) async =>
            http.Response(jsonEncode({'posts': [postJson(id: 2)]}), 200)),
      );
      expect(await wrapped.searchPosts(), hasLength(1));

      final bad = BooruClient(
        client: MockClient((req) async => http.Response('err', 500)),
      );
      expect(() => bad.searchPosts(), throwsA(isA<BooruException>()));

      final empty = BooruClient(
        client: MockClient((req) async => http.Response('{}', 200)),
      );
      expect(await empty.searchPosts(), isEmpty);
    });

    test('sends basic auth when credentials set', () async {
      String? auth;
      final client = BooruClient(
        username: 'user',
        apiKey: 'secret',
        client: MockClient((req) async {
          auth = req.headers['Authorization'];
          return http.Response('[]', 200);
        }),
      );
      await client.searchPosts();
      expect(auth, startsWith('Basic '));
      expect(auth, contains(base64Encode(utf8.encode('user:secret'))));
    });

    test('getPost returns post, null on 404, throws otherwise', () async {
      final ok = BooruClient(
        client: MockClient((req) async =>
            http.Response(jsonEncode({'post': postJson(id: 8)}), 200)),
      );
      expect((await ok.getPost(8))!.id, 8);

      final missing = BooruClient(
        client: MockClient((req) async => http.Response('nope', 404)),
      );
      expect(await missing.getPost(99), isNull);

      final bare = BooruClient(
        client: MockClient((req) async =>
            http.Response(jsonEncode(postJson(id: 9)), 200)),
      );
      expect((await bare.getPost(9))!.id, 9);

      final weird = BooruClient(
        client: MockClient((req) async => http.Response('[]', 200)),
      );
      expect(await weird.getPost(1), isNull);

      final bad = BooruClient(
        client: MockClient((req) async => http.Response('x', 500)),
      );
      expect(() => bad.getPost(1), throwsA(isA<BooruException>()));
    });

    test('autocomplete parses names and handles failures', () async {
      final client = BooruClient(
        client: MockClient((req) async {
          expect(req.url.path, '/tags.json');
          return http.Response(
              jsonEncode([
                {'name': 'canine', 'post_count': 5000},
                {'name': 'fox'},
              ]),
              200);
        }),
      );
      final out = await client.autocomplete('can');
      expect(out, hasLength(2));
      expect(out.first.name, 'canine');
      expect(out.first.postCount, 5000);

      expect(await client.autocomplete('   '), isEmpty);

      final bad = BooruClient(
        client: MockClient((req) async => http.Response('x', 500)),
      );
      expect(await bad.autocomplete('can'), isEmpty);

      final notList = BooruClient(
        client: MockClient((req) async => http.Response('{}', 200)),
      );
      expect(await notList.autocomplete('can'), isEmpty);
    });

    test('verifyLogin', () async {
      final yes = BooruClient(
        client: MockClient((req) async => http.Response('[{"id":1}]', 200)),
      );
      expect(await yes.verifyLogin(), isTrue);

      final no = BooruClient(
        client: MockClient((req) async => http.Response('[]', 200)),
      );
      expect(await no.verifyLogin(), isFalse);

      final denied = BooruClient(
        client: MockClient((req) async => http.Response('', 401)),
      );
      expect(await denied.verifyLogin(), isFalse);

      final err = BooruClient(
        client: MockClient((req) async => http.Response('', 500)),
      );
      expect(() => err.verifyLogin(), throwsA(isA<BooruException>()));
    });

    test('favorite/unfavorite', () async {
      var calls = 0;
      final ok = BooruClient(
        client: MockClient((req) async {
          calls++;
          return http.Response('{}', req.method == 'POST' ? 201 : 204);
        }),
      );
      await ok.favorite(1);
      await ok.unfavorite(1);
      expect(calls, 2);

      final bad = BooruClient(
        client: MockClient((req) async => http.Response('', 500)),
      );
      expect(() => bad.favorite(1), throwsA(isA<BooruException>()));
      expect(() => bad.unfavorite(1), throwsA(isA<BooruException>()));
    });
  });

  group('VersionChecker', () {
    test('finds highest semver tag', () async {
      final checker = VersionChecker(
        currentVersion: '0.1.0',
        client: MockClient((req) async => http.Response(
            releasesBody(['v0.9.0', 'v0.10.0', 'junk-tag', 'v0.2.0']), 200)),
      );
      final latest = await checker.latestRelease();
      expect(latest!.tag, 'v0.10.0');
      expect(latest.releaseUrl, contains('/-/releases/v0.10.0'));

      final result = await checker.check();
      expect(result.status, UpdateCheckStatus.available);
      expect(result.update!.version.toString(), '0.10.0');
    });

    test('up to date when nothing newer', () async {
      final checker = VersionChecker(
        currentVersion: '99.0.0',
        client: MockClient((req) async =>
            http.Response(releasesBody(['v1.0.0', 'v0.9.0']), 200)),
      );
      expect(await checker.latestRelease(), isNotNull);
      final result = await checker.check();
      expect(result.status, UpdateCheckStatus.upToDate);
    });

    test('none when no releases parse', () async {
      final checker = VersionChecker(
        currentVersion: '0.1.0',
        client: MockClient((req) async => http.Response(
            releasesBody(['junk', 'also-junk']), 200)),
      );
      final result = await checker.check();
      expect(result.status, UpdateCheckStatus.none);
    });

    test('paginates when page is full', () async {
      var pages = 0;
      final tags = List.generate(100, (i) => 'v0.0.$i');
      final checker = VersionChecker(
        currentVersion: '0.1.0',
        client: MockClient((req) async {
          pages++;
          if (pages == 1) return http.Response(releasesBody(tags), 200);
          return http.Response(releasesBody(['v5.0.0']), 200);
        }),
      );
      final latest = await checker.latestRelease();
      expect(latest!.tag, 'v5.0.0');
      expect(pages, 2);
    });

    test('failure states', () async {
      final bad = VersionChecker(
        currentVersion: '0.1.0',
        client: MockClient((req) async => http.Response('oops', 502)),
      );
      expect((await bad.check()).status, UpdateCheckStatus.failed);

      final malformed = VersionChecker(
        currentVersion: '0.1.0',
        client: MockClient((req) async => http.Response('not json{', 200)),
      );
      expect((await malformed.check()).status, UpdateCheckStatus.failed);
    });
  });
}
