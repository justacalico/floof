import 'package:floof/pages/settings_page.dart';
import 'package:floof/services/version_checker.dart';
import 'package:floof/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:floof/l10n/app_localizations.dart';

import 'helpers/pump.dart';

Widget settingsApp(AppState state) {
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
      home: const Scaffold(body: SettingsPage()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fakes = PlatformFakes()..install();

  testWidgets('lists accounts and switches active', (tester) async {
    setViewSize(tester);
    final state = await makeState();
    state.addGuestAccount('https://e621.net');
    await tester.pumpWidget(settingsApp(state));
    await tester.pumpAndSettle();
    expect(find.textContaining('e621'), findsWidgets);
    await tester.tap(find.text('Guest (e926)'));
    await tester.pumpAndSettle();
    expect(state.activeAccount.hostBaseUrl, 'https://e926.net');
  });

  testWidgets('sign in dialog adds account on success', (tester) async {
    setViewSize(tester);
    final state = await makeState();
    await tester.pumpWidget(settingsApp(state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'myuser');
    await tester.enterText(fields.at(1), 'mykey');
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    expect(state.activeAccount.username, 'myuser');
    expect(find.text('Signed in'), findsOneWidget);
  });

  testWidgets('failed sign in shows error', (tester) async {
    setViewSize(tester);
    final client = FakeBooruClient()..verifyResult = false;
    final state = await makeState(client: client);
    await tester.pumpWidget(settingsApp(state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'bad');
    await tester.enterText(fields.at(1), 'bad');
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Sign in failed'), findsOneWidget);
    expect(state.accounts, hasLength(1));
  });

  testWidgets('sign in dialog cancel and custom host', (tester) async {
    setViewSize(tester);
    final state = await makeState();
    await tester.pumpWidget(settingsApp(state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('e926'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('custom').last);
    await tester.pumpAndSettle();
    expect(find.text('Custom host URL'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(state.accounts, hasLength(1));
  });

  testWidgets('guest host dialog adds e621 guest', (tester) async {
    setViewSize(tester);
    final state = await makeState();
    await tester.pumpWidget(settingsApp(state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add guest host'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('e621'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('custom'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField), 'https://mirror.example');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(
        state.activeAccount.hostBaseUrl, 'https://mirror.example');
  });

  testWidgets('remove account button', (tester) async {
    setViewSize(tester);
    final state = await makeState();
    state.addGuestAccount('https://e621.net');
    state.setActiveAccount('guest-https://e926.net');
    await tester.pumpWidget(settingsApp(state));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(state.accounts, hasLength(1));
  });

  testWidgets('theme radios switch theme', (tester) async {
    setViewSize(tester);
    final state = await makeState();
    await tester.pumpWidget(settingsApp(state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OLED'));
    await tester.pumpAndSettle();
    expect(state.theme, AppTheme.oled);
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(state.theme, AppTheme.light);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(state.theme, AppTheme.dark);
    await tester.tap(find.text('System').first);
    await tester.pumpAndSettle();
    expect(state.theme, AppTheme.system);
  });

  testWidgets('language picker switches locale', (tester) async {
    setViewSize(tester);
    final state = await makeState();
    await tester.pumpWidget(settingsApp(state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('简体中文'));
    await tester.pumpAndSettle();
    expect(state.localeTag, 'zh');
    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();
    expect(state.localeTag, 'ru');
    await tester.tap(find.text('Gaeilge'));
    await tester.pumpAndSettle();
    expect(state.localeTag, 'ga');
    await tester.tap(find.text('Traditional English'));
    await tester.pumpAndSettle();
    expect(state.localeTag, 'en_GB');
    await tester.tap(find.text('System').last);
    await tester.pumpAndSettle();
    expect(state.localeTag, '');
  });

  testWidgets('content rating unlocked on non-e926 host', (tester) async {
    setViewSize(tester);
    final state = await makeState();
    state.addGuestAccount('https://e621.net');
    await tester.pumpWidget(settingsApp(state));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Everything'), 200);
    await tester.pumpAndSettle();
    tester
        .widget<RadioGroup<ContentRating>>(
            find.byType(RadioGroup<ContentRating>))
        .onChanged(ContentRating.all);
    await tester.pumpAndSettle();
    expect(state.contentRating, ContentRating.all);
  });

  testWidgets('clear history confirms and clears', (tester) async {
    setViewSize(tester);
    final state = await makeState();
    state.recordWatch(makePost(id: 1), 5, 10, false);
    await tester.pumpWidget(settingsApp(state));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Clear history'), 200);
    tester
        .widget<ListTile>(find.widgetWithText(ListTile, 'Clear history'))
        .onTap!();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(state.history, isNotEmpty);
    await tester.scrollUntilVisible(find.text('Clear history'), 200);
    tester
        .widget<ListTile>(find.widgetWithText(ListTile, 'Clear history'))
        .onTap!();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(state.history, isEmpty);
    expect(find.text('History cleared'), findsOneWidget);
  });

  testWidgets('reset algorithm confirms', (tester) async {
    setViewSize(tester);
    final client = FakeBooruClient(posts: [makePost(id: 1)]);
    final state = await makeState(client: client);
    await tester.pumpWidget(settingsApp(state));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Reset recommendations'), 200);
    tester
        .widget<ListTile>(
            find.widgetWithText(ListTile, 'Reset recommendations'))
        .onTap!();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(state.engine.weights, isEmpty);
    expect(find.text('Recommendations reset'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('update check shows available release', (tester) async {
    setViewSize(tester);
    final state = await makeState(updateResult: availableResult());
    await tester.pumpWidget(settingsApp(state));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Check for updates'), 200);
    tester
        .widget<ListTile>(
            find.widgetWithText(ListTile, 'Check for updates'))
        .onTap!();
    await tester.pumpAndSettle();
    expect(find.text('Version v9.9.9 is available'), findsOneWidget);
    await tester.tap(find.text('Version v9.9.9 is available'));
    await tester.pumpAndSettle();
    expect(fakes.urlLauncher.launched, contains(
        'https://gitlab.com/HttpAnimations/floof/-/releases/v9.9.9'));
  });

  testWidgets('up to date and failed states', (tester) async {
    setViewSize(tester);
    final state = await makeState(
        updateResult: UpdateCheckResult.upToDate);
    await tester.pumpWidget(settingsApp(state));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Check for updates'), 200);
    tester
        .widget<ListTile>(
            find.widgetWithText(ListTile, 'Check for updates'))
        .onTap!();
    await tester.pumpAndSettle();
    expect(find.text('You are on the latest release.'), findsOneWidget);

    final failed =
        await makeState(updateResult: UpdateCheckResult.failed);
    await tester.pumpWidget(settingsApp(failed));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Check for updates'), 200);
    tester
        .widget<ListTile>(
            find.widgetWithText(ListTile, 'Check for updates'))
        .onTap!();
    await tester.pumpAndSettle();
    expect(find.text('Could not check for updates.'), findsOneWidget);
  });

  testWidgets('all releases link launches', (tester) async {
    setViewSize(tester);
    final state = await makeState();
    await tester.pumpWidget(settingsApp(state));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('All releases'), 200);
    tester
        .widget<ListTile>(find.widgetWithText(ListTile, 'All releases'))
        .onTap!();
    await tester.pumpAndSettle();
    expect(fakes.urlLauncher.launched,
        contains(VersionChecker.releasesPage));
  });
}
