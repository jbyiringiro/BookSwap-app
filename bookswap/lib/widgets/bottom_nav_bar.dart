// lib/widgets/bottom_nav_bar.dart

import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const BottomNavBar({
    super.key,
    required this.selectedIndex
  });

  @override
  Widget build(BuildContext context) {
    // Define the same number of items for all screens
    final List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.book),
        label: 'Browse',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.list),
        label: 'My Listings',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat),
        label: 'Chats',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];

    // Make sure currentIndex is valid
    int validIndex = selectedIndex;
    if (validIndex < 0 || validIndex >= items.length) {
      validIndex = 0; // Default to first item if index is invalid
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: validIndex,
      onTap: (index) {
        // Navigate to different screens based on index
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/mylistings');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/chat');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/profile');
            break;
        }
      },
      items: items,
      selectedItemColor: Colors.white, // Keep selected icon white
      unselectedItemColor: Colors.grey, // Keep unselected icons grey
      backgroundColor: const Color(0xFF12122F),
      elevation: 0,
    );
  }
}