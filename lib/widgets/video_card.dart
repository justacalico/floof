import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_localizations.dart';
import '../models/post.dart';
import '../state/app_state.dart';
import 'done_sheet.dart';

class VideoCard extends StatefulWidget {
  final Post post;
  final AppState state;
  final bool autofocus;

  const VideoCard({
    super.key,
    required this.post,
    required this.state,
    this.autofocus = false,
  });

  @override
  State<VideoCard> createState() => VideoCardState();
}

class VideoCardState extends State<VideoCard> {
  VideoPlayerController? _controller;
  bool _initStarted = false;
  bool _initFailed = false;
  final _watch = Stopwatch()..start();
  double get _watchedSeconds => _watch.elapsedMilliseconds / 1000;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) _startPlayback();
  }

  Future<void> _startPlayback() async {
    if (_initStarted) return;
    _initStarted = true;
    _watch.reset();
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.post.playableUrl),
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      controller.setLooping(true);
      await controller.play();
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _initFailed = true);
    }
  }

  void reportWatch({double? duration}) {
    if (_reported) return;
    _reported = true;
    _report(duration);
  }

  void _report(double? duration) {
    final d = duration ??
        _controller?.value.duration.inSeconds.toDouble() ??
        widget.post.duration;
    final completed =
        d != null && d > 0 && _watchedSeconds >= d * 0.9;
    widget.state.recordWatch(
      widget.post,
      _watchedSeconds,
      d,
      completed,
    );
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
      _watch.stop();
    } else {
      c.play();
      _watch.start();
    }
    setState(() {});
  }

  Future<void> _markDone() async {
    final choice = await showModalBottomSheet<DoneChoice>(
      context: context,
      builder: (context) => const DoneSheet(),
    );
    if (choice == null || !mounted) return;
    await widget.state.markDone(widget.post, skipPhoto: choice == DoneChoice.skip);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.doneRecorded)),
      );
    }
  }

  @override
  void dispose() {
    if (!_reported) {
      _reported = true;
      final state = widget.state;
      final post = widget.post;
      final watched = _watchedSeconds;
      final d = _controller?.value.duration.inSeconds.toDouble() ??
          widget.post.duration;
      final completed = d != null && d > 0 && watched >= d * 0.9;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.recordWatch(post, watched, d, completed);
      });
    }
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) => _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final post = widget.post;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildVideoArea(scheme)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    widget.state.isLiked(post)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: widget.state.isLiked(post) ? Colors.red : null,
                  ),
                  tooltip: l10n.like,
                  onPressed: () => widget.state.toggleLike(post),
                ),
                IconButton(
                  icon: Icon(
                    widget.state.isDone(post.id)
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color:
                        widget.state.isDone(post.id) ? Colors.green : null,
                  ),
                  tooltip: l10n.done,
                  onPressed: _markDone,
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 20),
                  tooltip: l10n.openPost,
                  onPressed: () => launchUrl(
                    Uri.parse('${post.host}/posts/${post.id}'),
                  ),
                ),
                const Spacer(),
                Text(
                  '+${post.scoreTotal}  ·  ${post.favCount} fav',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (post.tags.artist.isNotEmpty || post.tags.species.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final t in [...post.tags.artist, ...post.tags.species])
                    Chip(
                      label: Text(t),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoArea(ColorScheme scheme) {
    final c = _controller;
    if (c != null) {
      return GestureDetector(
        onTap: _togglePlay,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: c.value.aspectRatio,
                child: VideoPlayer(c),
              ),
            ),
            if (!c.value.isPlaying)
              const Center(
                child: Icon(Icons.play_circle_fill,
                    size: 64, color: Colors.white70),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(c, allowScrubbing: true),
            ),
          ],
        ),
      );
    }
    return InkWell(
      onTap: _initFailed ? () {} : _startPlayback,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.post.largeThumbUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => Container(
              color: scheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image, size: 48),
            ),
          ),
          if (_initStarted && !_initFailed)
            const Center(child: CircularProgressIndicator())
          else
            Center(
              child: Icon(
                _initFailed ? Icons.error_outline : Icons.play_circle_fill,
                size: 64,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }
}
