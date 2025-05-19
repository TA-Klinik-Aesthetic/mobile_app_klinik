import 'package:flutter/material.dart';
import 'package:mobile_app_klinik/core/app_export.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? namaUser;
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
    _loadUserName(); // Load user name on init
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTimeStr = prefs.getString('login_time');
    final token = prefs.getString('token');

    if (loginTimeStr != null && token != null) {
      final loginTime = DateTime.tryParse(loginTimeStr);
      final now = DateTime.now();

      if (loginTime != null && now.difference(loginTime).inDays < 7) {
        final savedName = prefs.getString('nama_user');
        if (mounted) {
          setState(() {
            namaUser = savedName ?? "Guest";
          });
        }
        return;
      } else {
        await prefs.clear();
      }
    }

    if (mounted) {
      setState(() {
        namaUser = "Guest";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(context),
      items: _navBarsItems(),
      backgroundColor: appTheme.lightGreenOld,
      confineToSafeArea: true,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      navBarStyle: NavBarStyle.style9,
    );
  }

  List<Widget> _buildScreens(BuildContext context) {
    return [
      Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => _mainScreen(),
        ),
      ),
      Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) =>
              AppRoutes.routes[AppRoutes.productScreen]!(context),
        ),
      ),
      Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) =>
              AppRoutes.routes[AppRoutes.bookingScreen]!(context),
        ),
      ),
      Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => AppRoutes.routes[AppRoutes.userScreen]!(context),
        ),
      ),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        title: "Home",
        activeColorPrimary: appTheme.lightBadge100,
        inactiveColorPrimary: appTheme.whiteA700,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.shopping_bag),
        title: "Products",
        activeColorPrimary: appTheme.lightBadge100,
        inactiveColorPrimary: appTheme.whiteA700,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.chat),
        title: "Booking",
        activeColorPrimary: appTheme.lightBadge100,
        inactiveColorPrimary: appTheme.whiteA700,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person),
        title: "User",
        activeColorPrimary: appTheme.lightBadge100,
        inactiveColorPrimary: appTheme.whiteA700,
      ),
    ];
  }

  Widget _mainScreen() {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            if (namaUser == null || namaUser == "Guest") {
              Navigator.pushNamed(context, AppRoutes.loginUserScreen);
            } else {
              Navigator.pushNamed(context, AppRoutes.userScreen);
            }
          },
          child: Text.rich(
            TextSpan(
              children: [
                if (namaUser == null || namaUser == "Guest")
                  const TextSpan(
                    text: "Masuk / Daftar",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  )
                else ...[
                  const TextSpan(
                    text: "Hello, ",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: namaUser,
                    style: TextStyle(
                      color: appTheme.black900,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(
                    text: "!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                "Latest Promo",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: appTheme.lightBadge100,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.productScreen);
                },
                child: const Center(
                  child: Text(
                    "Promo Content",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                "Jadwal Doctor",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              height: 75,
              width: double.infinity,
              decoration: BoxDecoration(
                color: appTheme.lightGreen,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.doctorScheduleScreen);
                },
                child: const Center(
                  child: Text(
                    "Calender Jadwal Dokter",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
