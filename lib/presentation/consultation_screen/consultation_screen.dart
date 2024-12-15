import 'package:flutter/material.dart';
import 'package:mobile_app_klinik/core/app_export.dart';

class ConsultationScreen extends StatelessWidget {
  const ConsultationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      backgroundColor: appTheme.lightGreen,
      
    );
  }

  AppBar appBar() {
    return AppBar(
      title: const Text(
        'Consultation',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: appTheme.lightGreen,
      elevation: 0.0,
      centerTitle: true,
    );
  }
}