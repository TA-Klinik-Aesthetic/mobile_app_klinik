import 'package:flutter/material.dart';
import 'package:mobile_app_klinik/presentation/product_screen/product_initial_page.dart';
import '../../core/app_export.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Hi, ${widget.userName}!",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ), 
        ),  
      ),
      body: 
      SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                "Products",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              height: 300, // Tinggi container promo
              width: double.infinity,
              decoration: BoxDecoration(
                color: appTheme.lightBadge100,
                borderRadius: BorderRadius.circular(24.0), // Radius
              ),
              child: GestureDetector(
                onTap: () {
                },
                child: Center(
                  child: Text(
                    "Product Content",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: appTheme.black900,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 100, // Tinggi container promo
              width: double.infinity,
              decoration: BoxDecoration(
                color: appTheme.lightBadge100,
                borderRadius: BorderRadius.circular(24.0), // Radius
              ),
              child: GestureDetector(
                onTap: () {
                },
                child: Center(
                  child: Text(
                    "Consultation",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: appTheme.black900,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 100, // Tinggi container promo
              width: double.infinity,
              decoration: BoxDecoration(
                color: appTheme.lightBadge100,
                borderRadius: BorderRadius.circular(24.0), // Radius
              ),
              child: GestureDetector(
                onTap: () {
                  onTapProductScreen(context);
                },
                child: Center(
                  child: Text(
                    "Consultation",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: appTheme.black900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  onTapProductScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProductInitialPage(),
      ),
    );
  }
}  
