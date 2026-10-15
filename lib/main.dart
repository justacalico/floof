import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'platform/io_ops.dart' as io;
import 'platform/platform_info.dart';
import 'platform/window_ops.dart';
import 'state/app_state.dart';

Future<void> initWindow(WindowOps ops) => ops.init();

WindowOps createWindowOps() => WindowManagerOps();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final window = createWindowOps();
  if (PlatformInfo.isDesktop) {
    await initWindow(window);
    await window.setTitle('floof');
  }

  final prefs = await SharedPreferences.getInstance();
  final docsDir = await io.documentsDir();
  final appVersion = await resolveAppVersion();

  final state = AppState(
    prefs: prefs,
    docsDir: docsDir,
    now: DateTime.now,
    imagePicker: ImagePicker(),
  );
  state.appVersion = appVersion;
  state.load();

  runApp(FloofApp(state: state, window: window));
}

Future<String> resolveAppVersion(
    {Future<PackageInfo> Function()? infoLoader}) async {
  final load = infoLoader ?? PackageInfo.fromPlatform;
  try {
    final info = await load();
    return info.version;
  } on MissingPluginException {
    return '0.1.0';
  }
}
