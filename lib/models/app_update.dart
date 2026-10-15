import '../utils/version_utils.dart';

class AppUpdate {
  final Version version;
  final String tag;
  final String releaseUrl;

  const AppUpdate({
    required this.version,
    required this.tag,
    required this.releaseUrl,
  });
}
