import 'package:flutter/material.dart';
import '../presentation/app_navigation_screen/app_navigation_screen.dart';
import '../presentation/login_user_screen/login_user_screen.dart';
import '../presentation/register_user_screen/register_user_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/product_screen/product_screen.dart';
import '../presentation/product_screen/product_detail_screen.dart';

// ignore_for_file: must_be_immutable
class AppRoutes {
  static const String loginUserScreen = '/login_user_screen';

  static const String registerUserScreen = '/register_user_screen';

  static const String homeScreen = '/home_screen';

  static const String productScreen = '/product_screen';

  static const String productDetailScreen = '/product_detail_screen';

  static const String appNavigationScreen = '/app_navigation_screen';

  static const String initialRoute = '/initialRoute';

  static Map<String, WidgetBuilder> routes = {
    loginUserScreen: (context) => const LoginUserScreen(),
    registerUserScreen: (context) => const RegisterUserScreen(),
    homeScreen: (context) => const HomeScreen(),
    productScreen: (context) => const ProductScreen(),
    appNavigationScreen: (context) => const AppNavigationScreen(),
    initialRoute: (context) => const HomeScreen(),
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
