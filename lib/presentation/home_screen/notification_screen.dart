import 'package:flutter/material.dart';
import 'package:mobile_app_klinik/core/app_export.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: appTheme.black900,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: appTheme.whiteA700,
        elevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'No notifications yet.',
          style: TextStyle(
            color: appTheme.black900,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}