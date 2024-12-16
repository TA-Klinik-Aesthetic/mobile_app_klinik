import 'package:flutter/material.dart';
import 'package:mobile_app_klinik/core/app_export.dart';
import 'package:mobile_app_klinik/presentation/doctor_schedule_screen/doctor_schedule_screen.dart';
import 'package:mobile_app_klinik/presentation/product_screen/product_screen.dart';
import 'package:mobile_app_klinik/widgets/common_button.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../consultation_screen/consultation_screen.dart';
import '../treatment_screen/treatment_screen.dart';
import '../user_screen/user_screen.dart';

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
    _loadUserName(); // Load userName when screen is initialized
  }

  // Function to load the userName from SharedPreferences
  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      namaUser = prefs.getString('nama_user') ?? "Guest";
    });
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      backgroundColor: appTheme.lightBadge100,
      confineToSafeArea: true,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      navBarStyle: NavBarStyle.style13, // Choose the style you prefer
    );
  }

  List<Widget> _buildScreens() {
    return [
      _mainScreen(),
      const ProductScreen(),
      const ConsultationScreen(),
      const TreatmentScreen(),
      const UserScreen(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        title: "Home",
        activeColorPrimary: appTheme.orange200,
        inactiveColorPrimary: appTheme.lightGrey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.shopping_bag),
        title: "Products",
        activeColorPrimary: appTheme.orange200,
        inactiveColorPrimary: appTheme.lightGrey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.chat),
        title: "Consultation",
        activeColorPrimary: appTheme.orange200,
        inactiveColorPrimary: appTheme.lightGrey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.vaccines),
        title: "Treatment",
        activeColorPrimary: appTheme.orange200,
        inactiveColorPrimary: appTheme.lightGrey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person),
        title: "User",
        activeColorPrimary: appTheme.orange200,
        inactiveColorPrimary: appTheme.lightGrey,
      ),
    ];
  }

  Widget _mainScreen() {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserScreen(),
              ),
            );
          },
          child: Text.rich(
            TextSpan(
              children: [
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
                    color: appTheme.orange200,
                    fontSize: 24,
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
                "Promo for you",
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
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductScreen(),
                    ),
                  );
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoctorScheduleScreen(),
                    ),
                  );
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                "Booking",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CommonButton(
                    text: "Consultation",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConsultationScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CommonButton(
                    text: "Treatment",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TreatmentScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
