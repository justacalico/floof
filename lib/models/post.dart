class PostTags {
  final List<String> general;
  final List<String> artist;
  final List<String> contributor;
  final List<String> copyright;
  final List<String> character;
  final List<String> species;
  final List<String> invalid;
  final List<String> meta;
  final List<String> lore;

  const PostTags({
    this.general = const [],
    this.artist = const [],
    this.contributor = const [],
    this.copyright = const [],
    this.character = const [],
    this.species = const [],
    this.invalid = const [],
    this.meta = const [],
    this.lore = const [],
  });

  factory PostTags.fromJson(Map<String, dynamic> json) {
    List<String> list(String key) =>
        (json[key] as List?)?.whereType<String>().toList() ?? const [];
    return PostTags(
      general: list('general'),
      artist: list('artist'),
      contributor: list('contributor'),
      copyright: list('copyright'),
      character: list('character'),
      species: list('species'),
      invalid: list('invalid'),
      meta: list('meta'),
      lore: list('lore'),
    );
  }

  Set<String> get featureSet => {
        for (final t in general) 'g:$t',
        for (final t in artist) 'a:$t',
        for (final t in species) 's:$t',
        for (final t in character) 'c:$t',
        for (final t in copyright) 'p:$t',
        for (final t in meta) 'm:$t',
        for (final t in lore) 'l:$t',
      };

  List<String> get all => [
        ...artist,
        ...character,
        ...species,
        ...general,
        ...copyright,
        ...meta,
      ];
}

class PostFileVariant {
  final String? codec;
  final double? fps;
  final int size;
  final int width;
  final int height;
  final String url;

  const PostFileVariant({
    this.codec,
    this.fps,
    this.size = 0,
    this.width = 0,
    this.height = 0,
    required this.url,
  });

  factory PostFileVariant.fromJson(Map<String, dynamic> json) {
    return PostFileVariant(
      codec: json['codec'] as String?,
      fps: (json['fps'] as num?)?.toDouble(),
      size: (json['size'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      url: json['url'] as String? ?? '',
    );
  }
}

class Post {
  final int id;
  final DateTime? createdAt;
  final String rating;
  final String description;
  final String uploaderName;
  final List<String> sources;
  final PostTags tags;
  final String fileExt;
  final int fileSize;
  final double? duration;
  final int width;
  final int height;
  final String fileUrl;
  final String? previewUrl;
  final String? previewWebp;
  final String? sampleUrl;
  final String? videoUrl;
  final String? videoMp4Url;
  final int scoreUp;
  final int scoreDown;
  final int scoreTotal;
  final int favCount;
  final int commentCount;
  final bool isFavorited;
  final bool deleted;
  final String host;

  const Post({
    required this.id,
    this.createdAt,
    this.rating = 's',
    this.description = '',
    this.uploaderName = '',
    this.sources = const [],
    this.tags = const PostTags(),
    this.fileExt = '',
    this.fileSize = 0,
    this.duration,
    this.width = 0,
    this.height = 0,
    this.fileUrl = '',
    this.previewUrl,
    this.previewWebp,
    this.sampleUrl,
    this.videoUrl,
    this.videoMp4Url,
    this.scoreUp = 0,
    this.scoreDown = 0,
    this.scoreTotal = 0,
    this.favCount = 0,
    this.commentCount = 0,
    this.isFavorited = false,
    this.deleted = false,
    this.host = '',
  });

  static const videoExts = {'webm', 'mp4', 'mov', 'gif', 'avi', 'mkv'};

  bool get isVideo => videoUrl != null || videoExts.contains(fileExt);

  String get key => '$host#$id';

  String get playableUrl => videoMp4Url ?? videoUrl ?? fileUrl;

  String get thumbUrl => previewWebp ?? previewUrl ?? sampleUrl ?? fileUrl;

  String get largeThumbUrl => sampleUrl ?? previewWebp ?? previewUrl ?? fileUrl;

  double get aspectRatio =>
      height > 0 ? width / height : 16 / 9;

  factory Post.fromJson(Map<String, dynamic> json, {String host = ''}) {
    final files = Map<String, dynamic>.from(json['files'] as Map? ?? const {});
    final meta = Map<String, dynamic>.from(files['meta'] as Map? ?? const {});
    final original = Map<String, dynamic>.from(files['original'] as Map? ?? const {});
    final preview = Map<String, dynamic>.from(files['preview'] as Map? ?? const {});
    final sample = Map<String, dynamic>.from(files['sample'] as Map? ?? const {});
    final video = Map<String, dynamic>.from(files['video'] as Map? ?? const {});
    final stats = Map<String, dynamic>.from(json['stats'] as Map? ?? const {});
    final score = Map<String, dynamic>.from(stats['score'] as Map? ?? const {});
    final flags = Map<String, dynamic>.from(json['flags'] as Map? ?? const {});

    String? vUrl;
    String? mp4Url;
    final videoOriginal = (video['original'] is Map ? Map<String, dynamic>.from(video['original']) : null);
    if (videoOriginal != null) {
      vUrl = videoOriginal['url'] as String?;
    }
    final variants = (video['variants'] is Map ? Map<String, dynamic>.from(video['variants']) : null);
    final mp4 = variants?['mp4'] as Map<String, dynamic>?;
    if (mp4 != null) {
      mp4Url = mp4['url'] as String?;
    }

    return Post(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      rating: json['rating'] as String? ?? 's',
      description: json['description'] as String? ?? '',
      uploaderName: json['uploader_name'] as String? ?? '',
      sources:
          (json['sources'] as List?)?.whereType<String>().toList() ?? const [],
      tags: PostTags.fromJson(
          Map<String, dynamic>.from(json['tags'] as Map? ?? const {})),
      fileExt: meta['ext'] as String? ?? '',
      fileSize: (meta['size'] as num?)?.toInt() ?? 0,
      duration: (meta['duration'] as num?)?.toDouble(),
      width: (original['width'] as num?)?.toInt() ?? 0,
      height: (original['height'] as num?)?.toInt() ?? 0,
      fileUrl: original['url'] as String? ?? '',
      previewUrl: preview['jpg'] as String?,
      previewWebp: preview['webp'] as String?,
      sampleUrl: sample['jpg'] as String? ?? sample['webp'] as String?,
      videoUrl: vUrl,
      videoMp4Url: mp4Url,
      scoreUp: (score['up'] as num?)?.toInt() ?? 0,
      scoreDown: (score['down'] as num?)?.toInt() ?? 0,
      scoreTotal: (score['total'] as num?)?.toInt() ?? 0,
      favCount: (stats['fav_count'] as num?)?.toInt() ?? 0,
      commentCount: (stats['comment_count'] as num?)?.toInt() ?? 0,
      isFavorited: stats['is_favorited'] as bool? ?? false,
      deleted: flags['deleted'] as bool? ?? false,
      host: host,
    );
  }

  Map<String, dynamic> toSummary() => {
        'id': id,
        'host': host,
        'thumb': thumbUrl,
        'ext': fileExt,
        'rating': rating,
        'artist': tags.artist.isEmpty ? '' : tags.artist.first,
        'tags': tags.all.take(8).toList(),
        'score': scoreTotal,
        'favs': favCount,
      };
}
