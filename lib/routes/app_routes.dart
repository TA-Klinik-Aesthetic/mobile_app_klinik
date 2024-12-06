import 'package:flutter/material.dart';
import '../presentation/app_navigation_screen/app_navigation_screen.dart';
import '../presentation/login_user_screen/login_user_screen.dart';
import '../presentation/register_user_screen/register_user_screen.dart';

// ignore_for_file: must_be_immutable
class AppRoutes {
  static const String loginUserScreen = '/login_user_screen';

  static const String registerUserScreen = '/register_user_screen';

  static const String appNavigationScreen = '/app_navigation_screen';

  static const String initialRoute = '/initialRoute';

  static Map<String, WidgetBuilder> routes = {
    loginUserScreen: (context) => LoginUserScreen(),
    registerUserScreen: (context) => RegisterUserScreen(),
    appNavigationScreen: (context) => AppNavigationScreen(),
    initialRoute: (context) => LoginUserScreen()
  };
}
