import 'package:flutter/material.dart';

class AppColor {
  // Accent colors (remain similar)
  static const primary = Color(0xFFf77080);
  static const secondary = Color(0xFFe96561);

  // Base dark mode colors
  static const mainColor = Color(0xFF121212);
  static const darker = Color(0xFF1E1E1E);
  static const cardColor = Color(0xFF242424);
  static const appBgColor = Color(0xFF121212);
  static const appBarColor = Color(0xFF1F1F1F);
  static const bottomBarColor = Color(0xFF1F1F1F);
  static const inActiveColor = Colors.grey;
  static const shadowColor = Colors.black87;
  static const textBoxColor = Color(0xFF1C1C1C);

  // Text colors (light for contrast)
  static const textColor = Color(0xFFFFFFFF);
  static const glassTextColor = Colors.white;
  static const labelColor = Color(0xFFB0B0B0);
  static const glassLabelColor = Colors.white;

  // Action color – slightly adjusted for dark mode clarity
  static const actionColor = Color(0xFFf28c8c);

  // Additional color scheme properties for consistency with your widget code:
  // 'primaryContainer' is used for the progress indicator's background and progress colors.
  static const primaryContainer = Color(0xFFf28c8c);
  // 'inverseSurface' is used in card shadow decorations.
  static const inverseSurface = Color(0xFF2C2C2C);

  // Accent palette – adjusted slightly to work well on a dark background
  static const yellow = Color(0xFFffd966);
  static const green = Color(0xFFa2e1a6);
  static const pink = Color(0xFFf5bde8);
  static const purple = Color(0xFFc8b6ff);
  static const red = Color(0xFFf77080);
  static const orange = Color(0xFFf5ba92);
  static const sky = Color(0xFFABDEE6);
  static const blue = Color(0xFF509BE4);

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
