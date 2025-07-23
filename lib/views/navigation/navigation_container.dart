// FILE: views/navigation/navigation_container.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../side_table/side_table_screen.dart';
import '../vent_corner/vent_corner_screen.dart';
import '../profile/profile_screen.dart';

class NavigationContainer extends StatefulWidget {
  const NavigationContainer({super.key});

  @override
  State<NavigationContainer> createState() => _NavigationContainerState();
}

class _NavigationContainerState extends State<NavigationContainer> {
  // Default to the middle tab (Side Table) when the app opens
  int _selectedIndex = 1;

  // Re-ordered the list of pages to match the new navigation bar layout
  static const List<Widget> _pages = <Widget>[
    VentCornerScreen(),
    SideTableScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    // Add haptic feedback for a more premium feel
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      // To remove the splash effect, we wrap the BottomNavigationBar
      // with a Theme widget and override the splash/highlight colors.
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          // Re-ordered the navigation items
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: const Icon(Icons.chat_bubble_rounded),
              label: 'Vent Corner',
            ),
            // The new middle item with a table icon
            BottomNavigationBarItem(
              icon: const Icon(Icons.table_restaurant_outlined),
              activeIcon: const Icon(Icons.table_restaurant),
              label: 'Side Table',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: const Color(0xFF0A0A0A),
          // This type prevents the "spreading" animation and keeps items fixed
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[700],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          elevation: 0, // Clean, modern look with no shadow
          iconSize: 28,
        ),
      ),
    );
  }
}
