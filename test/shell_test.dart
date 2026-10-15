import 'package:floof/platform/platform_info.dart';
import 'package:floof/platform/window_ops.dart';
import 'package:floof/widgets/app_shell.dart';
import 'package:floof/widgets/desktop_title_bar.dart';
import 'package:floof/widgets/nav_sidebar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump.dart';

Widget shellApp(WindowOps window) {
  return MaterialApp(
    home: AppShell(
      title: 'floof',
      window: window,
      destinations: const [
        NavDestination(Icons.home, 'Home'),
        NavDestination(Icons.search, 'Search'),
        NavDestination(Icons.settings, 'Settings'),
      ],
      pages: const [
        Center(child: Text('page-home')),
        Center(child: Text('page-search')),
        Center(child: Text('page-settings')),
      ],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => PlatformInfo.desktopOverride = null);

  testWidgets('wide layout shows sidebar and navigates', (tester) async {
    setViewSize(tester);
    PlatformInfo.desktopOverride = false;
    await tester.pumpWidget(shellApp(FakeWindowOps()));
    await tester.pumpAndSettle();
    expect(find.byType(DesktopTitleBar), findsNothing);
    int? index() =>
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index;
    expect(index(), 0);
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(index(), 1);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(index(), 2);
  });

  testWidgets('narrow layout uses drawer', (tester) async {
    setViewSize(tester, const Size(400, 800));
    PlatformInfo.desktopOverride = false;
    await tester.pumpWidget(shellApp(FakeWindowOps()));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.byType(NavSidebar), findsOneWidget);
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
      1,
    );
  });

  testWidgets('desktop shows title bar with working buttons',
      (tester) async {
    setViewSize(tester);
    PlatformInfo.desktopOverride = true;
    final window = FakeWindowOps();
    await tester.pumpWidget(shellApp(window));
    await tester.pumpAndSettle();
    expect(find.byType(DesktopTitleBar), findsOneWidget);

    final buttons = tester.widgetList<GestureDetector>(
        find.descendant(
            of: find.byType(DesktopTitleBar),
            matching: find.byType(GestureDetector)));
    await tester.tap(find.byWidget(buttons.elementAt(0).child!));
    await tester.tap(find.byWidget(buttons.elementAt(1).child!));
    await tester.tap(find.byWidget(buttons.elementAt(2).child!));
    await tester.pumpAndSettle();
    expect(window.closes, 1);
    expect(window.minimizes, 1);
    expect(window.maxCalls, 1);

    final gesture =
        await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byWidget(buttons.elementAt(0).child!)));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsOneWidget);
    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();
  });

  testWidgets('double tap title bar maximizes', (tester) async {
    setViewSize(tester);
    PlatformInfo.desktopOverride = true;
    final window = FakeWindowOps();
    await tester.pumpWidget(shellApp(window));
    await tester.pumpAndSettle();
    final doubleTap = tester
        .widgetList<GestureDetector>(find.byType(GestureDetector))
        .firstWhere((g) => g.onDoubleTap != null);
    doubleTap.onDoubleTap!();
    await tester.pumpAndSettle();
    expect(window.maxCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('window manager ops hit the channel', (tester) async {
    const channel = MethodChannel('window_manager');
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'isMaximized') return false;
      return true;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));

    final ops = WindowManagerOps();
    await ops.init();
    await ops.close();
    await ops.minimize();
    await ops.maximizeOrRestore();
    expect(await ops.isMaximized(), isFalse);
    await ops.setTitle('floof');
    expect(calls, containsAll([
      'ensureInitialized',
      'waitUntilReadyToShow',
      'close',
      'minimize',
      'maximize',
      'setTitle',
    ]));
  });

  test('platform info respects override and default', () {
    PlatformInfo.desktopOverride = true;
    expect(PlatformInfo.isDesktop, isTrue);
    PlatformInfo.desktopOverride = false;
    expect(PlatformInfo.isDesktop, isFalse);
    PlatformInfo.desktopOverride = null;
    expect(PlatformInfo.isDesktop, isA<bool>());
  });

  testWidgets('sidebar renders footer', (tester) async {
    setViewSize(tester);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NavSidebar(
          selectedIndex: 0,
          destinations: const [NavDestination(Icons.home, 'H')],
          onSelect: (_) {},
          footer: const Text('foot'),
        ),
      ),
    ));
    expect(find.text('foot'), findsOneWidget);
  });
}
