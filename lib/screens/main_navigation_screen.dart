import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'walker_home_screen.dart';
import 'walks_screen.dart';
import 'menu_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    WalkerHomeScreen(),
    WalksScreen(),
    MenuScreen(),
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
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
            icon: Icon(Icons.directions_walk_rounded),
            label: 'Walks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}
