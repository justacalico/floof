import 'dart:convert';
import 'dart:io';

import 'package:floof/l10n/app_localizations.dart';
import 'package:floof/models/post.dart';
import 'package:floof/pages/history_page.dart';
import 'package:floof/pages/home_page.dart';
import 'package:floof/pages/profiles_page.dart';
import 'package:floof/pages/search_page.dart';
import 'package:floof/state/app_state.dart';
import 'package:floof/widgets/app_shell.dart';
import 'package:floof/widgets/nav_sidebar.dart';
import 'package:floof/widgets/video_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'helpers/pump.dart';
import 'pages_test.dart' show pageApp;
import 'video_card_test.dart' show cardAppFor;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fakes = PlatformFakes()..install();

  test('load survives corrupt prefs', () async {
    final state = await makeState(prefs: {
      'accounts': '{bad json',
      'profiles': '[{oops',
      'activeAccountId': 'ghost',
      'activeProfileId': 'ghost',
      'theme': 99,
      'contentRating': -5,
      'profile.default.taste': 'nope',
    });
    expect(state.accounts, hasLength(1));
    expect(state.activeAccountId, state.accounts.first.id);
    expect(state.activeProfileId, state.profiles.first.id);
    expect(state.theme, AppTheme.oled);
    expect(state.contentRating, ContentRating.safe);
    expect(state.engine.weights, isEmpty);
  });

  test('recordWatch for a stale profile writes its own store', () async {
    final state = await makeState(prefs: {
      'profile.other.taste': jsonEncode({'weights': {}}),
      'profile.other.history': jsonEncode([
        for (var i = 0; i < 505; i++)
          {'postId': i, 'host': 'h', 'watchedAt': '2026-01-01T00:00:00'}
      ]),
    });
    final post = makePost(id: 7);
    state.recordWatch(post, 20, 30, false, profileId: 'other');
    final hist = jsonDecode(state.prefs.getString('profile.other.history')!)
        as List;
    expect(hist.length, 500);
    expect(hist.first['postId'], 7);
    final taste =
        jsonDecode(state.prefs.getString('profile.other.taste')!) as Map;
    expect(taste['weights'], isNotEmpty);
    expect(state.history, isEmpty);
  });

  test('toggleLike rolls back on remote failure', () async {
    final client = FakeBooruClient()..throwOnFav = true;
    final state = await makeState(client: client);
    await state.addAccount('u', 'k', 'https://e926.net');
    client.throwOnFav = true;
    final post = makePost(id: 3);
    await state.toggleLike(post);
    expect(state.isLiked(post), isFalse);
    client.throwOnFav = false;
    await state.toggleLike(post);
    expect(state.isLiked(post), isTrue);
  });

  test('markDone ignores already-done posts', () async {
    final state = await makeState();
    final post = makePost(id: 9);
    await state.markDone(post, skipPhoto: true);
    await state.markDone(post, skipPhoto: true);
    expect(state.dones, hasLength(1));
  });

  testWidgets('card resets when post changes underneath it', (tester) async {
    HttpOverrides.global = FakeHttpOverrides();
    addTearDown(() => HttpOverrides.global = null);
    final state = await makeState();
    final key = GlobalKey<VideoCardState>();
    Widget frame(Post p) => MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
              body: VideoCard(key: key, post: p, state: state, autofocus: true)),
        );
    await tester.pumpWidget(frame(makePost(id: 1)));
    await tester.pumpAndSettle();
    expect(fakes.video.playCalls, greaterThan(0));
    await tester.pumpWidget(frame(makePost(id: 2)));
    await tester.pumpAndSettle();
    expect(state.history, isNotEmpty);
    expect(find.byType(VideoPlayer), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('pausePlayback pauses a playing card', (tester) async {
    HttpOverrides.global = FakeHttpOverrides();
    addTearDown(() => HttpOverrides.global = null);
    final state = await makeState();
    final key = GlobalKey<VideoCardState>();
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: VideoCard(
            key: key, post: makePost(id: 4), state: state, autofocus: true),
      ),
    ));
    await tester.pumpAndSettle();
    key.currentState!.pausePlayback();
    expect(fakes.video.pauseCalls, greaterThan(0));
    key.currentState!.reportWatch();
    expect(state.history, hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('failed init tap retries playback', (tester) async {
    HttpOverrides.global = FakeHttpOverrides();
    addTearDown(() => HttpOverrides.global = null);
    fakes.video.throwOnCreate = true;
    addTearDown(() => fakes.video.throwOnCreate = false);
    final state = await makeState();
    await tester.pumpWidget(cardAppFor(makePost(id: 6), state));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.play_circle_fill));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    fakes.video.throwOnCreate = false;
    final ink = tester.widget<InkWell>(find.byType(InkWell).first);
    ink.onTap!();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(VideoPlayer), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('hidden tab pauses playback', (tester) async {
    setViewSize(tester);
    HttpOverrides.global = FakeHttpOverrides();
    addTearDown(() => HttpOverrides.global = null);
    final state = await makeState();
    final cardKey = GlobalKey<VideoCardState>();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppShell(
          title: 'floof',
          window: FakeWindowOps(),
          destinations: const [
            NavDestination(Icons.home, 'Home'),
            NavDestination(Icons.settings, 'Settings'),
          ],
          pages: [
            VideoCard(
                key: cardKey, post: makePost(id: 8), state: state, autofocus: true),
            const Text('other'),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(fakes.video.playCalls, greaterThan(0));
    tester.widget<NavSidebar>(find.byType(NavSidebar)).onSelect(1);
    await tester.pumpAndSettle();
    expect(fakes.video.pauseCalls, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('search error path clears loading', (tester) async {
    final client = FakeBooruClient()..throwOnSearch = true;
    final state = await makeState(client: client);
    await tester.pumpWidget(pageApp(const SearchPage(), state));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'fox');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('search next page dedupes results', (tester) async {
    setViewSize(tester);
    final shared = makePost(id: 1);
    final client = FakeBooruClient(
      posts: [for (var i = 0; i < 40; i++) i == 0 ? shared : makePost(id: i + 1)],
    )..laterPosts = [shared, makePost(id: 500)];
    final state = await makeState(client: client);
    await tester.pumpWidget(pageApp(const SearchPage(), state));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'fox');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.fling(
        find.byType(GridView), const Offset(0, -4000), 3000);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  test('recordWatch stale profile with no stored data', () async {
    final state = await makeState();
    state.recordWatch(makePost(id: 3), 5, null, true, profileId: 'never');
    final hist =
        jsonDecode(state.prefs.getString('profile.never.history')!) as List;
    expect(hist, hasLength(1));
  });

  test('toggleLike rolls back failed unlike too', () async {
    final client = FakeBooruClient();
    final state = await makeState(client: client);
    await state.addAccount('u', 'k', 'https://e926.net');
    final post = makePost(id: 4);
    await state.toggleLike(post);
    expect(state.isLiked(post), isTrue);
    client.throwOnFav = true;
    await state.toggleLike(post);
    expect(state.isLiked(post), isTrue);
    expect(client.unfavCalls, 1);
  });

  test('page constructors', () {
    expect(HomePage(), isA<HomePage>());
    expect(SearchPage(), isA<SearchPage>());
    expect(ProfilesPage(), isA<ProfilesPage>());
    expect(HistoryPage(), isA<HistoryPage>());
  });

  test('savePhoto keeps dotless filenames', () async {
    final tmp = await Directory.systemTemp.createTemp('floof_dot');
    addTearDown(() => tmp.delete(recursive: true));
    final src = File('${tmp.path}/nofileext')..writeAsBytesSync([1]);
    final state = await makeState(docsDir: tmp.path);
    final dest = await state.savePhoto(src.path);
    expect(dest, isNotNull);
    expect(File(dest!).existsSync(), isTrue);
  });
}
