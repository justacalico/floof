class Version implements Comparable<Version> {
  final int major;
  final int minor;
  final int patch;
  final String prerelease;

  const Version(this.major, this.minor, this.patch, [this.prerelease = '']);

  static Version? tryParse(String raw) {
    var s = raw.trim();
    if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
    final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.\-]+))?$')
        .firstMatch(s);
    if (match == null) return null;
    return Version(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      match.group(4) ?? '',
    );
  }

  bool get isStable => prerelease.isEmpty;

  @override
  int compareTo(Version other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    if (prerelease == other.prerelease) return 0;
    if (prerelease.isEmpty) return 1;
    if (other.prerelease.isEmpty) return -1;
    return prerelease.compareTo(other.prerelease);
  }

  @override
  String toString() =>
      '$major.$minor.$patch${prerelease.isEmpty ? '' : '-$prerelease'}';
}
