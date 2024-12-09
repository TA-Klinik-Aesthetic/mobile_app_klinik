import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class HomeScreen extends StatefulWidget {
  final String userName ; // Nama user

  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hi, ${widget.userName}!"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container utama
            Container(
              height: 300, // Tinggi container
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 32.0),
              decoration: BoxDecoration(
                color: appTheme.lightBadge100,
                borderRadius: BorderRadius.circular(24.0), // Radius
              ),
              child: Center(
                child: Text(
                  "Main Content Here",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: appTheme.darkCherry,
                  ),
                ),
              ),
            ),
            // Latest Promo section
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                "Latest Promo",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              height: 150, // Tinggi container promo
              width: double.infinity,
              decoration: BoxDecoration(
                color: appTheme.lightBadge100,
                borderRadius: BorderRadius.circular(24.0), // Radius
              ),
              child: Center(
                child: Text(
                  "Promo Content Here",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: appTheme.darkCherry,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
