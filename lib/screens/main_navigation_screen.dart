import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/services/app_state_service.dart';
import '../widgets/active_walk_strip.dart';
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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    AppStateService.instance.refresh();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      AppStateService.instance.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Color get _selectedColor {
    switch (_currentIndex) {
      case 0:
        return AppColors.primary;

      case 1:
        return Colors.green;

      case 2:
        return Colors.deepPurple;

      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ActiveWalkStrip(
            onTap: _openActiveWalk,
          ),

          BottomNavigationBar(
            currentIndex: _currentIndex,
            selectedItemColor: _selectedColor,
            unselectedItemColor: AppColors.textGrey,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.directions_walk_rounded,
                ),
                label: 'Walks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu),
                label: 'Menu',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openActiveWalk() {
    final AppStateService state =
        AppStateService.instance;

    final String? walkId =
        state.activeWalkId;

    if (walkId == null || walkId.isEmpty) {
      return;
    }

    // Active Walk / Live Walk navigation
    // yahan exact existing screen constructor
    // connect karna hai.
  }
}
