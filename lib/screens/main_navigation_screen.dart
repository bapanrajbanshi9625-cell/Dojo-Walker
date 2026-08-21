// File location: lib/screens/main_navigation_screen.dart

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/services/app_state_service.dart';
import 'walker_home_screen.dart';
import 'walks_screen.dart';
import 'menu_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
  });

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    WalkerHomeScreen(),
    WalksScreen(),
    MenuScreen(),
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // ----------------------------------------------------------
    // Recover current Firebase state when navigation screen
    // is opened.
    // ----------------------------------------------------------

    AppStateService.instance.refresh();
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    super.didChangeAppLifecycleState(state);

    // ----------------------------------------------------------
    // App वापस foreground में आने पर Firebase state refresh.
    // ----------------------------------------------------------

    if (state == AppLifecycleState.resumed) {
      AppStateService.instance.refresh();
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  // ============================================================
  // SELECTED COLOR
  // ============================================================

  Color get _selectedColor {
    switch (_currentIndex) {
      case 0:
        return AppColors.primary; // Home - Orange

      case 1:
        return Colors.green; // Walks - Green

      case 2:
        return Colors.deepPurple; // Menu - Purple

      default:
        return AppColors.primary;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: _screens[_currentIndex],

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: _currentIndex,

        selectedItemColor:
            _selectedColor,

        unselectedItemColor:
            AppColors.textGrey,

        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
            ),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.directions_walk_rounded,
            ),
            label: 'Walks',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.menu,
            ),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}
