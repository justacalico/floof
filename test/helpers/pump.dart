import 'package:floof/state/app_state.dart';
import 'package:floof/services/version_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'fakes.dart';

export 'fakes.dart';

Future<AppState> makeState({
  Map<String, Object> prefs = const {},
  FakeBooruClient? client,
  bool withImagePicker = false,
  UpdateCheckResult? updateResult,
  DateTime? fixedNow,
  String docsDir = '',
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final fake = client ?? FakeBooruClient();
  final state = AppState(
    prefs: p,
    docsDir: docsDir,
    clientFactory: (a) => fake,
    imagePicker: withImagePicker ? ImagePicker() : null,
    checkerFactory: (v) =>
        FakeVersionChecker(updateResult ?? UpdateCheckResult.upToDate),
    now: () => fixedNow ?? DateTime(2026, 1, 1, 12),
  );
  state.load();
  return state;
}

class PlatformFakes {
  late FakeVideoPlayerPlatform video;
  late FakeImagePickerPlatform imagePicker;
  late FakeUrlLauncherPlatform urlLauncher;

  void install() {
    video = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = video;
    imagePicker = FakeImagePickerPlatform();
    ImagePickerPlatform.instance = imagePicker;
    urlLauncher = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = urlLauncher;
  }
}

void setViewSize(WidgetTester tester, [Size size = const Size(1280, 800)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
