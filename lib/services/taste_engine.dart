import 'dart:math';

import '../models/post.dart';

enum Signal {
  impression,
  quickSkip,
  watchProgress,
  completed,
  liked,
  unliked,
  done,
}

class TasteEngine {
  static const double _minWeight = -6;
  static const double _maxWeight = 6;
  static const double _decayPerDay = 0.985;
  static const int maxSeenRemembered = 4000;

  static const Map<String, double> _groupScale = {
    'a': 1.6,
    'c': 1.5,
    'p': 1.3,
    's': 1.2,
    'g': 1.0,
    'l': 0.6,
    'm': 0.35,
  };

  static const Map<Signal, double> _signalValue = {
    Signal.impression: 0.05,
    Signal.quickSkip: -0.55,
    Signal.watchProgress: 0.30,
    Signal.completed: 0.65,
    Signal.liked: 0.90,
    Signal.unliked: -0.45,
    Signal.done: 1.20,
  };

  Map<String, double> weights;
  final Set<String> seenPostIds;
  double baseline;
  int impressions;
  DateTime lastDecay;
  final Random _random;

  TasteEngine({
    Map<String, double>? weights,
    Set<String>? seenPostIds,
    this.baseline = 0,
    this.impressions = 0,
    DateTime? lastDecay,
    Random? random,
  })  : weights = weights ?? {},
        seenPostIds = seenPostIds ?? {},
        lastDecay = lastDecay ?? DateTime.now(),
        _random = random ?? Random();

  void record(Post post, Signal signal, {double ratio = 1}) {
    applyDecay();
    var engagement = _signalValue[signal] ?? 0;
    if (signal == Signal.watchProgress) {
      engagement = engagement * ratio.clamp(0, 1.5);
    }
    if (signal == Signal.impression) {
      impressions++;
      engagement = engagement * ratio.clamp(0, 1.5);
    }
    _rememberSeen(post.key);

    final delta = engagement - baseline;
    const lr = 0.35;
    for (final feature in post.tags.featureSet) {
      final scale = _groupScale[feature.substring(0, 1)] ?? 1.0;
      final current = weights[feature] ?? 0;
      weights[feature] =
          (current + lr * delta * scale).clamp(_minWeight, _maxWeight);
    }
    baseline += 0.06 * delta;
  }

  void _rememberSeen(String id) {
    if (seenPostIds.length >= maxSeenRemembered && !seenPostIds.contains(id)) {
      final drop = seenPostIds.take(seenPostIds.length - maxSeenRemembered + 1)
          .toList();
      for (final d in drop) {
        seenPostIds.remove(d);
      }
    }
    seenPostIds.add(id);
  }

  void applyDecay([DateTime? now]) {
    final n = now ?? DateTime.now();
    final days = n.difference(lastDecay).inMilliseconds / 86400000;
    if (days <= 0) return;
    final factor = pow(_decayPerDay, days).toDouble();
    weights = weights.map((k, v) => MapEntry(k, v * factor));
    weights.removeWhere((k, v) => v.abs() < 0.001);
    baseline *= factor;
    lastDecay = n;
  }

  double rawAffinity(Post post) {
    var score = 0.0;
    for (final feature in post.tags.featureSet) {
      score += weights[feature] ?? 0;
    }
    final count = post.tags.featureSet.length;
    return count > 0 ? score / sqrt(count) : score;
  }

  double qualityPrior(Post post) {
    final favs = log(1 + max(0, post.favCount)) / log(1 + 500);
    final score = log(1 + max(0, post.scoreTotal)) / log(1 + 400);
    return (0.55 * favs + 0.45 * score) * 0.9;
  }

  double noveltyBonus(Post post) {
    if (seenPostIds.contains(post.key)) return -2.0;
    var bonus = 0.0;
    for (final artist in post.tags.artist) {
      if ((weights['a:$artist'] ?? 0).abs() < 0.01) bonus += 0.08;
    }
    return bonus;
  }

  double score(Post post, {double explore = 0.12}) {
    final jitter = explore * (_random.nextDouble() * 2 - 1);
    return rawAffinity(post) + qualityPrior(post) + noveltyBonus(post) + jitter;
  }

  List<Post> rank(List<Post> candidates, {int limit = 20, double lambda = 0.72, double explore = 0.12}) {
    final pool = candidates.where((p) => !p.deleted).toList();
    final scored = {for (final p in pool) p.id: score(p, explore: explore)};
    final byScore = pool.toList()
      ..sort((a, b) => scored[b.id]!.compareTo(scored[a.id]!));

    final picked = <Post>[];
    while (picked.length < limit && byScore.isNotEmpty) {
      Post? best;
      var bestMmr = -double.infinity;
      for (final p in byScore.take(24)) {
        final relevance = scored[p.id]!;
        var maxSim = 0.0;
        for (final chosen in picked.take(10)) {
          final sim = _jaccard(p.tags.featureSet, chosen.tags.featureSet);
          if (sim > maxSim) maxSim = sim;
        }
        final mmr = lambda * relevance - (1 - lambda) * maxSim * 2;
        if (mmr > bestMmr) {
          bestMmr = mmr;
          best = p;
        }
      }
      if (best == null) break;
      picked.add(best);
      byScore.remove(best);
    }
    return picked;
  }

  double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) return 0;
    var inter = 0;
    for (final x in a) {
      if (b.contains(x)) inter++;
    }
    return inter / (a.length + b.length - inter);
  }

  List<MapEntry<String, double>> topFeatures({int count = 12, bool positive = true}) {
    final entries = weights.entries
        .where((e) => positive ? e.value > 0.05 : e.value < -0.05)
        .toList()
      ..sort((a, b) => positive
          ? b.value.compareTo(a.value)
          : a.value.compareTo(b.value));
    return entries.take(count).toList();
  }

  void reset() {
    weights = {};
    seenPostIds.clear();
    baseline = 0;
    impressions = 0;
    lastDecay = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'weights': weights,
        'seen': seenPostIds.toList(),
        'baseline': baseline,
        'impressions': impressions,
        'lastDecay': lastDecay.toIso8601String(),
      };

  factory TasteEngine.fromJson(Map<String, dynamic> json, {Random? random}) {
    return TasteEngine(
      weights: (json['weights'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
          ) ??
          {},
      seenPostIds: (json['seen'] as List?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      baseline: (json['baseline'] as num?)?.toDouble() ?? 0,
      impressions: (json['impressions'] as num?)?.toInt() ?? 0,
      lastDecay: DateTime.tryParse(json['lastDecay'] as String? ?? ''),
      random: random,
    );
  }
}
