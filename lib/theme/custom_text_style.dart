import 'package:flutter/material.dart';
import '../core/app_export.dart';

extension on TextStyle {
  TextStyle get lato {
    return copyWith(
      fontFamily: 'Lato',
    );
  }

  TextStyle get playfairDisplay {
    return copyWith(
      fontFamily: 'PlayfairDisplay',
    );
  }
}

/// A collection of pre-defined text styles for customizing text appearance,
/// categorized by different font families and weights.
/// Additionally, this class includes extensions on [TextStyle] to easily apply specific font families to text.
class CustomTextStyles {
  // Body text style
  static TextStyle get bodySmallBlack900 => theme.textTheme.bodySmall!.copyWith(
        color: appTheme.black900,
      );
  static TextStyle get bodySmallOnPrimary =>
      theme.textTheme.bodySmall!.copyWith(
        color: theme.colorScheme.onPrimary,
      );
// Headline text style
  static TextStyle get headlineSmallBold =>
      theme.textTheme.headlineSmall!.copyWith(
        fontWeight: FontWeight.w700,
      );
  static TextStyle get headlineSmallMedium =>
      theme.textTheme.headlineSmall!.copyWith(
        fontWeight: FontWeight.w500,
      );
// Inter text style
  static TextStyle get latoPrimary => TextStyle(
        color: theme.colorScheme.primary,
        fontSize: 4.fSize,
        fontWeight: FontWeight.w400,
      ).lato;

  static TextStyle get signature => TextStyle(
        fontSize: 24.fSize, 
        fontWeight: FontWeight.w700, 
        color: theme.colorScheme.primary, 
      ).playfairDisplay; 
}
