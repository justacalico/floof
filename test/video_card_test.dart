import 'dart:io';

import 'package:floof/l10n/app_localizations.dart';
import 'package:floof/models/post.dart';
import 'package:floof/state/app_state.dart';
import 'package:floof/widgets/video_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'helpers/pump.dart';

Widget cardAppFor(Post post, AppState state, {bool autofocus = false}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: VideoCard(post: post, state: state, autofocus: autofocus),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fakes = PlatformFakes()..install();

  testWidgets('thumbnail shows play button, taps to play', (tester) async {
    HttpOverrides.global = FakeHttpOverrides();
    addTearDown(() => HttpOverrides.global = null);
    final state = await makeState();
    await tester.pumpWidget(cardAppFor(makePost(id: 1), state));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
    await tester.tap(find.byIcon(Icons.play_circle_fill));
    await tester.pumpAndSettle();
    expect(fakes.video.playCalls, 1);
    expect(find.byType(VideoProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(VideoProgressIndicator), warnIfMissed: false);
    await tester.pumpWidget(const SizedBox());
    expect(state.history, hasLength(1));
  });

  testWidgets('play toggle pauses and resumes', (tester) async {
    final state = await makeState();
    await tester.pumpWidget(
        cardAppFor(makePost(id: 2), state, autofocus: true));
    await tester.pumpAndSettle();
    expect(fakes.video.playCalls, greaterThanOrEqualTo(1));
    final toggle = tester
        .widget<GestureDetector>(find.ancestor(
            of: find.byType(VideoPlayer),
            matching: find.byType(GestureDetector))
        .first);
    toggle.onTap!();
    await tester.pumpAndSettle();
    expect(fakes.video.pauseCalls, greaterThanOrEqualTo(1));
    toggle.onTap!();
    await tester.pumpAndSettle();
    expect(fakes.video.playCalls, greaterThanOrEqualTo(2));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('failed init shows error icon', (tester) async {
    fakes.video.throwOnCreate = true;
    addTearDown(() => fakes.video.throwOnCreate = false);
    final state = await makeState();
    await tester.pumpWidget(cardAppFor(makePost(id: 3), state));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_circle_fill));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    await tester.tap(find.byIcon(Icons.error_outline));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('like button toggles', (tester) async {
    final state = await makeState();
    await tester.pumpWidget(cardAppFor(makePost(id: 4), state));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(state.isLiked(makePost(id: 4)), isTrue);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('open in browser launches post url', (tester) async {
    final state = await makeState();
    await tester.pumpWidget(cardAppFor(makePost(id: 9), state));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.open_in_new));
    await tester.pumpAndSettle();
    expect(fakes.urlLauncher.launched, contains('https://e926.net/posts/9'));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('done flow skip records done', (tester) async {
    final state = await makeState();
    final post = makePost(id: 11);
    await tester.pumpWidget(cardAppFor(post, state));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();
    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(state.isDone(post), isTrue);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('done flow photo records done with picker', (tester) async {
    final tmp = await tester
        .runAsync(() => Directory.systemTemp.createTemp('floof_vcdone'));
    addTearDown(() => tmp!.delete(recursive: true));
    final shot = File('${tmp!.path}/shot.jpg')
      ..writeAsBytesSync(transparentPng);
    fakes.imagePicker.nextFile = XFile(shot.path);
    final state = await makeState(
      withImagePicker: true,
      docsDir: tmp.path,
    );
    await tester.pumpWidget(cardAppFor(makePost(id: 12), state));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();
    tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!();
    await tester.pumpAndSettle();
    expect(fakes.imagePicker.calls, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('done sheet dismiss does nothing', (tester) async {
    final state = await makeState();
    await tester.pumpWidget(cardAppFor(makePost(id: 13), state));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(state.dones, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('post without artist shows no chips', (tester) async {
    final state = await makeState();
    final post = Post.fromJson({'id': 21, 'tags': {}});
    await tester.pumpWidget(cardAppFor(post, state));
    await tester.pumpAndSettle();
    expect(find.byType(Chip), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
