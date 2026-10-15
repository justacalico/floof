import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
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
  Directory docsDir;
  try {
    docsDir = await getApplicationDocumentsDirectory();
  } on MissingPluginException {
    docsDir = Directory.systemTemp;
  }
  String appVersion = '0.1.0';
  try {
    final info = await PackageInfo.fromPlatform();
    appVersion = info.version;
  } on MissingPluginException {
    // keep the fallback version
  }

  final state = AppState(
    prefs: prefs,
    docsDir: docsDir.path,
    now: DateTime.now,
    imagePicker: ImagePicker(),
  );
  state.appVersion = appVersion;
  state.load();

  runApp(FloofApp(state: state, window: window));
}
