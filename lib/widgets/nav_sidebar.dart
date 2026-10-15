import 'package:flutter/material.dart';

class NavDestination {
  final IconData icon;
  final String label;
  const NavDestination(this.icon, this.label);
}

class NavSidebar extends StatelessWidget {
  final int selectedIndex;
  final List<NavDestination> destinations;
  final ValueChanged<int> onSelect;
  final Widget? footer;

  const NavSidebar({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onSelect,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 232,
      color: scheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                itemCount: destinations.length,
                itemBuilder: (context, i) {
                  final selected = i == selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Material(
                      color: Colors.transparent,
                      shape: const StadiumBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        dense: true,
                        leading: Icon(destinations[i].icon, size: 20),
                        title: Text(destinations[i].label),
                        selected: selected,
                        selectedTileColor: scheme.secondaryContainer,
                        hoverColor: scheme.surfaceContainerHighest,
                        shape: const StadiumBorder(),
                        onTap: () => onSelect(i),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }
}
