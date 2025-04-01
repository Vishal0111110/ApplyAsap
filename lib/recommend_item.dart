import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'custom_image.dart';

class RecommendItem extends StatelessWidget {
  const RecommendItem({
    Key? key,
    required this.data,
    required this.index,
    this.onTap,
  }) : super(key: key);

  final data;
  final int index;
  final GestureTapCallback? onTap;

  // Inline color definitions based on your dark-themed palette.
  static const Color background = Color(0xFF000000); // Primary app background
  static const Color cardBackground = Color(0xFF1F1F1F); // Card background
  static final Color cardBorder = Colors.grey[800]!; // Card border/outline
  static const Color headline = Color(0xFFFFFFFF); // Main headline text
  static const Color secondaryText = Color(0xFFD1D1D1); // Secondary text
  static const Color label = Color(0xFFB0B0B0); // Labels / small text
  static const Color accent =
      Color(0xFF5BC0EB); // Accent color for price, buttons, etc.
  static const Color star = Color(0xFFFFC107); // Gold for star ratings

  Future<void> openVideo(int index) async {
    final List<String> urls = [
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
        // If a custom onTap is provided, execute it.
        if (onTap != null) {
          onTap!();
        } else {
          // Otherwise, open the video based on the provided index.
          await openVideo(index);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        width: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cardBackground,
          border: Border.all(color: cardBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 1,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            CustomImage(
              data["image"],
              radius: 15,
              height: 80,
            ),
            const SizedBox(width: 10),
            _buildInfo()
          ],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course title / name (Headline)
        Text(
          data["name"],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: headline,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        // Course price with accent color
        Text(
          data["price"],
          style: const TextStyle(
            fontSize: 14,
            color: accent,
          ),
        ),
        const SizedBox(height: 15),
        _buildDurationAndRate()
      ],
    );
  }

  Widget _buildDurationAndRate() {
    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          color: label,
          size: 14,
        ),
        const SizedBox(width: 2),
        // Duration text (using label color)
        Text(
          data["duration"],
          style: const TextStyle(
            fontSize: 12,
            color: label,
          ),
        ),
        const SizedBox(width: 20),
        Icon(
          Icons.star,
          color: star,
          size: 14,
        ),
        const SizedBox(width: 2),
        // Review text (using label color)
        Text(
          data["review"],
          style: const TextStyle(
            fontSize: 12,
            color: label,
          ),
        )
      ],
    );
  }
}
