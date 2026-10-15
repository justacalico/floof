import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_update.dart';
import '../utils/version_utils.dart';

class VersionChecker {
  static const projectPath = 'HttpAnimations/floof';
  static const apiBase = 'https://gitlab.com/api/v4';
  static const releasesPage = 'https://gitlab.com/$projectPath/-/releases';

  final http.Client _client;
  final String currentVersion;

  VersionChecker({required this.currentVersion, http.Client? client})
      : _client = client ?? http.Client();

  Future<AppUpdate?> latestRelease() async {
    final encoded = Uri.encodeComponent(projectPath);
    var page = 1;
    AppUpdate? best;
    while (page <= 5) {
      final res = await _client.get(Uri.parse(
          '$apiBase/projects/$encoded/releases?per_page=100&order_by=released_at&sort=desc&page=$page'));
      if (res.statusCode != 200) {
        throw VersionCheckException(res.statusCode);
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! List || decoded.isEmpty) break;
      for (final r in decoded.whereType<Map<String, dynamic>>()) {
        final tag = r['tag_name'] as String? ?? '';
        final version = Version.tryParse(tag);
        if (version == null) continue;
        if (best == null || version.compareTo(best.version) > 0) {
          best = AppUpdate(
            version: version,
            tag: tag,
            releaseUrl: '$releasesPage/$tag',
          );
        }
      }
      if (decoded.length < 100) break;
      page++;
    }
    return best;
  }

  Future<UpdateCheckResult> check() async {
    try {
      final latest = await latestRelease();
      if (latest == null) return UpdateCheckResult.none;
      final current = Version.tryParse(currentVersion);
      if (current != null && latest.version.compareTo(current) > 0) {
        return UpdateCheckResult(latest);
      }
      return UpdateCheckResult.upToDate;
    } on VersionCheckException {
      return UpdateCheckResult.failed;
    } on FormatException {
      return UpdateCheckResult.failed;
    }
  }
}

class VersionCheckException implements Exception {
  final int statusCode;
  const VersionCheckException(this.statusCode);
}

class UpdateCheckResult {
  static const none = UpdateCheckResult._(UpdateCheckStatus.none);
  static const upToDate = UpdateCheckResult._(UpdateCheckStatus.upToDate);
  static const failed = UpdateCheckResult._(UpdateCheckStatus.failed);

  final UpdateCheckStatus status;
  final AppUpdate? update;

  const UpdateCheckResult._(this.status) : update = null;
  const UpdateCheckResult(AppUpdate u)
      : status = UpdateCheckStatus.available,
        update = u;
}

enum UpdateCheckStatus { none, upToDate, available, failed }
