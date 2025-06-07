import 'package:flutter/material.dart';
import 'package:mobile_app_klinik/presentation/app_navigation_screen/app_navigation_screen.dart';
import 'package:mobile_app_klinik/presentation/booking_screen/booking_consultation_screen.dart';
import 'package:mobile_app_klinik/presentation/booking_screen/booking_treatment_screen.dart';
import 'package:mobile_app_klinik/presentation/doctor_schedule_screen/doctor_schedule_screen.dart';
import 'package:mobile_app_klinik/presentation/home_screen/notification_screen.dart';
import 'package:mobile_app_klinik/presentation/login_user_screen/login_user_screen.dart';
import 'package:mobile_app_klinik/presentation/promo_screen/promo_screen.dart';
import 'package:mobile_app_klinik/presentation/register_user_screen/register_user_screen.dart';
import 'package:mobile_app_klinik/presentation/home_screen/home_screen.dart';
import 'package:mobile_app_klinik/presentation/user_screen/history_purchase_screen.dart';
import 'package:mobile_app_klinik/presentation/user_screen/user_screen.dart';
import 'package:mobile_app_klinik/presentation/product_screen/product_screen.dart';
import 'package:mobile_app_klinik/presentation/product_screen/product_detail_screen.dart';
import 'package:mobile_app_klinik/presentation/booking_screen/booking_screen.dart';

// ignore_for_file: must_be_immutable
class AppRoutes {
  static const String loginUserScreen = '/login_user_screen';
  static const String registerUserScreen = '/register_user_screen';
  static const String homeScreen = '/home_screen';
  static const String notificationScreen = '/notification_screen';
  static const String productScreen = '/product_screen';
  static const String productDetailScreen = '/product_detail_screen';
  static const String historyPurchaseScreen = '/history_purchase_screen';
  static const String doctorScheduleScreen = '/doctor_schedule_screen';
  static const String bookingScreen = '/booking_screen';
  static const String bookingConsultationScreen = '/booking_consultation_screen';
  static const String bookingTreatmentScreen = '/booking_treatment_screen';
  static const String userScreen = '/user_screen';
  static const String promoScreen = '/promo_screen';
  static const String appNavigationScreen = '/app_navigation_screen';
  static const String initialRoute = '/initialRoute';

  static Map<String, WidgetBuilder> routes = {
    homeScreen: (context) => const HomeScreen(),
    notificationScreen: (context) => const NotificationScreen(),
    loginUserScreen: (context) => const LoginUserScreen(),
    registerUserScreen: (context) => const RegisterUserScreen(),
    productScreen: (context) => const ProductScreen(),
    historyPurchaseScreen: (context) => const HistoryPurchaseScreen(),
    promoScreen: (context) => const PromoScreen(),
    doctorScheduleScreen: (context) => const DoctorScheduleScreen(),
    bookingScreen: (context) => const BookingScreen(),
    bookingConsultationScreen: (context) => const BookingConsultationScreen(),
    bookingTreatmentScreen: (context) => const BookingTreatmentScreen(),
    userScreen: (context) => const UserScreen(),
    appNavigationScreen: (context) => const AppNavigationScreen(),
    initialRoute: (context) => const LoginUserScreen(),

  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case productDetailScreen:
        if (settings.arguments is Map<String, dynamic>) {
          final product = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          );
        }
        return _errorRoute();
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Page not found'),
        ),
      ),
    );
  }
}
