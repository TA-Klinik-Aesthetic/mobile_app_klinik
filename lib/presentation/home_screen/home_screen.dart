import 'package:flutter/material.dart';
import 'package:mobile_app_klinik/core/app_export.dart';
import 'package:mobile_app_klinik/presentation/product_screen/product_screen.dart';
import 'package:mobile_app_klinik/widgets/common_button.dart';
import '../consultation_screen/consultation_screen.dart';
import '../treatment_screen/treatment_screen.dart';
import '../user_screen/user_screen.dart';

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
        title: GestureDetector(
          onTap: () {
            onTapUserScreen(context);
          },
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: "Hi, ",
                  style: TextStyle(
                    fontWeight: FontWeight.normal, // Gaya default
                  ),
                ),
                TextSpan(
                  text: widget.userName,
                  style: TextStyle(
                    color: appTheme.lightGreen,
                    fontWeight: FontWeight.bold, // Nama diberi gaya bold
                  ),
                ),
                const TextSpan(
                  text: "!",
                  style: TextStyle(
                    fontWeight: FontWeight.normal, // Gaya default
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
                "Products",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: appTheme.lightBadge100,
                borderRadius: BorderRadius.circular(24.0), // Rounded corners
                border: Border.all(color: Colors.black, width: 2), // Outline
              ),
              child: GestureDetector(
                onTap: () {
                  onTapProductScreen(context);
                },
                child: const Center(
                  child: Text(
                    "Product Content",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.h),
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
                      onTapConsultationScreen(context);
                    },
                  ),
                ),
                const SizedBox(width: 12), // Add spacing between buttons
                Expanded(
                  child: CommonButton(
                    text: "Treatment",
                    onTap: () {
                      onTapTreatmentScreen(context);
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

  onTapUserScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserScreen(),
      ),
    );
  }


  // Navigate to ProductScreen
  onTapProductScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProductScreen(),
      ),
    );
  }

  // Navigate to ConsultationScreen
  onTapConsultationScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConsultationScreen(),
      ),
    );
  }

  // Navigate to TreatmentScreen
  onTapTreatmentScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TreatmentScreen(),
      ),
    );
  }
}
