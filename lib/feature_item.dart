/*import 'package:flutter/material.dart';
import 'colors.dart';

import 'custom_image.dart';

class FeatureItem extends StatelessWidget {
  FeatureItem({
    Key? key,
    required this.data,
    this.width = 280,
    this.height = 290,
    this.onTap,
  }) : super(key: key);

  final data;
  final double width;
  final double height;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: EdgeInsets.only(right: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColor.shadowColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 1,
              offset: Offset(1, 1), // changes position of shadow
            ),
          ],
        ),
        child: Stack(
          children: [
            CustomImage(
              data["image"],
              width: double.infinity,
              height: 190,
              radius: 15,
            ),
            Positioned(
              top: 170,
              right: 15,
              child: _buildPrice(),
            ),
            Positioned(
              top: 210,
              child: _buildInfo(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Container(
      width: width - 20,
      padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data["name"],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              color: AppColor.labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          _buildAttributes(),
        ],
      ),
    );
  }

  Widget _buildPrice() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.shadowColor.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 1,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Text(
        data["price"],
        style: TextStyle(
          color: AppColor.labelColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAttributes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _getAttribute(
          Icons.play_circle_outlined,
          AppColor.labelColor,
          data["session"],
        ),
        const SizedBox(
          width: 12,
        ),
        _getAttribute(
          Icons.schedule_rounded,
          AppColor.labelColor,
          data["duration"],
        ),
        const SizedBox(
          width: 12,
        ),
        _getAttribute(
          Icons.star,
          AppColor.yellow,
          data["review"],
        ),
      ],
    );
  }

  _getAttribute(IconData icon, Color color, String info) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(
          width: 3,
        ),
        Text(
          info,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColor.labelColor, fontSize: 13),
        ),
      ],
    );
  }
}
*/
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'custom_image.dart';

class FeatureItem extends StatelessWidget {
  FeatureItem({
    Key? key,
    required this.data,
    required this.videoIndex, // new integer input from parent
    this.width = 280,
    this.height = 290,
    this.onTap,
  }) : super(key: key);

  final data;
  final int videoIndex;
  final double width;
  final double height;
  final GestureTapCallback? onTap;

  // Define color constants directly in this file
  static const Color background =
      Color(0xFF000000); // App background (if needed)
  static const Color cardBackground = Color(0xFF1F1F1F); // Card background
  static final Color cardBorder = Colors.grey[800]!; // Card border
  static const Color headline = Color(0xFFFFFFFF); // Main headline text
  static const Color secondaryText =
      Color(0xFFD1D1D1); // Secondary text (if needed)
  static const Color labelColor = Color(0xFFB0B0B0); // Labels and small text
  static const Color chipBackground =
      Color(0xFF323232); // For chip backgrounds (if needed)
  static const Color chipText = Color(0xFFFFFFFF); // For chip text (if needed)
  static const Color chipAccent = Color(0xFF5BC0EB); // Teal accent (if needed)
  static const Color primaryButtonBackground =
      Color(0xFF5BC0EB); // Primary button background
  static const Color secondaryButtonBackground =
      Color(0xFF323232); // Secondary button background
  static const Color buttonText = Color(0xFFFFFFFF); // Button text
  static const Color shadowColor = Color(0xFF000000); // Shadow color
  static const Color ratingStar = Color(0xFFFFD700); // Gold color for star icon

  // Video URLs list
  final List<String> urls = const [
    "https://vimeo.com/1070732701/558b21900f",
    "https://vimeo.com/1070650026/ee8ceda97d",
    "https://vimeo.com/1070731552/e1f08a9102",
    "https://vimeo.com/1070732193/5401e265ec",
    "https://vimeo.com/1070732479/5b389160ef",
    "https://vimeo.com/1070732193/5401e265ec",
    "https://vimeo.com/1070733130/aa190bee5a",
    "https://vimeo.com/1070733568/3ef905f411",
    "https://vimeo.com/1070733877/e159f1d5af",
    "https://vimeo.com/1070734145/9c25564d81",
    "https://vimeo.com/1070734390/58520c7b1d",
    "https://vimeo.com/1070734810/2528c2adee",
    "https://vimeo.com/1070735257/3daf9fea49",
    "https://vimeo.com/1070735634/ad8d6935d9",
    "https://vimeo.com/1070735980/98400943c6",
    "https://vimeo.com/1070736587/c5fa59aa6e"
  ];

  Future<void> openVideo(int index) async {
    if (index >= 0 && index < urls.length) {
      final Uri url = Uri.parse(urls[index]);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Call parent's onTap callback if provided.
        if (onTap != null) {
          onTap!();
        }
        // Open the video based on the provided videoIndex.
        await openVideo(videoIndex);
      },
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 1,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            CustomImage(
              data["image"],
              width: double.infinity,
              height: 190,
              radius: 15,
            ),
            Positioned(
              top: 170,
              right: 15,
              child: _buildPrice(),
            ),
            Positioned(
              top: 210,
              child: _buildInfo(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Container(
      width: width - 20,
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data["name"],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              color: headline,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _buildAttributes(),
        ],
      ),
    );
  }

  Widget _buildPrice() {
    return Container(
      padding: const EdgeInsets.all(7.5),
      decoration: BoxDecoration(
        color: primaryButtonBackground,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Text(
        data["price"],
        style: const TextStyle(
          color: buttonText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAttributes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _getAttribute(
          Icons.play_circle_outlined,
          labelColor,
          data["session"],
        ),
        const SizedBox(width: 12),
        _getAttribute(
          Icons.schedule_rounded,
          labelColor,
          data["duration"],
        ),
        const SizedBox(width: 12),
        _getAttribute(
          Icons.star,
          ratingStar,
          data["review"],
        ),
      ],
    );
  }

  Widget _getAttribute(IconData icon, Color color, String info) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          info,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: labelColor,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
