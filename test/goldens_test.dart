import 'dart:io';

import 'package:floof/l10n/app_localizations.dart';
import 'package:floof/models/history_entry.dart';
import 'package:floof/pages/history_page.dart';
import 'package:floof/pages/home_page.dart';
import 'package:floof/pages/profiles_page.dart';
import 'package:floof/pages/search_page.dart';
import 'package:floof/pages/settings_page.dart';
import 'package:floof/pages/viewer_page.dart';
import 'package:floof/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:provider/provider.dart';

import 'helpers/pump.dart';

Widget goldenApp(Widget page, AppState state, {Locale? locale}) {
  return ChangeNotifierProvider.value(
    value: state,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
      home: Scaffold(body: page),
    ),
  );
}

void main() {
  PlatformFakes().install();

  setUpAll(() async {
    HttpOverrides.global = FakeHttpOverrides();
    await loadAppFonts();
  });

  tearDownAll(() => HttpOverrides.global = null);

  Future<void> snap(
    WidgetTester tester,
    Widget page,
    AppState state,
    String name, {
    Locale? locale,
  }) async {
    await tester.pumpWidgetBuilder(
      goldenApp(page, state, locale: locale),
      surfaceSize: const Size(900, 640),
    );
    await tester.pump();
    await screenMatchesGolden(tester, name);
  }

  Future<AppState> seededState() async {
    final client = FakeBooruClient(posts: [
      makePost(id: 1),
      makePost(id: 2, artist: const ['otherartist']),
    ]);
    final state = await makeState(client: client);
    state.feedPosts.addAll(client.posts);
    state.history = [
      HistoryEntry(
        postId: 1,
        host: 'e926.net',
        watchedAt: DateTime(2026, 1, 1, 12),
        watchSeconds: 30,
        durationSeconds: 60,
        completed: false,
        postSummary: makePost(id: 1).toSummary(),
      ),
    ];
    state.dones = [
      DoneEntry(
        postId: 2,
        host: 'e926.net',
        doneAt: DateTime(2026, 1, 1, 12, 30),
        postSummary: makePost(id: 2).toSummary(),
      ),
    ];
    return state;
  }

  testGoldens('home page', (tester) async {
    final state = await seededState();
    await snap(tester, const HomePage(), state, 'home');
  });

  testGoldens('search page', (tester) async {
    final state = await seededState();
    await snap(tester, const SearchPage(), state, 'search');
  });

  testGoldens('profiles page', (tester) async {
    final state = await seededState();
    await snap(tester, const ProfilesPage(), state, 'profiles');
  });

  testGoldens('history page', (tester) async {
    final state = await seededState();
    await snap(tester, const HistoryPage(), state, 'history');
  });

  testGoldens('settings page', (tester) async {
    final state = await seededState();
    await snap(tester, const SettingsPage(), state, 'settings');
  });

  testGoldens('viewer page', (tester) async {
    final state = await seededState();
    await snap(
      tester,
      ViewerPage(post: makePost(id: 3)),
      state,
      'viewer',
    );
  });

  testGoldens('history page in russian', (tester) async {
    final state = await seededState();
    await snap(
      tester,
      const HistoryPage(),
      state,
      'history_ru',
      locale: const Locale('ru'),
    );
  });

  testGoldens('home page in simplified chinese', (tester) async {
    final state = await seededState();
    await snap(
      tester,
      const HomePage(),
      state,
      'home_zh',
      locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    );
  });
}
