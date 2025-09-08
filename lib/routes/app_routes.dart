import 'package:flutter/material.dart';
import 'package:mobile_app_klinik/presentation/add_on_screen/onboarding_screen.dart';
import 'package:mobile_app_klinik/presentation/add_on_screen/splash_screen.dart';
import 'package:mobile_app_klinik/presentation/app_navigation_screen/app_navigation_screen.dart';
import 'package:mobile_app_klinik/presentation/authentication_screen/forgot_password_screen.dart';
import 'package:mobile_app_klinik/presentation/authentication_screen/reset_password_screen.dart';
import 'package:mobile_app_klinik/presentation/booking_screen/booking_consultation_screen.dart';
import 'package:mobile_app_klinik/presentation/booking_screen/booking_treatment_screen.dart';
import 'package:mobile_app_klinik/presentation/doctor_schedule_screen/doctor_schedule_screen.dart';
import 'package:mobile_app_klinik/presentation/home_screen/notification_screen.dart';
import 'package:mobile_app_klinik/presentation/authentication_screen/login_user_screen.dart';
import 'package:mobile_app_klinik/presentation/authentication_screen/register_user_screen.dart';
import 'package:mobile_app_klinik/presentation/home_screen/home_screen.dart';
import 'package:mobile_app_klinik/presentation/promo_screen/promo_screen.dart';
import 'package:mobile_app_klinik/presentation/user_screen/favorite_screen.dart';
import 'package:mobile_app_klinik/presentation/user_screen/history_purchase_screen.dart';
import 'package:mobile_app_klinik/presentation/user_screen/history_visit_screen.dart';
import 'package:mobile_app_klinik/presentation/user_screen/user_screen.dart';
import 'package:mobile_app_klinik/presentation/product_screen/product_screen.dart';
import 'package:mobile_app_klinik/presentation/product_screen/product_detail_screen.dart';
import 'package:mobile_app_klinik/presentation/booking_screen/booking_screen.dart';

// ignore_for_file: must_be_immutable
class AppRoutes {
  static const String splashScreen = '/splash_screen';
  static const String onboardingScreen = '/onboarding_screen';
  static const String loginUserScreen = '/login_user_screen';
  static const String registerUserScreen = '/register_user_screen';
  static const String forgotPasswordScreen = '/forgot_password_screen';
  static const String resetPasswordScreen = '/reset_password_screen';
  static const String homeScreen = '/home_screen';
  static const String notificationScreen = '/notification_screen';
  static const String productScreen = '/product_screen';
  static const String productDetailScreen = '/product_detail_screen';
  static const String historyPurchaseScreen = '/history_purchase_screen';
  static const String historyConsultationScreen = '/history_visit_screen';
  static const String doctorScheduleScreen = '/doctor_schedule_screen';
  static const String bookingScreen = '/booking_screen';
  static const String bookingConsultationScreen = '/booking_consultation_screen';
  static const String bookingTreatmentScreen = '/booking_treatment_screen';
  static const String treatmentHistoryScreen = '/treatment_history_screen';
  static const String userScreen = '/user_screen';
  static const String promoScreen = '/promo_screen';
  static const String favoriteUserScreen = '/favorite_screen';
  static const String appNavigationScreen = '/app_navigation_screen';
  static const String initialRoute = '/splash_screen'; // ✅ Fix: Point to splash_screen

  static Map<String, WidgetBuilder> routes = {
    splashScreen: (context) => const SplashScreen(),
    onboardingScreen: (context) => const OnboardingScreen(),
    forgotPasswordScreen: (context) => const ForgotPasswordScreen(),
    resetPasswordScreen: (context) => const ResetPasswordScreen(token: '', email: ''),
    homeScreen: (context) => const HomeScreen(),
    notificationScreen: (context) => const NotificationScreen(),
    loginUserScreen: (context) => const LoginUserScreen(),
    registerUserScreen: (context) => const RegisterUserScreen(),
    productScreen: (context) => const ProductScreen(),
    historyConsultationScreen: (context) => const HistoryVisitScreen(),
    historyPurchaseScreen: (context) => const HistoryPurchaseScreen(),
    promoScreen: (context) => const PromoScreen(),
    doctorScheduleScreen: (context) => const DoctorScheduleScreen(),
    bookingScreen: (context) => const BookingScreen(),
    bookingConsultationScreen: (context) => const BookingConsultationScreen(),
    bookingTreatmentScreen: (context) => const BookingTreatmentScreen(),
    treatmentHistoryScreen: (context) => const HistoryVisitScreen(),
    userScreen: (context) => const UserScreen(),
    favoriteUserScreen: (context) => const FavoriteScreen(),
    appNavigationScreen: (context) => const AppNavigationScreen(),
    // ✅ Remove duplicate initialRoute
  };

  // ✅ ENHANCED onGenerateRoute - Handle all routes properly
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    print('🧭 Generating route for: ${settings.name}');
    
    switch (settings.name) {
      // ✅ Handle ProductDetailScreen with arguments
      case productDetailScreen:
        if (settings.arguments is Map<String, dynamic>) {
          final product = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
            settings: settings,
          );
        }
        return _errorRoute('Product data is required');
        
      // ✅ Handle all static routes
      case splashScreen:
        return MaterialPageRoute(
          builder: routes[splashScreen]!,
          settings: settings,
        );
        
      case onboardingScreen:
        return MaterialPageRoute(
          builder: routes[onboardingScreen]!,
          settings: settings,
        );
        
      case loginUserScreen:
        return MaterialPageRoute(
          builder: routes[loginUserScreen]!,
          settings: settings,
        );
      
      case AppRoutes.forgotPasswordScreen:
        return MaterialPageRoute(builder: (context) => const ForgotPasswordScreen());

      case AppRoutes.resetPasswordScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              token: args['token'] as String?,
              email: args['email'] as String? ?? '',
              fromForgot: args['from_forgot'] as bool? ?? false,
            ),
          );
        }
        // Fallback to login if arguments are missing
        return MaterialPageRoute(
          builder: (context) => const LoginUserScreen(),
        );
        
      case homeScreen:
        return MaterialPageRoute(
          builder: routes[homeScreen]!,
          settings: settings,
        );
        
      case registerUserScreen:
        return MaterialPageRoute(
          builder: routes[registerUserScreen]!,
          settings: settings,
        );
        
      case notificationScreen:
        return MaterialPageRoute(
          builder: routes[notificationScreen]!,
          settings: settings,
        );
        
      case productScreen:
        return MaterialPageRoute(
          builder: routes[productScreen]!,
          settings: settings,
        );
        
      case historyPurchaseScreen:
        return MaterialPageRoute(
          builder: routes[historyPurchaseScreen]!,
          settings: settings,
        );
        
      case historyConsultationScreen:
        return MaterialPageRoute(
          builder: routes[historyConsultationScreen]!,
          settings: settings,
        );
        
      case doctorScheduleScreen:
        return MaterialPageRoute(
          builder: routes[doctorScheduleScreen]!,
          settings: settings,
        );
        
      case bookingScreen:
        return MaterialPageRoute(
          builder: routes[bookingScreen]!,
          settings: settings,
        );
        
      case bookingConsultationScreen:
        return MaterialPageRoute(
          builder: routes[bookingConsultationScreen]!,
          settings: settings,
        );
        
      case bookingTreatmentScreen:
        return MaterialPageRoute(
          builder: routes[bookingTreatmentScreen]!,
          settings: settings,
        );
        
      case treatmentHistoryScreen:
        return MaterialPageRoute(
          builder: routes[treatmentHistoryScreen]!,
          settings: settings,
        );
        
      case userScreen:
        return MaterialPageRoute(
          builder: routes[userScreen]!,
          settings: settings,
        );
        
      case promoScreen:
        return MaterialPageRoute(
          builder: routes[promoScreen]!,
          settings: settings,
        );
        
      case favoriteUserScreen:
        return MaterialPageRoute(
          builder: routes[favoriteUserScreen]!,
          settings: settings,
        );
        
      case appNavigationScreen:
        return MaterialPageRoute(
          builder: routes[appNavigationScreen]!,
          settings: settings,
        );
        
      // ✅ Handle root route
      case '/':
        return MaterialPageRoute(
          builder: routes[splashScreen]!,
          settings: settings,
        );
        
      // ✅ Fallback for unknown routes
      default:
        print('⚠️ Route not found: ${settings.name}');
        return _errorRoute('Route "${settings.name}" not found');
    }
  }

  // ✅ ENHANCED error route with custom message
  static Route<dynamic> _errorRoute([String? message]) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                message ?? 'Page not found',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    splashScreen,
                    (route) => false,
                  );
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ ADD: Helper method for navigation with error handling
  static Future<void> navigateTo(BuildContext context, String routeName, {Object? arguments}) async {
    try {
      await Navigator.of(context).pushNamed(routeName, arguments: arguments);
    } catch (e) {
      print('❌ Navigation error to $routeName: $e');
      // Fallback navigation
      Navigator.of(context).pushNamedAndRemoveUntil(
        splashScreen,
        (route) => false,
      );
    }
  }

  // ✅ ADD: Helper method for replace navigation
  static Future<void> navigateAndReplace(BuildContext context, String routeName, {Object? arguments}) async {
    try {
      await Navigator.of(context).pushReplacementNamed(routeName, arguments: arguments);
    } catch (e) {
      print('❌ Replace navigation error to $routeName: $e');
      Navigator.of(context).pushNamedAndRemoveUntil(
        splashScreen,
        (route) => false,
      );
    }
  }

  // ✅ ADD: Helper method for remove until navigation
  static Future<void> navigateAndRemoveUntil(BuildContext context, String routeName, {Object? arguments}) async {
    try {
      await Navigator.of(context).pushNamedAndRemoveUntil(
        routeName,
        (route) => false,
        arguments: arguments,
      );
    } catch (e) {
      print('❌ Remove until navigation error to $routeName: $e');
      Navigator.of(context).pushNamedAndRemoveUntil(
        splashScreen,
        (route) => false,
      );
    }
  }
}