import 'package:flutter/material.dart';

class AppColor {
  // Basic colors - ensuring all are properly defined
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const transparent = Color(0x00000000);

  // Accent colors (remain similar)
  static const primary = Color(0xFF5BC0EB);
  static const secondary = Color(0xFF3774B3);
  static const accent = Color(0xFF5BC0EB);

  // Base dark mode colors
  static const mainColor = Color(0xFF121212);
  static const darker = Color(0xFF1E1E1E);
  static const cardColor = Color(0xFF1F1F1F);
  static const appBgColor = Color(0xFF000000);
  static const appBarColor = Color(0xFF1F1F1F);
  static const bottomBarColor = Color(0xFF1F1F1F);
  static const inActiveColor = Color(0xFF9E9E9E);
  static const shadowColor = Color(0x40000000);
  static const textBoxColor = Color(0xFF1C1C1C);

  // Text colors (light for contrast)
  static const textColor = Color(0xFFFFFFFF);
  static const glassTextColor = Color(0xFFFFFFFF);
  static const labelColor = Color(0xFFB0B0B0);
  static const glassLabelColor = Color(0xFFFFFFFF);

  // Action color – slightly adjusted for dark mode clarity
  static const actionColor = Color(0xFF5BC0EB);

  // Additional color scheme properties for consistency with your widget code:
  // 'primaryContainer' is used for the progress indicator's background and progress colors.
  static const primaryContainer = Color(0xFF5BC0EB);
  // 'inverseSurface' is used in card shadow decorations.
  static const inverseSurface = Color(0xFF2C2C2C);

  // Accent palette
  static const yellow = Color(0xFFffd966);
  static const green = Color(0xFF4CAF50);
  static const pink = Color(0xFFE91E63);
  static const purple = Color(0xFF9C27B0);
  static const red = Color(0xFFF44336);
  static const orange = Color(0xFFFF9800);
  static const sky = Color(0xFFABDEE6);
  static const blue = Color(0xFF2196F3);

  // A sample list of accent colors for UI elements
  static const listColors = [
    green,
    purple,
    yellow,
    orange,
    sky,
    secondary,
    red,
    blue,
    pink,
    yellow,
  ];
}
