import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';

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
        title: Text("Hi, ${widget.userName}!"),
      ),
      body: 
      SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
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
                    color: appTheme.black900,
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
              child: GestureDetector(
                onTap: () {
                  onTapPromo(context);
                },
                child: Center(
                  child: Text(
                    "Promo Content Here",
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
      bottomNavigationBar: SizedBox(
        width: double.maxFinite,
        child: _buildBottomBar(context),
      ),
    );
  }

  /// Build Bottom Navigation Bar
  Widget _buildBottomBar(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: CustomBottomBar(
        onChanged: (BottomBarEnum type) {
          Navigator.pushNamed(
              navigatorKey.currentContext!, getCurrentRoute(type));
        },
      ),
    );
  }
  
  /// Handling route based on bottom navigation click actions
  String getCurrentRoute(BottomBarEnum type) {
    switch (type) {
      case BottomBarEnum.Home:
        return AppRoutes.homeScreen;
      case BottomBarEnum.Product:
        return AppRoutes.productInitialPage;
      case BottomBarEnum.Booking:
        return "/";
      case BottomBarEnum.Profile:
        return "/";
      default:
        return "/";
    }
  }

  void onTapPromo(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.promoScreen, // Pastikan rute ini didefinisikan di AppRoutes
    );
  }


  /// Handling page rendering based on current route
  Widget getCurrentPage(BuildContext context, String currentRoute) {
    switch (currentRoute) {
      case AppRoutes.homeScreen:
        return const HomeScreen(userName: 'Samuel Ezra');
      default:
        return const DefaultWidget();
    }
  }
}  
