import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/post.dart';
import '../services/booru_client.dart';
import '../state/app_state.dart';
import 'viewer_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final _field = TextEditingController();
  Timer? _debounce;
  List<TagSuggestion> _suggestions = [];
  List<Post> _results = [];
  bool _loading = false;
  bool _searched = false;
  String _query = '';
  int _page = 1;
  bool _hasMore = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _field.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final term = _field.text.trim();
      if (term.isEmpty) {
        if (mounted) setState(() => _suggestions = []);
        return;
      }
      try {
        final suggestions =
            await context.read<AppState>().client.autocomplete(term);
        if (mounted && _field.text.trim() == term) {
          setState(() => _suggestions = suggestions);
        }
      } catch (_) {
        if (mounted) setState(() => _suggestions = []);
      }
    });
  }

  Future<void> _search(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _suggestions = [];
      _query = query.trim();
    });
    try {
      final state = context.read<AppState>();
      final tags = state.ratingFilter.isEmpty
          ? '$query type:webm'
          : '$query type:webm ${state.ratingFilter}';
      final posts =
          await state.client.searchPosts(tags: tags, page: page, limit: 40);
      if (!mounted) return;
      setState(() {
        _page = page;
        _hasMore = posts.isNotEmpty;
        _loading = false;
        _searched = true;
        if (page == 1) {
          _results = posts;
        } else {
          _results = [..._results, ...posts];
        }
      });
    } on BooruException {
      if (mounted) {
        setState(() {
          _loading = false;
          _searched = true;
          _results = [];
          _hasMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            controller: _field,
            onChanged: _onChanged,
            onSubmitted: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _field.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _field.clear();
                        setState(() {
                          _suggestions = [];
                          _results = [];
                          _searched = false;
                        });
                      },
                    ),
            ),
          ),
        ),
        if (_suggestions.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final s in _suggestions)
                  ListTile(
                    dense: true,
                    title: Text(s.name),
                    trailing: Text('${s.postCount}'),
                    onTap: () {
                      _field.text = s.name;
                      _search(s.name);
                    },
                  ),
              ],
            ),
          ),
        Expanded(child: _buildResults(l10n)),
      ],
    );
  }

  Widget _buildResults(AppLocalizations l10n) {
    if (_loading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searched && _results.isEmpty) {
      return Center(child: Text(l10n.searchEmpty));
    }
    if (_results.isEmpty) {
      return Center(child: Text(l10n.searchHint));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _results.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _results.length) {
          _search(_query, page: _page + 1);
          return const Center(child: CircularProgressIndicator());
        }
        final post = _results[index];
        return _ResultTile(post: post);
      },
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Post post;
  const _ResultTile({required this.post});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ViewerPage(post: post),
        ),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              post.thumbUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image),
              ),
            ),
            if (post.duration != null)
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(post.duration!),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(double seconds) {
    final d = Duration(seconds: seconds.round());
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
