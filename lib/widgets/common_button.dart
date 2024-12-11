import 'package:flutter/material.dart';
import 'package:mobile_app_klinik/core/app_export.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const CommonButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: appTheme.orange200, // Background color
          borderRadius: BorderRadius.circular(24.0), // Rounded corners
          border: Border.all(color: Colors.black, width: 2), // Outline
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
