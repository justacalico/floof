class BooruHost {
  final String name;
  final String baseUrl;

  const BooruHost(this.name, this.baseUrl);

  static const e926 = BooruHost('e926', 'https://e926.net');
  static const e621 = BooruHost('e621', 'https://e621.net');

  static const known = [e926, e621];

  static BooruHost? find(String baseUrl) {
    for (final h in known) {
      if (h.baseUrl == baseUrl) return h;
    }
    return null;
  }
}

class Account {
  final String id;
  final String username;
  final String apiKey;
  final String hostBaseUrl;
  final bool guest;

  const Account({
    required this.id,
    this.username = '',
    this.apiKey = '',
    this.hostBaseUrl = 'https://e926.net',
    this.guest = true,
  });

  factory Account.guest([String hostBaseUrl = 'https://e926.net']) {
    final host =
        BooruHost.find(hostBaseUrl) ?? BooruHost(hostBaseUrl, hostBaseUrl);
    return Account(
      id: 'guest-${host.baseUrl}',
      username: 'guest',
      hostBaseUrl: host.baseUrl,
      guest: true,
    );
  }

  String get hostLabel => BooruHost.find(hostBaseUrl)?.name ?? hostBaseUrl;

  String get displayName => guest ? 'Guest ($hostLabel)' : username;

  bool get canFavorite => !guest;

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'apiKey': apiKey,
        'hostBaseUrl': hostBaseUrl,
        'guest': guest,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        apiKey: json['apiKey'] as String? ?? '',
        hostBaseUrl: json['hostBaseUrl'] as String? ?? BooruHost.e926.baseUrl,
        guest: json['guest'] as bool? ?? true,
      );
}
