import 'package:flutter/material.dart';
import '../core/app_export.dart';

class AppDecoration {
  // Darker decorations
  static BoxDecoration get darkerBadge => BoxDecoration(
        color: appTheme.orange200,
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 1.h,
        ),
      );
// Fill decorations
  static BoxDecoration get fillBlueGray => BoxDecoration(
        color: appTheme.blueGray100,
      );
  static BoxDecoration get fillWhiteA => BoxDecoration(
        color: appTheme.whiteA700,
      );
// Second decorations
  static BoxDecoration get second => BoxDecoration(
        color: appTheme.lightGreen100,
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 1.h,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      );
}

class BorderRadiusStyle {
  // Rounded borders
  static BorderRadius get roundedBorder40 => BorderRadius.circular(
        40.h,
      );
  static BorderRadius get roundedBorder8 => BorderRadius.circular(
        8.h,
      );
}
