import 'dart:convert';
import 'dart:io';

import 'package:floof/models/account.dart';
import 'package:floof/services/booru_client.dart';
import 'package:floof/services/taste_engine.dart';
import 'package:floof/services/version_checker.dart';
import 'package:floof/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fakes = PlatformFakes()..install();

  group('AppState basics', () {
    test('loads with guest defaults', () async {
      final state = await makeState();
      expect(state.accounts, hasLength(1));
      expect(state.accounts.first.guest, isTrue);
      expect(state.activeAccount.guest, isTrue);
      expect(state.activeProfile.name, 'Default');
      expect(state.theme, AppTheme.system);
      expect(state.loaded, isTrue);
    });

    test('persists theme, locale, rating', () async {
      final state = await makeState();
      state.setTheme(AppTheme.oled);
      state.setLocale('ru');
      state.setContentRating(ContentRating.all);
      final p = state.prefs;
      expect(p.getInt('theme'), AppTheme.oled.index);
      expect(p.getString('locale'), 'ru');
      expect(p.getInt('contentRating'), ContentRating.all.index);
      await Future.delayed(Duration.zero);
    });

    test('restores persisted values', () async {
      final accounts = jsonEncode([
        Account.guest().toJson(),
        const Account(
          id: 'u@https://e621.net',
          username: 'u',
          apiKey: 'k',
          hostBaseUrl: 'https://e621.net',
          guest: false,
        ).toJson(),
      ]);
      final state = await makeState(prefs: {
        'accounts': accounts,
        'activeAccountId': 'u@https://e621.net',
        'theme': 2,
        'locale': 'ga',
        'contentRating': 1,
        'profiles': jsonEncode([
          {'id': 'p1', 'name': 'One', 'createdAt': '2026-01-01T00:00:00'},
        ]),
        'activeProfileId': 'p1',
        'profile.p1.taste': jsonEncode({'weights': {'g:fox': 2.0}}),
        'profile.p1.history': '[]',
        'profile.p1.done': '[]',
        'profile.p1.liked': ['5'],
      });
      expect(state.activeAccount.username, 'u');
      expect(state.theme, AppTheme.dark);
      expect(state.localeTag, 'ga');
      expect(state.contentRating, ContentRating.all);
      expect(state.engine.weights['g:fox'], 2.0);
      expect(state.likedPostIds, {5});
      expect(state.ratingFilter, '');
    });
  });

  group('accounts', () {
    test('addAccount verifies then activates', () async {
      final client = FakeBooruClient();
      final state = await makeState(client: client);
      await state.addAccount('user', 'key', 'https://e621.net');
      expect(state.accounts, hasLength(2));
      expect(state.activeAccount.username, 'user');
      expect(state.activeAccount.canFavorite, isTrue);
    });

    test('addAccount throws on bad login', () async {
      final client = FakeBooruClient()..verifyResult = false;
      final state = await makeState(client: client);
      expect(() => state.addAccount('u', 'k', 'https://e621.net'),
          throwsA(isA<BooruException>()));
      expect(state.accounts, hasLength(1));
    });

    test('guest account add and dedupe', () async {
      final state = await makeState();
      state.addGuestAccount('https://e621.net');
      state.addGuestAccount('https://e621.net');
      expect(state.accounts, hasLength(2));
      expect(state.activeAccount.hostBaseUrl, 'https://e621.net');
      expect(state.ratingFilter, 'rating:s');
      state.setContentRating(ContentRating.all);
      expect(state.ratingFilter, '');
      await Future.delayed(Duration.zero);
    });

    test('remove account keeps at least one', () async {
      final state = await makeState();
      state.removeAccount(state.accounts.first.id);
      expect(state.accounts, hasLength(1));
      state.addGuestAccount('https://e621.net');
      final activeId = state.activeAccountId;
      state.removeAccount(activeId);
      expect(state.activeAccount.hostBaseUrl, 'https://e926.net');
    });

    test('rating filter stays safe on e926 even when all set', () async {
      final state = await makeState();
      state.setContentRating(ContentRating.all);
      await Future.delayed(Duration.zero);
      expect(state.activeAccount.hostBaseUrl, 'https://e926.net');
      expect(state.ratingFilter, '');
    });
  });

  group('profiles', () {
    test('add, switch, rename, remove', () async {
      final state = await makeState();
      state.addProfile('Second');
      expect(state.profiles, hasLength(2));
      expect(state.activeProfile.name, 'Second');
      state.switchProfile(state.profiles.first.id);
      expect(state.activeProfile.name, 'Default');
      state.switchProfile(state.profiles.first.id);
      state.renameProfile(state.profiles.first.id, 'Renamed');
      expect(state.profiles.first.name, 'Renamed');
      state.removeProfile(state.profiles.first.id);
      expect(state.profiles, hasLength(1));
      expect(state.activeProfile.name, 'Second');
      state.removeProfile(state.profiles.first.id);
      expect(state.profiles, hasLength(1));
    });

    test('profiles keep separate taste state', () async {
      final state = await makeState();
      final post = makePost(id: 1, general: const ['fox']);
      state.recordSignal(post, Signal.liked);
      expect(state.engine.weights['g:fox']! > 0, isTrue);
      state.addProfile('Other');
      expect(state.engine.weights, isEmpty);
      state.switchProfile(state.profiles.first.id);
      expect(state.engine.weights['g:fox']! > 0, isTrue);
    });
  });

  group('feed', () {
    test('loadMoreFeed fills posts', () async {
      final client = FakeBooruClient(posts: [makePost(id: 1), makePost(id: 2)]);
      final state = await makeState(client: client);
      await state.loadMoreFeed(batchSize: 4);
      expect(state.feedPosts, isNotEmpty);
      final first = state.feedPosts.first;
      await state.loadMoreFeed(batchSize: 1);
      expect(state.feedPosts.length, greaterThanOrEqualTo(1));
      expect(first.id, state.feedPosts.first.id);
    });

    test('concurrent load is a no-op', () async {
      final state = await makeState();
      state.feedLoading = true;
      await state.loadMoreFeed();
      expect(state.feedError, isNull);
    });

    test('error path sets feedError', () async {
      final client = FakeBooruClient()..throwOnSearch = true;
      final state = await makeState(client: client);
      await state.loadMoreFeed(batchSize: 2);
      expect(state.feedPosts, isEmpty);
      await state.loadMoreFeed(batchSize: 2);
      expect(state.feedPosts, isEmpty);
    });

    test('refreshFeed rebuilds service', () async {
      final state = await makeState();
      state.refreshFeed();
      await Future.delayed(Duration.zero);
      expect(state.feedPosts, isNotEmpty);
      expect(state.ratingFilter, '');
    });
  });

  group('watch and done', () {
    test('recordWatch completed vs skip vs progress', () async {
      final state = await makeState();
      final post = makePost(id: 1);
      state.recordWatch(post, 11, 12, true);
      state.recordWatch(makePost(id: 2), 1, 30, false);
      state.recordWatch(makePost(id: 3), 5, 10, false);
      state.recordWatch(makePost(id: 4), 5, null, false);
      expect(state.history, hasLength(4));
      expect(state.history.first.postId, 4);
      expect(state.history[3].completed, isTrue);
    });

    test('history trims at cap', () async {
      final state = await makeState();
      for (var i = 0; i < 505; i++) {
        state.recordWatch(makePost(id: i), 5, 10, false);
      }
      expect(state.history.length, 500);
    });

    test('toggleLike updates local and remote', () async {
      final client = FakeBooruClient();
      final state = await makeState(client: client);
      final post = makePost(id: 7);
      await state.toggleLike(post);
      expect(state.isLiked(post), isTrue);
      expect(client.favCalls, 0);
      await state.toggleLike(post);
      expect(state.isLiked(post), isFalse);
    });

    test('toggleLike calls remote on signed-in account', () async {
      final client = FakeBooruClient();
      final state = await makeState(client: client);
      await state.addAccount('u', 'k', 'https://e926.net');
      final post = makePost(id: 8);
      await state.toggleLike(post);
      expect(client.favCalls, 1);
      await state.toggleLike(post);
      expect(client.unfavCalls, 1);
      client.throwOnFav = true;
      await state.toggleLike(post);
      expect(state.isLiked(post), isTrue);
    });

    test('markDone with and without photo', () async {
      final tmp = await Directory.systemTemp.createTemp('floof_done');
      addTearDown(() => tmp.delete(recursive: true));
      final shot = File('${tmp.path}/shot.jpg')
        ..writeAsBytesSync(transparentPng);
      final state = await makeState(
        withImagePicker: true,
        docsDir: tmp.path,
      );
      fakes.imagePicker.nextFile = XFile(shot.path);
      final post = makePost(id: 5);
      await state.markDone(post);
      expect(fakes.imagePicker.calls, 1);
      expect(state.dones.first.photoPath, isNotNull);
      expect(File(state.dones.first.photoPath!).existsSync(), isTrue);
      expect(state.isDone(5), isTrue);

      fakes.imagePicker.nextFile = null;
      await state.markDone(makePost(id: 7));
      expect(state.dones.first.photoPath, isNull);

      await state.markDone(makePost(id: 6), skipPhoto: true);
      expect(state.dones.first.photoPath, isNull);
      expect(state.doneCount, 3);
    });

    test('takePhoto without picker returns null', () async {
      final state = await makeState();
      expect(await state.takePhoto(), isNull);
    });

    test('savePhoto copies into docs dir', () async {
      final tmp = await Directory.systemTemp.createTemp('floof_test');
      addTearDown(() => tmp.delete(recursive: true));
      final state = await makeState(docsDir: tmp.path);
      final src = File('${tmp.path}/src.jpg')
        ..writeAsBytesSync([1, 2, 3]);
      final dest = await state.savePhoto(src);
      expect(dest, isNotNull);
      expect(File(dest!).existsSync(), isTrue);
      expect(dest, contains('done_'));

      final noDir = await makeState(docsDir: '');
      expect(await noDir.savePhoto(src), isNull);
    });

    test('clearHistory wipes both lists', () async {
      final state = await makeState();
      state.recordWatch(makePost(id: 1), 5, 10, false);
      await state.markDone(makePost(id: 1), skipPhoto: true);
      state.clearHistory();
      expect(state.history, isEmpty);
      expect(state.dones, isEmpty);
      expect(state.watchedCount, 0);
    });

    test('resetAlgorithm clears engine and feed', () async {
      final client = FakeBooruClient(posts: [makePost(id: 3)]);
      final state = await makeState(client: client);
      state.recordSignal(makePost(id: 1), Signal.liked);
      await state.loadMoreFeed();
      state.resetAlgorithm();
      expect(state.engine.weights, isEmpty);
      expect(state.feedPosts, isEmpty);
      await Future.delayed(Duration.zero);
    });
  });

  group('updates', () {
    test('checkForUpdates stores result', () async {
      final state =
          await makeState(updateResult: availableResult());
      await state.checkForUpdates();
      expect(state.lastUpdateCheck.status, UpdateCheckStatus.available);
      expect(state.pendingUpdate!.tag, 'v9.9.9');
    });

    test('concurrent check returns early', () async {
      final checker = FakeVersionChecker(UpdateCheckResult.upToDate);
      SharedPreferences.setMockInitialValues({});
      final p = await SharedPreferences.getInstance();
      final state = AppState(
        prefs: p,
        clientFactory: (a) => FakeBooruClient(),
        checkerFactory: (v) => checker,
      );
      state.updateChecking = true;
      await state.checkForUpdates();
      expect(checker.calls, 0);
    });
  });
}
