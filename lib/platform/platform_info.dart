import 'package:flutter/foundation.dart';

class PlatformInfo {
  static bool? desktopOverride;

  static bool get isDesktop {
    final override = desktopOverride;
    if (override != null) return override;
    if (kIsWeb) return false;
    return {
      TargetPlatform.linux,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }.contains(defaultTargetPlatform);
  }
}
