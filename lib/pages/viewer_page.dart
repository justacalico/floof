import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../state/app_state.dart';
import '../widgets/video_card.dart';

class ViewerPage extends StatelessWidget {
  final Post post;
  const ViewerPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text('#${post.id}')),
      body: Padding(
        padding: const EdgeInsets.all(6),
        child: VideoCard(post: post, state: state, autofocus: true),
      ),
    );
  }
}
