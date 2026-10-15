import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../platform/window_ops.dart';

class DesktopTitleBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final WindowOps window;

  const DesktopTitleBar({super.key, required this.title, required this.window});

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: SizedBox(
        height: preferredSize.height,
        child: Row(
          children: [
            const SizedBox(width: 10),
            _TrafficButton(
              color: const Color(0xFFff5f57),
              glyph: Icons.close,
              onTap: window.close,
            ),
            _TrafficButton(
              color: const Color(0xFFfebc2e),
              glyph: Icons.remove,
              onTap: window.minimize,
            ),
            _TrafficButton(
              color: const Color(0xFF28c840),
              glyph: Icons.add,
              onTap: window.maximizeOrRestore,
            ),
            Expanded(
              child: GestureDetector(
                onDoubleTap: window.maximizeOrRestore,
                child: DragToMoveArea(
                  child: Center(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 74),
          ],
        ),
      ),
    );
  }
}

class _TrafficButton extends StatefulWidget {
  final Color color;
  final IconData glyph;
  final Future<void> Function() onTap;

  const _TrafficButton({
    required this.color,
    required this.glyph,
    required this.onTap,
  });

  @override
  State<_TrafficButton> createState() => _TrafficButtonState();
}

class _TrafficButtonState extends State<_TrafficButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration:
              BoxDecoration(color: widget.color, shape: BoxShape.circle),
          child: _hover
              ? Icon(widget.glyph, size: 10, color: Colors.black54)
              : null,
        ),
      ),
    );
  }
}
