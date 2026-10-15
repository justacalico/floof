class HistoryEntry {
  final int postId;
  final String host;
  final DateTime watchedAt;
  final double watchSeconds;
  final double? durationSeconds;
  final bool completed;
  final Map<String, dynamic> postSummary;

  const HistoryEntry({
    required this.postId,
    required this.host,
    required this.watchedAt,
    this.watchSeconds = 0,
    this.durationSeconds,
    this.completed = false,
    this.postSummary = const {},
  });

  double get watchRatio {
    final d = durationSeconds;
    if (d == null || d <= 0) return 0;
    return (watchSeconds / d).clamp(0, 1);
  }

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'host': host,
        'watchedAt': watchedAt.toIso8601String(),
        'watchSeconds': watchSeconds,
        'durationSeconds': durationSeconds,
        'completed': completed,
        'postSummary': postSummary,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        postId: (json['postId'] as num?)?.toInt() ?? 0,
        host: json['host'] as String? ?? '',
        watchedAt: DateTime.tryParse(json['watchedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        watchSeconds: (json['watchSeconds'] as num?)?.toDouble() ?? 0,
        durationSeconds: (json['durationSeconds'] as num?)?.toDouble(),
        completed: json['completed'] as bool? ?? false,
        postSummary:
            Map<String, dynamic>.from(json['postSummary'] as Map? ?? {}),
      );
}

class DoneEntry {
  final int postId;
  final String host;
  final DateTime doneAt;
  final String? photoPath;
  final Map<String, dynamic> postSummary;

  const DoneEntry({
    required this.postId,
    required this.host,
    required this.doneAt,
    this.photoPath,
    this.postSummary = const {},
  });

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'host': host,
        'doneAt': doneAt.toIso8601String(),
        'photoPath': photoPath,
        'postSummary': postSummary,
      };

  factory DoneEntry.fromJson(Map<String, dynamic> json) => DoneEntry(
        postId: (json['postId'] as num?)?.toInt() ?? 0,
        host: json['host'] as String? ?? '',
        doneAt: DateTime.tryParse(json['doneAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        photoPath: json['photoPath'] as String?,
        postSummary:
            Map<String, dynamic>.from(json['postSummary'] as Map? ?? {}),
      );
}
