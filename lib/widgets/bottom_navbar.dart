import 'package:flutter/material.dart';
import 'package:mobile_app_klinik/theme/theme_helper.dart';
import '../../core/app_export.dart';

class BottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.selectedIndex,
      onTap: widget.onTap,
      backgroundColor: appTheme.lightBadge100,
      selectedItemColor: appTheme.orange200,
      unselectedItemColor: Colors.white,
      iconSize: 30,
      selectedLabelStyle: const TextStyle(
        fontSize: 14, // Ukuran teks yang dipilih
        height: 1.5,  // Menambah jarak antara icon dan teks
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12, // Ukuran teks yang tidak dipilih
        height: 1.5,  // Menambah jarak antara icon dan teks
      ),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
          activeIcon: Icon(Icons.home),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2),
          label: 'Product',
          activeIcon: Icon(Icons.inventory_2),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Booking',
          activeIcon: Icon(Icons.today),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
          activeIcon: Icon(Icons.person),
        ),
      ],
    );
  }
}
