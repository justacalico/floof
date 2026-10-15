import 'dart:io';

import 'package:floof/l10n/app_localizations.dart';
import 'package:floof/models/post.dart';
import 'package:floof/pages/history_page.dart';
import 'package:floof/pages/home_page.dart';
import 'package:floof/pages/profiles_page.dart';
import 'package:floof/pages/search_page.dart';
import 'package:floof/pages/viewer_page.dart';
import 'package:floof/services/booru_client.dart';
import 'package:floof/services/taste_engine.dart';
import 'package:floof/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'helpers/pump.dart';

Widget pageApp(Widget page, AppState state) {
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: page),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fakes = PlatformFakes()..install();
  setUp(() => HttpOverrides.global = FakeHttpOverrides());
  tearDown(() => HttpOverrides.global = null);

  group('HomePage', () {
    testWidgets('loading spinner when empty and loading', (tester) async {
      setViewSize(tester);
      final state = await makeState();
      state.feedLoading = true;
      await tester.pumpWidget(pageApp(const HomePage(), state));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      state.feedLoading = false;
    });

    testWidgets('error state retries', (tester) async {
      setViewSize(tester);
      final client = FakeBooruClient()..throwOnSearch = true;
      final state = await makeState(client: client);
      state.feedError = 'x';
      state.feedLoading = false;
      await tester.pumpWidget(pageApp(const HomePage(), state));
      await tester.pump();
      expect(find.text('Could not load the feed.'), findsOneWidget);
      client.throwOnSearch = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(state.feedPosts, isNotEmpty);
    });

    testWidgets('empty state shows message', (tester) async {
      setViewSize(tester);
      final state = await makeState(client: FakeBooruClient(posts: []));
      await tester.pumpWidget(pageApp(const HomePage(), state));
      await tester.pumpAndSettle();
      expect(find.text('Nothing here yet. Pull some videos in.'),
          findsOneWidget);
    });

    testWidgets('feed renders posts and swipes track watch', (tester) async {
      setViewSize(tester);
      final client = FakeBooruClient(posts: [
        for (var i = 0; i < 8; i++) makePost(id: i + 1),
      ]);
      final state = await makeState(client: client);
      await state.loadMoreFeed(batchSize: 8);
      await tester.pumpWidget(pageApp(const HomePage(), state));
      await tester.pumpAndSettle();
      expect(find.byType(PageView), findsOneWidget);
      await tester.fling(find.byType(PageView), const Offset(0, -400), 800);
      await tester.pumpAndSettle();
      expect(state.history, isNotEmpty);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('SearchPage', () {
    testWidgets('autocomplete suggests and searches', (tester) async {
      setViewSize(tester);
      final client = FakeBooruClient(
        posts: [makePost(id: 42)],
        suggestions: const [TagSuggestion('canine', 5000)],
      );
      final state = await makeState(client: client);
      await tester.pumpWidget(pageApp(const SearchPage(), state));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'can');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('canine'), findsWidgets);
      await tester.tap(find.text('canine').last);
      await tester.pumpAndSettle();
      expect(client.lastSearchTags, contains('type:webm'));
      expect(find.byType(GridView), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('submit shows results, clear resets', (tester) async {
      setViewSize(tester);
      final client = FakeBooruClient(posts: [makePost(id: 7)]);
      final state = await makeState(client: client);
      await tester.pumpWidget(pageApp(const SearchPage(), state));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'fox');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(client.lastSearchTags, contains('fox'));
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('tapping a result opens the viewer', (tester) async {
      setViewSize(tester);
      final client = FakeBooruClient(posts: [makePost(id: 55)]);
      final state = await makeState(client: client);
      await tester.pumpWidget(pageApp(const SearchPage(), state));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'wolf');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(find.byType(ViewerPage), findsOneWidget);
      expect(find.text('#55'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('empty results and error path', (tester) async {
      setViewSize(tester);
      final client = FakeBooruClient(posts: []);
      final state = await makeState(client: client);
      await tester.pumpWidget(pageApp(const SearchPage(), state));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('No videos matched that search.'), findsOneWidget);

      client.throwOnSearch = true;
      await tester.enterText(find.byType(TextField), 'again');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('No videos matched that search.'), findsOneWidget);
    });
  });

  group('ViewerPage', () {
    testWidgets('autoplays', (tester) async {
      setViewSize(tester);
      final state = await makeState();
      await tester.pumpWidget(
          pageApp(ViewerPage(post: makePost(id: 66)), state));
      await tester.pumpAndSettle();
      expect(fakes.video.playCalls, greaterThanOrEqualTo(1));
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('ProfilesPage', () {
    testWidgets('lists profiles and adds one', (tester) async {
      setViewSize(tester);
      final state = await makeState();
      await tester.pumpWidget(pageApp(const ProfilesPage(), state));
      await tester.pumpAndSettle();
      expect(find.text('Default'), findsOneWidget);
      await tester.tap(find.text('Add profile'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'second');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(state.profiles, hasLength(2));
      expect(find.text('second'), findsOneWidget);
      expect(find.text('Active profile'), findsOneWidget);
    });

    testWidgets('cancel add does nothing', (tester) async {
      setViewSize(tester);
      final state = await makeState();
      await tester.pumpWidget(pageApp(const ProfilesPage(), state));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(state.profiles, hasLength(1));
    });

    testWidgets('rename and delete', (tester) async {
      setViewSize(tester);
      final state = await makeState();
      state.addProfile('bye');
      state.switchProfile(state.profiles.first.id);
      await tester.pumpWidget(pageApp(const ProfilesPage(), state));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'renamed');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      expect(state.profiles.first.name, 'renamed');

      await tester.tap(find.byIcon(Icons.delete_outline).last);
      await tester.pumpAndSettle();
      expect(state.profiles, hasLength(1));
    });

    testWidgets('switching profiles works', (tester) async {
      setViewSize(tester);
      final state = await makeState();
      state.addProfile('other');
      await tester.pumpWidget(pageApp(const ProfilesPage(), state));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Default'));
      await tester.pumpAndSettle();
      expect(state.activeProfile.name, 'Default');
    });

    testWidgets('taste card shows learned weights', (tester) async {
      setViewSize(tester);
      final state = await makeState();
      state.recordSignal(makePost(id: 1, general: const ['fox']), Signal.done);
      state.recordSignal(makePost(id: 2, general: const ['rock'], artist: const ['x'], species: const ['y']), Signal.quickSkip);
      await tester.pumpWidget(pageApp(const ProfilesPage(), state));
      await tester.pumpAndSettle();
      expect(find.text('What the algorithm learned'), findsOneWidget);
      expect(find.text('Likes'), findsOneWidget);
      expect(find.text('Dislikes'), findsOneWidget);
      expect(find.textContaining('fox'), findsOneWidget);
    });
  });

  group('HistoryPage', () {
    testWidgets('empty state', (tester) async {
      setViewSize(tester);
      final state = await makeState();
      await tester.pumpWidget(pageApp(const HistoryPage(), state));
      await tester.pumpAndSettle();
      expect(find.text('No history yet. Go watch something.'), findsOneWidget);
    });

    testWidgets('shows entries grouped by day and clears', (tester) async {
      setViewSize(tester);
      final tmp = await Directory.systemTemp.createTemp('floof_hist');
      addTearDown(() => tmp.delete(recursive: true));
      final shot = File('${tmp.path}/shot.jpg')
        ..writeAsBytesSync(transparentPng);
      fakes.imagePicker.nextFile = XFile(shot.path);
      final state = await makeState(
        withImagePicker: true,
        docsDir: tmp.path,
      );
      state.recordWatch(makePost(id: 1), 12, 12, true);
      state.recordWatch(makePost(id: 2), 3, 12, false);
      await state.markDone(makePost(id: 3));
      await tester.pumpWidget(pageApp(const HistoryPage(), state));
      await tester.pumpAndSettle();
      expect(find.textContaining('Done at'), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
      expect(find.text('Clear history'), findsOneWidget);

      await tester.tap(find.text('Clear history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(state.history, isEmpty);
      expect(find.text('No history yet. Go watch something.'), findsOneWidget);
    });

    testWidgets('done photo falls back when missing', (tester) async {
      setViewSize(tester);
      fakes.imagePicker.nextFile = null;
      final state = await makeState(withImagePicker: true);
      await state.markDone(makePost(id: 4));
      await tester.pumpWidget(pageApp(const HistoryPage(), state));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    });
  });
}
