import 'package:flutter/material.dart';

import '../dojo_walker_colors.dart';

class DojoBottomNavigation
    extends StatelessWidget {
  const DojoBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DojoWalkerColors.white,
        border: Border(
          top: BorderSide(
            color: DojoWalkerColors.border,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor:
            DojoWalkerColors.white,
        indicatorColor:
            DojoWalkerColors.primarySoft,
        elevation: 0,
        height: 70,
        destinations: items
            .map(
              (BottomNavigationBarItem item) {
                return NavigationDestination(
                  icon: item.icon,
                  selectedIcon:
                      item.activeIcon ??
                      item.icon,
                  label: item.label ?? '',
                );
              },
            )
            .toList(),
      ),
    );
  }
}
