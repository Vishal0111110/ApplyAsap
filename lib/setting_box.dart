import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SettingBox extends StatelessWidget {
  const SettingBox({
    Key? key,
    required this.title,
    required this.icon,
    // Default color set to pure white (#FFFFFF) for main headline text
    this.color = const Color(0xFFFFFFFF),
  }) : super(key: key);

  final String title;
  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        // Card Background: slightly lighter than pure black for differentiation
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(5),
        // Removed border decoration to avoid unwanted underlines.
        // If you want a subtle outline, consider adding a border on specific sides only.
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A2A2A).withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            icon,
            color: color,
            width: 22,
            height: 22,
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          )
        ],
      ),
    );
  }
}
