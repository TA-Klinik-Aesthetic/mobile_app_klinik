import 'package:flutter/material.dart';
import '../presentation/app_navigation_screen/app_navigation_screen.dart';
import '../presentation/login_user_screen/login_user_screen.dart';
import '../presentation/register_user_screen/register_user_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/product_screen/product_screen.dart';
import '../presentation/product_detail_screen/product_detail_screen.dart';
import '../presentation/promo_screen/promo_screen.dart';

// ignore_for_file: must_be_immutable
class AppRoutes {
  static const String loginUserScreen = '/login_user_screen';

  static const String registerUserScreen = '/register_user_screen';

  static const String homeScreen = '/homeScreen';

  static const String productScreen = '/product_screen';

  static const String productInitialPage = '/product_initial_page';

  static const String productDetailScreen = '/product_detail_screen';

  static const String promoScreen = '/promo_screen';

  static const String appNavigationScreen = '/app_navigation_screen';

  static const String initialRoute = '/initialRoute';

  static Map<String, WidgetBuilder> routes = {
    loginUserScreen: (context) => const LoginUserScreen(),
    registerUserScreen: (context) => const RegisterUserScreen(),
    homeScreen: (context) => const HomeScreen(userName: 'Samuel Ezra'),
    productScreen: (context) => const ProductScreen(),
    productDetailScreen: (context) => const ProductDetailScreen(),
    promoScreen: (context) => const PromoScreen(),
    appNavigationScreen: (context) => const AppNavigationScreen(),
    initialRoute: (context) => const LoginUserScreen()
  };
}
