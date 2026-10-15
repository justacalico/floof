import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../widgets/video_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final _controller = PageController();
  final Map<int, GlobalKey<VideoCardState>> _cardKeys = {};
  int _currentIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.feedPosts.isEmpty) state.loadMoreFeed();
    });
  }

  GlobalKey<VideoCardState> _keyFor(int index) =>
      _cardKeys.putIfAbsent(index, () => GlobalKey<VideoCardState>());

  void _onPageChanged(int index) {
    if (_currentIndex >= 0 && _currentIndex != index) {
      _cardKeys[_currentIndex]?.currentState?.reportWatch();
    }
    _currentIndex = index;
    final state = context.read<AppState>();
    if (index >= state.feedPosts.length - 3) {
      state.loadMoreFeed();
    }
  }

  @override
  void dispose() {
    if (_currentIndex >= 0) {
      _cardKeys[_currentIndex]?.currentState?.reportWatch();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.feedPosts.isEmpty) {
          if (state.feedLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.feedError != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.feedError),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: state.refreshFeed,
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }
          return Center(child: Text(l10n.feedEmpty));
        }
        return PageView.builder(
          controller: _controller,
          scrollDirection: Axis.vertical,
          onPageChanged: _onPageChanged,
          itemCount: state.feedPosts.length,
          itemBuilder: (context, index) {
            final post = state.feedPosts[index];
            return Padding(
              padding: const EdgeInsets.all(6),
              child: VideoCard(
                key: _keyFor(index),
                post: post,
                state: state,
              ),
            );
          },
        );
      },
    );
  }
}
