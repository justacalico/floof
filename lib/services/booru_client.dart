import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/post.dart';

class BooruException implements Exception {
  final String message;
  final int? statusCode;
  const BooruException(this.message, [this.statusCode]);

  @override
  String toString() => 'BooruException($statusCode): $message';
}

class TagSuggestion {
  final String name;
  final int postCount;
  const TagSuggestion(this.name, this.postCount);
}

class BooruClient {
  final String baseUrl;
  final String username;
  final String apiKey;
  final http.Client _client;
  final bool _ownsClient;
  final String userAgent;

  BooruClient({
    String baseUrl = 'https://e926.net',
    this.username = '',
    this.apiKey = '',
    http.Client? client,
    this.userAgent = 'floof/0.1 (https://gitlab.com/HttpAnimations/floof)',
  })  : baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _client = client ?? http.Client(),
        _ownsClient = client == null;

  Map<String, String> get _headers {
    final h = <String, String>{'User-Agent': userAgent};
    if (username.isNotEmpty && apiKey.isNotEmpty) {
      h['Authorization'] =
          'Basic ${base64Encode(utf8.encode('$username:$apiKey'))}';
    }
    return h;
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<List<Post>> searchPosts({
    String tags = '',
    int page = 1,
    int limit = 40,
  }) async {
    final uri = _uri('/posts.json', {
      'tags': tags,
      'page': '$page',
      'limit': '$limit',
      'v2': 'true',
      'mode': 'extended',
    });
    final res = await _client.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw BooruException('search failed', res.statusCode);
    }
    final decoded = jsonDecode(res.body);
    final raw = decoded is Map ? decoded['posts'] : decoded;
    final list = raw is List ? raw : null;
    if (list == null) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((j) => Post.fromJson(j, host: baseUrl))
        .toList();
  }

  Future<Post?> getPost(int id) async {
    final res = await _client.get(
      _uri('/posts/$id.json', {'v2': 'true', 'mode': 'extended'}),
      headers: _headers,
    );
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw BooruException('post fetch failed', res.statusCode);
    }
    final decoded = jsonDecode(res.body);
    final postJson = decoded is Map<String, dynamic>
        ? (decoded['post'] as Map<String, dynamic>? ?? decoded)
        : null;
    if (postJson == null) return null;
    return Post.fromJson(postJson, host: baseUrl);
  }

  Future<List<TagSuggestion>> autocomplete(String term, {int limit = 8}) async {
    if (term.trim().isEmpty) return const [];
    final res = await _client.get(
      _uri('/tags.json', {
        'search[name_matches]': '*${term.trim()}*',
        'search[order]': 'count',
        'limit': '$limit',
      }),
      headers: _headers,
    );
    if (res.statusCode != 200) return const [];
    final decoded = jsonDecode(res.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map((j) => TagSuggestion(
              j['name'] as String? ?? '',
              (j['post_count'] as num?)?.toInt() ?? 0,
            ))
        .toList();
  }

  Future<bool> verifyLogin() async {
    final res = await _client.get(
      _uri('/users.json', {'search[name]': username, 'limit': '1'}),
      headers: _headers,
    );
    if (res.statusCode == 401 || res.statusCode == 403) return false;
    if (res.statusCode != 200) {
      throw BooruException('login check failed', res.statusCode);
    }
    final decoded = jsonDecode(res.body);
    return decoded is List && decoded.isNotEmpty;
  }

  Future<void> favorite(int postId) async {
    final res = await _client.post(
      _uri('/favorites.json'),
      headers: _headers,
      body: {'post_id': '$postId'},
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw BooruException('favorite failed', res.statusCode);
    }
  }

  Future<void> unfavorite(int postId) async {
    final res = await _client.delete(
      _uri('/favorites/$postId.json'),
      headers: _headers,
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw BooruException('unfavorite failed', res.statusCode);
    }
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
