import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SettingItem extends StatelessWidget {
  const SettingItem({
    Key? key,
    required this.title,
    this.onTap,
    this.leadingIcon,
    // Main Headline Text: #FFFFFF
    this.leadingIconColor = const Color(0xFFFFFFFF),
    // Primary Button Background / Accent: #5BC0EB
    this.bgIconColor = const Color(0xFF5BC0EB),
  }) : super(key: key);

  final String? leadingIcon;
  final Color leadingIconColor;
  final Color bgIconColor;
  final String title;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // Removed debug border decoration.
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: leadingIcon != null ? _buildItemWithPrefixIcon() : _buildItem(),
      ),
    );
  }

  Widget _buildPrefixIcon() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bgIconColor,
        shape: BoxShape.circle,
      ),
      child: SvgPicture.asset(
        leadingIcon!,
        color: leadingIconColor,
        width: 22,
        height: 22,
      ),
    );
  }

  Widget _buildItemWithPrefixIcon() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPrefixIcon(),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFFFFFFF),
              decoration: TextDecoration.none,
            ),
          ),
        ),
        const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFFB0B0B0),
          size: 17,
        )
      ],
    );
  }

  Widget _buildItem() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFFFFFFF),
              decoration: TextDecoration.none,
            ),
          ),
        ),
        const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFFB0B0B0),
          size: 17,
        )
      ],
    );
  }
}
