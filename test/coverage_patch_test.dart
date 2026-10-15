import 'dart:async';
import 'dart:io';

import 'package:floof/app.dart';
import 'package:floof/l10n/app_localizations.dart';
import 'package:floof/models/history_entry.dart';
import 'package:floof/models/post.dart';
import 'package:floof/models/profile.dart';
import 'package:floof/pages/history_page.dart';
import 'package:floof/pages/home_page.dart';
import 'package:floof/models/account.dart';
import 'package:floof/pages/profiles_page.dart';
import 'package:floof/pages/search_page.dart';
import 'package:floof/pages/settings_page.dart';
import 'package:floof/platform/window_ops.dart';
import 'package:floof/services/booru_client.dart';
import 'package:floof/services/taste_engine.dart';
import 'package:floof/state/app_state.dart';
import 'package:floof/main.dart' as app;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:floof/widgets/video_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump.dart';
import 'pages_test.dart' show pageApp;
import 'video_card_test.dart' show cardAppFor;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fakes = PlatformFakes()..install();

  test('BooruException toString', () {
    expect(const BooruException('x', 500).toString(),
        'BooruException(500): x');
    expect(const BooruException('y').toString(),
        'BooruException(null): y');
  });

  test('PostFileVariant parses', () {
    final v = PostFileVariant.fromJson({
      'codec': 'h264',
      'fps': 30,
      'size': 100,
      'width': 640,
      'height': 480,
      'url': 'u',
    });
    expect(v.codec, 'h264');
    expect(v.width, 640);
    expect(const PostFileVariant(url: 'x').codec, isNull);
  });

  test('history and profile epoch fallbacks', () {
    final h = HistoryEntry.fromJson({'watchedAt': 'bad', 'doneAt': 'bad'});
    expect(h.watchedAt.millisecondsSinceEpoch, 0);
    final d = DoneEntry.fromJson({'doneAt': 'bad'});
    expect(d.doneAt.millisecondsSinceEpoch, 0);
    final p = Profile.fromJson({'createdAt': 'bad'});
    expect(p.createdAt.millisecondsSinceEpoch, 0);
  });

  test('taste engine restores seen ids', () {
    final e = TasteEngine.fromJson(
        {'weights': {'g:fox': 2.0}, 'seen': [1, '2', 3]});
    expect(e.seenPostIds, containsAll(['1', '3']));
    expect(TasteEngine.fromJson({}).weights, isEmpty);
  });

  test('unsupported locale throws', () {
    expect(() => AppLocalizations.delegate.load(const Locale('xx')),
        throwsFlutterError);
  });

  test('AppState fallbacks', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState(
      prefs: await SharedPreferences.getInstance(),
      docsDir: '',
      clientFactory: (a) => FakeBooruClient(),
      now: () => DateTime(2026),
    );
    state.checkForUpdates();
    expect(state.appVersion.isNotEmpty, isTrue);
    state.load();
    state.activeAccountId = 'missing';
    expect(state.activeAccount, state.accounts.first);
    state.activeProfileId = 'missing';
    expect(state.activeProfile, state.profiles.first);
  });

  testWidgets('locale resolution callback', (tester) async {
    final state = await makeState();
    await tester.pumpWidget(FloofApp(state: state, window: FakeWindowOps()));
    await tester.pump();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final cb = app.localeResolutionCallback!;
    final supported = AppLocalizations.supportedLocales;
    expect(cb(const Locale('ru', 'RU'), supported)!.languageCode, 'ru');
    expect(cb(const Locale('zh', 'CN'), supported)!.languageCode, 'zh');
    expect(cb(const Locale('xx'), supported), const Locale('en', 'GB'));
    state.setLocale('ga');
    await tester.pump();
    expect(cb(const Locale('xx'), supported)!.languageCode, 'ga');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('window ops unmaximize when maximized', (tester) async {
    const channel = MethodChannel('window_manager');
    var maximized = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'isMaximized') return maximized;
      if (call.method == 'unmaximize') maximized = false;
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await WindowManagerOps().maximizeOrRestore();
    expect(maximized, isFalse);
  });

  testWidgets('card without playback reports nothing', (tester) async {
    HttpOverrides.global = FakeHttpOverrides();
    addTearDown(() => HttpOverrides.global = null);
    final state = await makeState();
    final key = GlobalKey<VideoCardState>();
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: VideoCard(
            key: key, post: makePost(id: 5, duration: 10), state: state),
      ),
    ));
    await tester.pumpAndSettle();
    key.currentState!.reportWatch();
    expect(state.history, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('card init completes after unmount disposes controller',
      (tester) async {
    HttpOverrides.global = FakeHttpOverrides();
    addTearDown(() => HttpOverrides.global = null);
    fakes.video.createGate = Completer<void>();
    addTearDown(() => fakes.video.createGate = null);
    final state = await makeState();
    await tester.pumpWidget(cardAppFor(makePost(id: 6), state));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.play_circle_fill));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    fakes.video.createGate!.complete();
    await tester.pump();
  });

  testWidgets('card with zero-size init falls back to post aspect',
      (tester) async {
    HttpOverrides.global = FakeHttpOverrides();
    addTearDown(() => HttpOverrides.global = null);
    fakes.video.initSize = const Size(0, 450);
    addTearDown(() => fakes.video.initSize = const Size(800, 450));
    final state = await makeState();
    await tester.pumpWidget(
        cardAppFor(makePost(id: 7), state, autofocus: true));
    await tester.pumpAndSettle();
    expect(find.byType(AspectRatio), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('history cancel button', (tester) async {
    final state = await makeState();
    state.recordWatch(makePost(id: 1), 5, 10, false);
    await tester.pumpWidget(pageApp(const HistoryPage(), state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(state.history, isNotEmpty);
  });

  testWidgets('history entries without thumbnail and bad images',
      (tester) async {
    HttpOverrides.global = FakeHttpOverrides(const [1, 2, 3]);
    addTearDown(() => HttpOverrides.global = null);
    final tmp = await tester
        .runAsync(() => Directory.systemTemp.createTemp('cov_hist'));
    addTearDown(() => tmp!.delete(recursive: true));
    final shot = File('${tmp!.path}/shot.jpg')
      ..writeAsBytesSync(const [1, 2, 3]);
    fakes.imagePicker.nextFile = XFile(shot.path);
    final state = await makeState(withImagePicker: true, docsDir: tmp.path);
    await tester.runAsync(() => state.markDone(makePost(id: 8)));
    state.history = [
      HistoryEntry(
        postId: 1,
        host: 'e926.net',
        watchedAt: DateTime(2026),
        postSummary: const {},
      ),
    ];
    state.dones.add(DoneEntry(
      postId: 9,
      host: 'e926.net',
      doneAt: DateTime(2026),
      photoPath: '${tmp.path}/gone.jpg',
      postSummary: const {},
    ));
    await tester.pumpWidget(pageApp(const HistoryPage(), state));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.videocam), findsWidgets);
    final img = tester.widget<Image>(find.byType(Image).last);
    final imgCtx = tester.element(find.byType(Image).last);
    final fallback =
        img.errorBuilder!(imgCtx, StateError('bad'), StackTrace.empty);
    expect(fallback, isA<Icon>());
  });

  test('resolveAppVersion paths', () async {
    expect(await app.resolveAppVersion(), isNotEmpty);
    expect(
      await app.resolveAppVersion(
          infoLoader: () async => _FakePackageInfo('9.9.9')),
      '9.9.9',
    );
    expect(
      await app.resolveAppVersion(
          infoLoader: () => throw MissingPluginException()),
      '0.1.0',
    );
  });

  testWidgets('home swipe reports watch and loads more', (tester) async {
    setViewSize(tester);
    HttpOverrides.global = FakeHttpOverrides();
    addTearDown(() => HttpOverrides.global = null);
    final client = FakeBooruClient(posts: [
      makePost(id: 1),
      makePost(id: 2),
      makePost(id: 3),
      makePost(id: 4),
    ]);
    final state = await makeState(client: client);
    state.feedPosts.addAll(client.posts);
    await tester.pumpWidget(pageApp(const HomePage(), state));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_circle_fill));
    await tester.pumpAndSettle();
    await tester.fling(
        find.byType(PageView), const Offset(0, -400), 1000);
    await tester.pumpAndSettle();
    await tester.fling(
        find.byType(PageView), const Offset(0, -400), 1000);
    await tester.pumpAndSettle();
    expect(state.history, isNotEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('profile dialogs submit and cancel', (tester) async {
    final state = await makeState();
    await tester.pumpWidget(pageApp(const ProfilesPage(), state));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'second');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(state.profiles.any((p) => p.name == 'second'), isTrue);
    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'renamed');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(state.profiles.any((p) => p.name == 'renamed'), isTrue);
    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(state.profiles.length, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('settings reset dialog cancel keeps data', (tester) async {
    final state = await makeState();
    await tester.pumpWidget(pageApp(const SettingsPage(), state));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Reset recommendations'), 200);
    tester
        .widget<ListTile>(
            find.widgetWithText(ListTile, 'Reset recommendations'))
        .onTap!();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('guest account dialog cancel', (tester) async {
    final state = await makeState();
    await tester.pumpWidget(pageApp(const SettingsPage(), state));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Add guest host'), 200);
    tester
        .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Add guest host'))
        .onPressed!();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('search autocomplete error and empty query', (tester) async {
    final client = FakeBooruClient()..throwOnAutocomplete = true;
    final state = await makeState(client: client);
    await tester.pumpWidget(pageApp(const SearchPage(), state));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'fox');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.image), findsNothing);
  });

  testWidgets('search appends rating filter on non-safe host',
      (tester) async {
    final client = FakeBooruClient();
    final state = await makeState(client: client);
    state.accounts = [Account.guest('https://e621.net')];
    state.activeAccountId = state.accounts.first.id;
    expect(state.contentRating, ContentRating.safe);
    await tester.pumpWidget(pageApp(const SearchPage(), state));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'fox');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(client.lastSearchTags, contains('rating:'));
  });

  testWidgets('search result thumbnail error builder', (tester) async {
    HttpOverrides.global = FakeHttpOverrides(const [1, 2, 3]);
    addTearDown(() => HttpOverrides.global = null);
    final state = await makeState();
    await tester.pumpWidget(pageApp(const SearchPage(), state));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'fox');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byIcon(Icons.broken_image), findsWidgets);
  });
}


class _FakePackageInfo extends PackageInfo {
  _FakePackageInfo(String v)
      : super(
          appName: 'floof',
          buildNumber: '1',
          packageName: 'x',
          version: v,
        );
}
