import 'package:flutter/material.dart';

import '../platform/platform_info.dart';
import '../platform/window_ops.dart';
import 'desktop_title_bar.dart';
import 'nav_sidebar.dart';

class AppShell extends StatefulWidget {
  final String title;
  final List<NavDestination> destinations;
  final List<Widget> pages;
  final WindowOps window;

  const AppShell({
    super.key,
    required this.title,
    required this.destinations,
    required this.pages,
    required this.window,
  });

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void select(int i) {
    setState(() => _index = i);
    final scaffold = _scaffoldKey.currentState;
    if (scaffold != null && scaffold.isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = PlatformInfo.isDesktop;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final content = IndexedStack(
          index: _index,
          children: widget.pages,
        );
        if (wide) {
          return Column(
            children: [
              if (desktop)
                DesktopTitleBar(title: widget.title, window: widget.window),
              Expanded(
                child: Row(
                  children: [
                    NavSidebar(
                      selectedIndex: _index,
                      destinations: widget.destinations,
                      onSelect: select,
                    ),
                    Expanded(child: content),
                  ],
                ),
              ),
            ],
          );
        }
        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(title: Text(widget.title)),
          drawer: Drawer(
            width: 260,
            child: NavSidebar(
              selectedIndex: _index,
              destinations: widget.destinations,
              onSelect: select,
            ),
          ),
          body: content,
        );
      },
    );
  }
}
