import 'dart:io';

import 'package:floof/app.dart';
import 'package:floof/main.dart' as app;
import 'package:floof/platform/platform_info.dart';
import 'package:floof/state/app_state.dart';
import 'package:floof/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fakes = PlatformFakes()..install();

  tearDown(() => PlatformInfo.desktopOverride = null);

  testWidgets('app builds the shell with five destinations', (tester) async {
    setViewSize(tester);
    PlatformInfo.desktopOverride = false;
    final state = await makeState();
    await tester.pumpWidget(
        FloofApp(state: state, window: FakeWindowOps()));
    await tester.pumpAndSettle();
    for (final label in ['Home', 'Search', 'Profiles', 'History', 'Settings']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('app respects theme and locale settings', (tester) async {
    setViewSize(tester);
    PlatformInfo.desktopOverride = false;
    final state = await makeState();
    state.setTheme(AppTheme.oled);
    state.setLocale('ru');
    await tester.pumpWidget(
        FloofApp(state: state, window: FakeWindowOps()));
    await tester.pumpAndSettle();
    expect(find.text('Главная'), findsWidgets);

    state.setTheme(AppTheme.light);
    state.setLocale('en_GB');
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);

    state.setTheme(AppTheme.dark);
    state.setLocale('zh');
    await tester.pumpAndSettle();
    expect(find.text('首页'), findsWidgets);

    state.setTheme(AppTheme.system);
    state.setLocale('ga');
    await tester.pumpAndSettle();
    expect(find.text('Baile'), findsWidgets);
  });

  testWidgets('main() boots the real app', (tester) async {
    setViewSize(tester);
    PlatformInfo.desktopOverride = true;
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('window_manager');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => true);
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    const pkg = MethodChannel('dev.fluttercommunity.plus/package_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pkg, (call) async => {
              'appName': 'floof',
              'buildNumber': '1',
              'packageName': 'gitlab.httpanimations.floof',
              'version': '0.1.0',
              'buildSignature': '',
            });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pkg, null));
    final tmp = await tester
        .runAsync(() => Directory.systemTemp.createTemp('floof_main'));
    addTearDown(() => tmp!.delete(recursive: true));
    PathProviderPlatform.instance = FakePathProviderPlatform(tmp!.path);

    HttpOverrides.global = FakeHttpOverrides();
    addTearDown(() => HttpOverrides.global = null);

    await app.main();
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('main() survives missing plugins', (tester) async {
    setViewSize(tester);
    PlatformInfo.desktopOverride = false;
    SharedPreferences.setMockInitialValues({});
    final fake = FakePathProviderPlatform('')
      ..error = MissingPluginException();
    PathProviderPlatform.instance = fake;
    // package_info has no mock handler in this test, so it throws
    // MissingPluginException and falls back to the baked-in version.
    await tester.runAsync(() => app.main());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AppShell), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test('takePhoto picks, saves and handles cancel', () async {
    final tmp = await Directory.systemTemp.createTemp('floof_pick');
    addTearDown(() => tmp.delete(recursive: true));
    final src = File('${tmp.path}/cam.jpg')..writeAsBytesSync(transparentPng);
    fakes.imagePicker.nextFile = XFile(src.path);
    final state = await makeState(
      withImagePicker: true,
      docsDir: tmp.path,
    );
    final saved = await state.takePhoto();
    expect(saved, isNotNull);
    expect(File(saved!).existsSync(), isTrue);
    expect(fakes.imagePicker.calls, 1);

    fakes.imagePicker.nextFile = null;
    expect(await state.takePhoto(), isNull);
  });
}
