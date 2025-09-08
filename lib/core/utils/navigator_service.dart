import 'package:flutter/material.dart';

class NavigatorService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static Future<dynamic>? pushNamed(String routeName, {dynamic arguments}) {
    try {
      print('🧭 NavigatorService.pushNamed: $routeName');
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        return navigator.pushNamed(routeName, arguments: arguments);
      } else {
        print('❌ Navigator state is null');
        return null;
      }
    } catch (e) {
      print('❌ Error in pushNamed: $e');
      return null;
    }
  }

  static Future<dynamic>? pushNamedAndRemoveUntil(String routeName, {dynamic arguments}) {
    try {
      print('🧭 NavigatorService.pushNamedAndRemoveUntil: $routeName');
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        return navigator.pushNamedAndRemoveUntil(
          routeName,
          (route) => false,
          arguments: arguments,
        );
      } else {
        print('❌ Navigator state is null');
        return null;
      }
    } catch (e) {
      print('❌ Error in pushNamedAndRemoveUntil: $e');
      return null;
    }
  }

  static void goBack() {
    try {
      print('🔙 NavigatorService.goBack');
      final navigator = navigatorKey.currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.pop();
      } else {
        print('❌ Cannot go back - navigator is null or cannot pop');
      }
    } catch (e) {
      print('❌ Error in goBack: $e');
    }
  }

  static Future<dynamic>? pushReplacementNamed(String routeName, {dynamic arguments}) {
    try {
      print('🧭 NavigatorService.pushReplacementNamed: $routeName');
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        return navigator.pushReplacementNamed(routeName, arguments: arguments);
      } else {
        print('❌ Navigator state is null');
        return null;
      }
    } catch (e) {
      print('❌ Error in pushReplacementNamed: $e');
      return null;
    }
  }
}