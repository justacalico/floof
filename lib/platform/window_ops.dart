import 'package:window_manager/window_manager.dart';

abstract class WindowOps {
  Future<void> init();
  Future<void> close();
  Future<void> minimize();
  Future<void> maximizeOrRestore();
  Future<bool> isMaximized();
  Future<void> setTitle(String title);
}

class WindowManagerOps implements WindowOps {
  @override
  Future<void> init() async {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  @override
  Future<void> close() => windowManager.close();

  @override
  Future<void> minimize() => windowManager.minimize();

  @override
  Future<void> maximizeOrRestore() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Future<bool> isMaximized() => windowManager.isMaximized();

  @override
  Future<void> setTitle(String title) => windowManager.setTitle(title);
}
