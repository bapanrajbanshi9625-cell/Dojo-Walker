import 'package:flutter/material.dart';

import '../colors/dojo_walker_colors.dart';

class DojoBottomNavigation extends StatelessWidget {
  const DojoBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DojoWalkerColors.bottomBar,
        border: Border(
          top: BorderSide(
            color: DojoWalkerColors.bottomBarBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,

          selectedItemColor: DojoWalkerColors.navSelected,
          unselectedItemColor: DojoWalkerColors.navUnselected,

          selectedFontSize: 12,
          unselectedFontSize: 12,

          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),

          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
          ),

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets_outlined),
              activeIcon: Icon(Icons.pets_rounded),
              label: 'Walks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Earnings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
