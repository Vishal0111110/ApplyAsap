/*import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; // For FilteringTextInputFormatter
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({Key? key}) : super(key: key);

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  // Reference to the 'posts' node in Firebase Realtime Database
  final DatabaseReference _postsRef = FirebaseDatabase.instance.ref('posts');

  // Controller for the text field in the bottom sheet
  final TextEditingController _postController = TextEditingController();

  // Controllers for share dialog
  final TextEditingController _exportWAController = TextEditingController();
  final TextEditingController _exportEmailController = TextEditingController();

  // Variables to store the media (image/video) in Base64 format and media type
  String? _mediaBase64;
  String? _mediaType;

  // Set to track which posts the user has liked (simulate one like per user)
  final Set<String> _likedPosts = {};

  /// Opens the bottom sheet for creating a new post.
  void _openNewPostSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with title and Cancel button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Create a Post",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _postController,
                    maxLines: 5,
                    style: const TextStyle(
                      color: Color(0xFFD1D1D1),
                    ),
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: const TextStyle(
                        color: Color(0xFFB0B0B0),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF323232),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[800]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: const Color(0xFF5BC0EB)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5BC0EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _pickMedia,
                        icon: const Icon(Icons.attach_file),
                        label: const Text("Add Media"),
                      ),
                      const SizedBox(width: 16),
                      _mediaBase64 != null
                          ? const Icon(Icons.check, color: Colors.green)
                          : const SizedBox.shrink(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BC0EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final content = _postController.text.trim();
                        if (content.isNotEmpty || _mediaBase64 != null) {
                          await _postsRef.push().set({
                            "author": FirebaseAuth
                                    .instance.currentUser?.displayName ??
                                "Unknown", // Now gets name from FirebaseAuth
                            "content": content,
                            "timestamp": DateTime.now().toIso8601String(),
                            "likes": 0,
                            "comments": {},
                            "media": _mediaBase64 ?? "",
                            "mediaType": _mediaType ?? ""
                          });
                          _postController.clear();
                          setState(() {
                            _mediaBase64 = null;
                            _mediaType = null;
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Post"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Opens the file picker using ImagePicker in a bottom sheet.
  Future<void> _pickMedia() async {
    showModalBottomSheet(
      backgroundColor: const Color(0xFF101010),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: Color(0xFF5BC0EB)),
                title: const Text(
                  "Image",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final picker = ImagePicker();
                  final pickedFile =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    final bytes = await pickedFile.readAsBytes();
                    String base64Image = base64Encode(bytes);
                    setState(() {
                      _mediaBase64 = base64Image;
                      _mediaType = 'image';
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Color(0xFF5BC0EB)),
                title: const Text(
                  "Video",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Video not supported")),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.attach_file, color: Color(0xFF5BC0EB)),
                title: const Text(
                  "File",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("File not supported")),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Handles the "Like" functionality by incrementing the like count.
  /// Allows only one like per valid user.
  Future<void> _handleLike(String postId, int currentLikes) async {
    if (_likedPosts.contains(postId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You have already liked this post"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    await _postsRef.child(postId).update({"likes": currentLikes + 1});
    setState(() {
      _likedPosts.add(postId);
    });
  }

  /// Opens the comment sheet where users can view and add comments.
  void _openCommentSheet(String postId, Map<dynamic, dynamic> postData) {
    final TextEditingController commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            // Get existing comments if any.
            Map<dynamic, dynamic> comments = {};
            if (postData['comments'] != null) {
              comments = Map<dynamic, dynamic>.from(postData['comments']);
            }
            List<Map<dynamic, dynamic>> commentsList =
                comments.entries.map((entry) {
              return Map<dynamic, dynamic>.from(entry.value);
            }).toList();
            // Sort comments by recency.
            commentsList.sort((a, b) {
              final timeA =
                  DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
              final timeB =
                  DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
              return timeB.compareTo(timeA);
            });
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Column(
                children: [
                  // Top row with title and Cancel button.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Comments",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: commentsList.length,
                      itemBuilder: (context, index) {
                        final comment = commentsList[index];
                        return ListTile(
                          title: Text(
                            comment['author'] ?? "Anonymous",
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            comment['content'] ?? "",
                            style: const TextStyle(color: Color(0xFFD1D1D1)),
                          ),
                          trailing: Text(
                            comment['timestamp'] ?? "",
                            style: const TextStyle(
                                color: Color(0xFFB0B0B0), fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Add a comment...",
                            hintStyle:
                                const TextStyle(color: Color(0xFFB0B0B0)),
                            filled: true,
                            fillColor: const Color(0xFF323232),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[800]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: const Color(0xFF5BC0EB)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5BC0EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final commentContent = commentController.text.trim();
                          if (commentContent.isNotEmpty) {
                            await _postsRef
                                .child(postId)
                                .child("comments")
                                .push()
                                .set({
                              "author": FirebaseAuth
                                      .instance.currentUser?.displayName ??
                                  "Anonymous",
                              "content": commentContent,
                              "timestamp": DateTime.now().toIso8601String(),
                            });
                            commentController.clear();
                          }
                        },
                        child: const Text("Send"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Opens a dialog to share the post content via WhatsApp or Email.
  void _handleShare(String content) {
    // Replace the localized map with your localization logic if needed.
    Map<String, String> localized = {
      "shareChat": "Share Chat",
      "shareChatContent": "Share this chat with others",
      "shareViaWA": "Share via Whatsapp",
      "enterWANumber": "Enter WhatsApp no",
      "shareViaEmail": "Share via Email",
      "enterEmail": "Enter email",
    };

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F1F1F),
          title: Text(
            localized["shareChat"] ?? "Share Chat",
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localized["shareChatContent"] ?? "Share this chat with others",
                style: const TextStyle(color: Color(0xFFD1D1D1)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _exportWAController,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: localized["shareViaWA"] ?? "Share via Whatsapp",
                  hintText: localized["enterWANumber"] ?? "Enter WhatsApp no",
                  prefixIcon: const Icon(Icons.message_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _exportEmailController,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(' '))
                ],
                decoration: InputDecoration(
                  labelText: localized["shareViaEmail"] ?? "Share via Email",
                  hintText: localized["enterEmail"] ?? "Enter email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF5BC0EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF5BC0EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final String waNumber = _exportWAController.text.trim();
                      final String email = _exportEmailController.text.trim();

                      // Check if at least one contact method is provided
                      if (waNumber.isEmpty && email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Please enter a Whatsapp no or an Email")),
                        );
                        return;
                      }

                      // Share via WhatsApp if a number is provided
                      if (waNumber.isNotEmpty) {
                        final String message = Uri.encodeComponent(
                            "Hello, I wanted to share this chat with you.\n\n$content");
                        final String waUrl =
                            "https://wa.me/$waNumber?text=$message";

                        if (await canLaunch(waUrl)) {
                          await launch(waUrl);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Could not launch WhatsApp")),
                          );
                        }
                      }

                      // Share via Email if an email address is provided
                      if (email.isNotEmpty) {
                        final String subject =
                            Uri.encodeComponent("Chat Share");
                        final String body = Uri.encodeComponent(
                            "Hello, I wanted to share this chat with you.\n\n$content");
                        final String emailUrl =
                            "mailto:$email?subject=$subject&body=$body";

                        if (await canLaunch(emailUrl)) {
                          await launch(emailUrl);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Could not launch Email client")),
                          );
                        }
                      }

                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      "Send",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Builds the widget for a single post card.
  Widget _buildPostCard(String postId, Map<dynamic, dynamic> postData) {
    // Use the user's name from FirebaseAuth if available.
    final author = postData['author'] ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'Unknown';
    final content = postData['content'] ?? '';
    final timestamp = postData['timestamp'] ?? '';
    final likes = postData['likes'] ?? 0;
    final media = postData['media'] ?? "";
    final mediaType = postData['mediaType'] ?? "";

    return InkWell(
      onTap: () => _openCommentSheet(postId, postData),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          border: Border.all(color: Colors.grey[800]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Avatar, author, and timestamp.
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF323232),
                    child: Text(
                      author.isNotEmpty ? author[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timestamp,
                          style: const TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: const TextStyle(
                  color: Color(0xFFD1D1D1),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              // Display media if available.
              media != ""
                  ? mediaType == "image"
                      ? Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Image.memory(
                            base64Decode(media),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Text(
                                "Error loading image",
                                style: TextStyle(color: Colors.red),
                              );
                            },
                          ),
                        )
                      : mediaType == "video"
                          ? Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: VideoPlayerWidget(mediaBase64: media),
                            )
                          : const SizedBox.shrink()
                  : const SizedBox.shrink(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Like button.
                  InkWell(
                    onTap: () => _handleLike(postId, likes),
                    child: Row(
                      children: [
                        const Icon(Icons.thumb_up_alt_outlined,
                            size: 20, color: Color(0xFFB0B0B0)),
                        const SizedBox(width: 4),
                        Text(
                          "Like ($likes)",
                          style: const TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Comment button.
                  InkWell(
                    onTap: () => _openCommentSheet(postId, postData),
                    child: Row(
                      children: const [
                        Icon(Icons.comment_outlined,
                            size: 20, color: Color(0xFFB0B0B0)),
                        SizedBox(width: 4),
                        Text(
                          "Comment",
                          style: TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Share button.
                  InkWell(
                    onTap: () => _handleShare(content),
                    child: Row(
                      children: const [
                        Icon(Icons.share_outlined,
                            size: 20, color: Color(0xFFB0B0B0)),
                        SizedBox(width: 4),
                        Text(
                          "Share",
                          style: TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
*/
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; // For FilteringTextInputFormatter
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

// FeedPage now accepts a language index from the parent.
class FeedPage extends StatefulWidget {
  final int languageIndex;
  const FeedPage({Key? key, required this.languageIndex}) : super(key: key);

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  // Mapping of keys to a map of translations.
  // Each language index (0 to 15) corresponds to a specific language.
  // The values here are dummy translations that prepend the language name.
  final Map<String, Map<int, String>> localizedTexts = {
    "createPost": {
      0: "پوسٹ بنائیں", // Kashmiri (in Perso-Arabic script)
      1: "ਪੋਸਟ ਬਣਾਓ", // Punjabi (Gurmukhi)
      2: "पोस्ट बनाओ", // Haryanvi
      3: "पोस्ट बनाएं", // Hindi
      4: "पोस्ट बनाओ", // Rajasthani
      5: "पोस्ट बनाईं", // Bhojpuri
      6: "পোস্ট তৈরি করুন", // Bengali
      7: "પોસ્ટ બનાવો", // Gujarati
      8: "প'ষ্ট বনাওক", // Assamese
      9: "ପୋଷ୍ଟ ସୃଷ୍ଟି କରନ୍ତୁ", // Odia
      10: "पोस्ट तयार करा", // Marathi
      11: "போஸ்ட் உருவாக்கவும்", // Tamil
      12: "పోస్ట్ సృష్టించండి", // Telugu
      13: "ಪೋಸ್ಟ್ ರಚಿಸಿ", // Kannada
      14: "പോസ്റ്റ് സൃഷ്ടിക്കുക", // Malayalam
      15: "Create a Post", // English
    },
    "cancel": {
      0: "منسوخ کرو",
      1: "ਰੱਦ ਕਰੋ",
      2: "रद्द करो",
      3: "रद्द करें",
      4: "रद्द करो",
      5: "रद्द करीं",
      6: "বাতিল করুন",
      7: "રદ કરો",
      8: "বাতিল কৰক",
      9: "ବାତିଲ୍ କରନ୍ତୁ",
      10: "रद्द करा",
      11: "ரத்து செய்யவும்",
      12: "రద్దు చేయండి",
      13: "ರದ್ದುಮಾಡಿ",
      14: "റദ്ദാക്കുക",
      15: "Cancel",
    },
    "whatsOnYourMind": {
      0: "تُہند خیال کیہ آہے؟",
      1: "ਤੁਹਾਡੇ ਮਨ ਵਿਚ ਕੀ ਹੈ?",
      2: "तेरे मन में के है?",
      3: "आपके दिमाग में क्या है?",
      4: "आपां री विचार में के है?",
      5: "तोहरे मन में का बा?",
      6: "আপনার মনের অবস্থা কী?",
      7: "તમારા મનમાં શું છે?",
      8: "আপোনাৰ মনত কি আছে?",
      9: "ଆପଣଙ୍କ ମନରେ କଣ ଅଛି?",
      10: "तुमच्या मनात काय आहे?",
      11: "உங்கள் மனதில் என்ன உள்ளது?",
      12: "మీ మనసులో ఏముంది?",
      13: "ನಿಮ್ಮ ಮನಸ್ಸಿನಲ್ಲಿ ಏನು?",
      14: "നിങ്ങളുടെ മനസ്സിൽ എന്തുണ്ട്?",
      15: "What's on your mind?",
    },
    "addMedia": {
      0: "میڈیا شامل کرو",
      1: "ਮੀਡੀਆ ਸ਼ਾਮਲ ਕਰੋ",
      2: "मीडिया जोड़ो",
      3: "मीडिया जोड़ें",
      4: "मीडिया जोड़ो",
      5: "मीडिया जोड़ल जाव",
      6: "মিডিয়া যুক্ত করুন",
      7: "મીડિયા ઉમેરો",
      8: "মিডিয়া সংযোজন কৰক",
      9: "ମିଡିଆ ଯୋଗ କରନ୍ତୁ",
      10: "मीडिया जोडा",
      11: "மீடியா சேர்க்கவும்",
      12: "మీడియాను చేర్చండి",
      13: "ಮೀಡಿಯಾ ಸೇರಿಸಿ",
      14: "മീഡിയ ചേർക്കുക",
      15: "Add Media",
    },
    "post": {
      0: "پوسٹ",
      1: "ਪੋਸਟ",
      2: "पोस्ट",
      3: "पोस्ट",
      4: "पोस्ट",
      5: "पोस्ट",
      6: "পোস্ট",
      7: "પોસ્ટ",
      8: "প'ষ্ট",
      9: "ପୋଷ୍ଟ",
      10: "पोस्ट",
      11: "போஸ்ட்",
      12: "పోస్ట్",
      13: "ಪೋಸ್ಟ್",
      14: "പോസ്റ്റ്",
      15: "Post",
    },
    "image": {
      0: "تصویر",
      1: "ਤਸਵੀਰ",
      2: "इमेज",
      3: "चित्र",
      4: "छवि",
      5: "इमेज",
      6: "ছবি",
      7: "છબી",
      8: "ছবি",
      9: "ଚିତ୍ର",
      10: "प्रतिमा",
      11: "படம்",
      12: "చిత్రం",
      13: "ಚಿತ್ರ",
      14: "ചിത്രം",
      15: "Image",
    },
    "video": {
      0: "ویڈیو",
      1: "ਵੀਡੀਓ",
      2: "वीडियो",
      3: "वीडियो",
      4: "वीडियो",
      5: "वीडियो",
      6: "ভিডিও",
      7: "વીડિઓ",
      8: "ভিডিঅ'",
      9: "ଭିଡିଓ",
      10: "व्हिडिओ",
      11: "வீடியோ",
      12: "వీడియో",
      13: "ವೀಡಿಯೊ",
      14: "വീഡിയോ",
      15: "Video",
    },
    "videoNotSupported": {
      0: "ویڈیو حمایت نہیں",
      1: "ਵੀਡੀਓ ਸਮਰਥਿਤ ਨਹੀਂ",
      2: "वीडियो समर्थित नहीं",
      3: "वीडियो समर्थित नहीं",
      4: "वीडियो समर्थित नीं",
      5: "वीडियो समर्थित ना",
      6: "ভিডিও সমর্থিত নয়",
      7: "વીડિઓ સમર્થન નથી",
      8: "ভিডিঅ' সমৰ্থিত নহয়",
      9: "ଭିଡିଓ ସମର୍ଥିତ ନୁହେଁ",
      10: "व्हिडिओ समर्थित नाही",
      11: "வீடியோ ஆதரவு இல்லை",
      12: "వీడియో మద్దతు ఇవ్వబడదు",
      13: "ವೀಡಿಯೊ ಬೆಂಬಲಿಸಲಾಗುವುದಿಲ್ಲ",
      14: "വീഡിയോ പിന്തുണയില്ല",
      15: "Video not supported",
    },
    "file": {
      0: "فائل",
      1: "ਫਾਇਲ",
      2: "फ़ाइल",
      3: "फ़ाइल",
      4: "फ़ाइल",
      5: "फ़ाइल",
      6: "ফাইল",
      7: "ફાઈલ",
      8: "ফাইল",
      9: "ଫାଇଲ୍",
      10: "फाईल",
      11: "கோப்பு",
      12: "ఫైల్",
      13: "ಫೈಲ್",
      14: "ഫയൽ",
      15: "File",
    },
    "fileNotSupported": {
      0: "فائل حمایت نہیں",
      1: "ਫਾਇਲ ਸਮਰਥਿਤ ਨਹੀਂ",
      2: "फ़ाइल समर्थित नहीं",
      3: "फ़ाइल समर्थित नहीं",
      4: "फ़ाइल समर्थित नीं",
      5: "फ़ाइल समर्थित ना",
      6: "ফাইল সমর্থিত নয়",
      7: "ફાઈલ સમર્થન નથી",
      8: "ফাইল সমৰ্থিত নহয়",
      9: "ଫାଇଲ୍ ସମର୍ଥିତ ନୁହେଁ",
      10: "फाईल समर्थित नाही",
      11: "கோப்பு ஆதரவு இல்லை",
      12: "ఫైల్ మద్దతు ఇవ్వబడదు",
      13: "ಫೈಲ್ ಬೆಂಬಲಿಸಲಾಗುವುದಿಲ್ಲ",
      14: "ഫയൽ പിന്തുണയില്ല",
      15: "File not supported",
    },
    "alreadyLiked": {
      0: "آپ پہلے ہی پسند کر چکے ہیں",
      1: "ਤੁਸੀਂ ਪਹਿਲਾਂ ਹੀ ਪਸੰਦ ਕਰ ਚੁੱਕੇ ਹੋ",
      2: "तू पहले ही लाइक कर चुक्या स",
      3: "आपने पहले ही पसंद किया है",
      4: "थाने पहले ही पसंद कर लियो है",
      5: "रउआ पहिले से ही लाइक कइले बानी",
      6: "আপনি ইতিমধ্যে পছন্দ করেছেন",
      7: "તમે પહેલાથી જ પસંદ કર્યું છે",
      8: "আপুনি ইতিমধ্যে পছন্দ কৰিছে",
      9: "ଆପଣ ପୂର୍ବରୁ ମନେ ପସନ୍ଦ କରିଛନ୍ତି",
      10: "तुम्ही आधीच आवडले आहे",
      11: "நீங்கள் ஏற்கனவே லைக் செய்திருக்கிறீர்கள்",
      12: "మీరు ఇప్పటికే లైక్ చేసారు",
      13: "ನೀವು ಈಗಾಗಲೇ ಲೈಕ್ ಮಾಡಿದ್ದಾರೆ",
      14: "നിങ്ങൾ ഇതിനകം ലൈക്ക് ചെയ്തിരിക്കുന്നു",
      15: "You have already liked this post",
    },
    "comments": {
      0: "تاثرات",
      1: "ਟਿੱਪਣੀਆਂ",
      2: "टिप्पणियाँ",
      3: "टिप्पणियाँ",
      4: "टिप्पणियाँ",
      5: "टिप्पणी",
      6: "মন্তব্যসমূহ",
      7: "ટિપ્પણીઓ",
      8: "টিপ্পণী",
      9: "ଟିପ୍ପଣୀ",
      10: "टिप्पण्या",
      11: "கருத்துகள்",
      12: "కమెంట్లు",
      13: "ಕಾಮೆಂಟ್ಸ್",
      14: "കമന്റുകൾ",
      15: "Comments",
    },
    "addAComment": {
      0: "تبصرہ شامل کرو",
      1: "ਇੱਕ ਟਿੱਪਣੀ ਸ਼ਾਮਲ ਕਰੋ",
      2: "एक टिप्पणी जोड़ो",
      3: "एक टिप्पणी जोड़ें",
      4: "एक टिप्पणी जोड़ो",
      5: "एक टिप्पणी जोड़ल जाव",
      6: "একটি মন্তব্য যুক্ত করুন",
      7: "એક ટિપ્પણી ઉમેરો",
      8: "এখন মন্তব্য যোগ কৰক",
      9: "ଏକ ଟିପ୍ପଣୀ ଯୋଗ କରନ୍ତୁ",
      10: "एक टिप्पणी जोडा",
      11: "ஒரு கருத்தை சேர்க்கவும்",
      12: "ఒక వ్యాఖ్యను చేర్చండి",
      13: "ಒಂದು ಕಾಮೆಂಟ್ ಸೇರಿಸಿ",
      14: "ഒരു കമന്റ് ചേർക്കുക",
      15: "Add a comment...",
    },
    "send": {
      0: "بھیجیں",
      1: "ਭੇਜੋ",
      2: "भेज",
      3: "भेजें",
      4: "भेजो",
      5: "भेजीं",
      6: "পাঠান",
      7: "મોકલો",
      8: "পঠিয়াওক",
      9: "ପଠାନ୍ତୁ",
      10: "पाठवा",
      11: "அனுப்பவும்",
      12: "పంపండి",
      13: "ಕಳುಹಿಸು",
      14: "അയച്ചു",
      15: "Send",
    },
    "shareChat": {
      0: "چیٹ شیئر کریں",
      1: "ਚੈਟ ਸਾਂਝਾ ਕਰੋ",
      2: "चैट शेयर करो",
      3: "चैट शेयर करें",
      4: "चैट शेयर करो",
      5: "चैट शेयर करीं",
      6: "চ্যাট শেয়ার করুন",
      7: "ચેટ શેર કરો",
      8: "চেট শ্বেয়াৰ কৰক",
      9: "ଚାଟ୍ ସେୟାର୍ କରନ୍ତୁ",
      10: "चॅट शेअर करा",
      11: "சாட் பகிரவும்",
      12: "చాట్ షేర్ చేయండి",
      13: "ಚಾಟ್ ಹಂಚಿಕೆ ಮಾಡಿ",
      14: "ചാറ്റ് പങ്കുവെക്കുക",
      15: "Share Chat",
    },
    "shareChatContent": {
      0: "دیگر کے ساتھ یہ چیٹ شیئر کریں",
      1: "ਇਸ ਚੈਟ ਨੂੰ ਹੋਰਾਂ ਨਾਲ ਸਾਂਝਾ ਕਰੋ",
      2: "इस चैट ने दूसर्यां के संग शेयर करो",
      3: "इस चैट को दूसरों के साथ साझा करें",
      4: "इस चैट ने दूसर्यां सूं शेयर करो",
      5: "ई चैट दूसर लोगन के साथ शेयर करीं",
      6: "এই চ্যাটটি অন্যদের সাথে শেয়ার করুন",
      7: "આ ચેટને અન્ય સાથે શેર કરો",
      8: "এই চেট অন্যৰ সৈতে শ্বেয়াৰ কৰক",
      9: "ଏହି ଚାଟ୍କୁ ଅନ୍ୟମାନଙ୍କ ସହିତ ସେୟାର କରନ୍ତୁ",
      10: "हा चॅट इतरांसोबत शेअर करा",
      11: "இந்த சாட் மற்றவர்களுடன் பகிரவும்",
      12: "ఈ చాట్‌ను ఇతరులతో పంచుకోండి",
      13: "ಈ ಚಾಟ್ ಅನ್ನು ಇತರರೊಂದಿಗೆ ಹಂಚಿಕೊಳ್ಳಿ",
      14: "ഈ ചാറ്റ് മറ്റാരോടും പങ്കിടുക",
      15: "Share this chat with others",
    },
    "shareViaWA": {
      0: "واٹس ایپ کے ذریعے شیئر کریں",
      1: "ਵਾਟਸਐਪ ਰਾਹੀਂ ਸਾਂਝਾ ਕਰੋ",
      2: "व्हाट्सएप के जरिए शेयर करो",
      3: "व्हाट्सएप के माध्यम से शेयर करें",
      4: "व्हाट्सएप री मदद सूं शेयर करो",
      5: "व्हाट्सएप के जरिए शेयर करीं",
      6: "হোয়াটসঅ্যাপের মাধ্যমে শেয়ার করুন",
      7: "વોટ્સએપ મારફતે શેર કરો",
      8: "ৱাটছএপৰ জৰিয়তে শ্বেয়াৰ কৰক",
      9: "ୱାଟସ୍ଆପ୍ ମାଧ୍ୟମରେ ସେୟାର କରନ୍ତୁ",
      10: "व्हॉट्सअॅपद्वारे शेअर करा",
      11: "வாட்ஸ்அப் மூலம் பகிரவும்",
      12: "వాట్సాప్ ద్వారా షేర్ చేయండి",
      13: "ವಾಟ್ಸಾಪ್ ಮೂಲಕ ಹಂಚಿಕೊಳ್ಳಿ",
      14: "വാട്ട്സാപ്പ് വഴി പങ്കുവെക്കുക",
      15: "Share via Whatsapp",
    },
    "enterWANumber": {
      0: "واٹس ایپ نمبر درج کریں",
      1: "ਵਾਟਸਐਪ ਨੰਬਰ ਦਰਜ ਕਰੋ",
      2: "व्हाट्सएप नंबर डालो",
      3: "व्हाट्सएप नंबर दर्ज करें",
      4: "व्हाट्सएप नंबर दर्ज करो",
      5: "व्हाट्सएप नंबर दर्ज करीं",
      6: "হোয়াটসঅ্যাপ নম্বর প্রবেশ করুন",
      7: "વોટ્સએપ નંબર દાખલ કરો",
      8: "ৱাটছএপ নম্বৰ সন্নিৱিষ্ট কৰক",
      9: "ୱାଟସ୍ଆପ୍ ନମ୍ବର ଦରଖାସ୍ତ କରନ୍ତୁ",
      10: "व्हॉट्सअॅप नंबर प्रविष्ट करा",
      11: "வாட்ஸ்அப் எண் உள்ளிடவும்",
      12: "వాట్సాప్ నంబర్ నమోదు చేయండి",
      13: "ವಾಟ್ಸಪ್ ಸಂಖ್ಯೆಯನ್ನು ನಮೂದಿಸಿ",
      14: "വാട്ട്സ്ആപ്പ് നമ്പർ നൽകുക",
      15: "Enter WhatsApp no",
    },
    "shareViaEmail": {
      0: "ایمیل کے ذریعے شیئر کریں",
      1: "ਈਮੇਲ ਰਾਹੀਂ ਸਾਂਝਾ ਕਰੋ",
      2: "ईमेल के जरिए शेयर करो",
      3: "ईमेल के माध्यम से शेयर करें",
      4: "ईमेल री मदद सूं शेयर करो",
      5: "ईमेल के जरिए शेयर करीं",
      6: "ইমেইলের মাধ্যমে শেয়ার করুন",
      7: "ઈમેઇલ મારફતે શેર કરો",
      8: "ইমেইলৰ জৰিয়তে শ্বেয়াৰ কৰক",
      9: "ଇମେଲ୍ ମାଧ୍ୟମରେ ସେୟାର କରନ୍ତୁ",
      10: "ईमेलद्वारे शेअर करा",
      11: "மின்னஞ்சல் மூலம் பகிரவும்",
      12: "ఇమెయిల్ ద్వారా షేర్ చేయండి",
      13: "ಇಮೇಲ್ ಮೂಲಕ ಹಂಚಿಕೊಳ್ಳಿ",
      14: "ഇമെയിൽ വഴി പങ്കുവെക്കുക",
      15: "Share via Email",
    },
    "enterEmail": {
      0: "ایمیل درج کریں",
      1: "ਈਮੇਲ ਦਰਜ ਕਰੋ",
      2: "ईमेल डालो",
      3: "ईमेल दर्ज करें",
      4: "ईमेल दर्ज करो",
      5: "ईमेल दर्ज करीं",
      6: "ইমেইল প্রবেশ করান",
      7: "ઈમેઇલ દાખલ કરો",
      8: "ইমেইল সন্নিৱিষ্ট কৰক",
      9: "ଇମେଲ୍ ଦରଖାସ୍ତ କରନ୍ତୁ",
      10: "ईमेल प्रविष्ट करा",
      11: "மின்னஞ்சல் உள்ளிடவும்",
      12: "ఇమెయిల్ నమోదు చేయండి",
      13: "ಇಮೇಲ್ ನಮೂದಿಸಿ",
      14: "ഇമെയിൽ നൽകുക",
      15: "Enter email",
    },
    "enterContact": {
      0: "برائے مہربانی واٹس ایپ نمبر یا ای میل درج کریں",
      1: "ਕਿਰਪਾ ਕਰਕੇ ਵਾਟਸਐਪ ਨੰਬਰ ਜਾਂ ਈਮੇਲ ਦਰਜ ਕਰੋ",
      2: "कृपया व्हाट्सएप नंबर या ईमेल डालो",
      3: "कृपया व्हाट्सएप नंबर या ईमेल दर्ज करें",
      4: "कृपया व्हाट्सएप नंबर या ईमेल दर्ज करो",
      5: "कृपया व्हाट्सएप नंबर या ईमेल दर्ज करीं",
      6: "অনুগ্রহ করে হোয়াটসঅ্যাপ নম্বর অথবা ইমেইল প্রদান করুন",
      7: "કૃપા કરીને વોટ્સએપ નંબર અથવા ઈમેઇલ દાખલ કરો",
      8: "দয়া কৰি ৱাটছএপ নম্বৰ বা ইমেইল সন্নিৱিষ্ট কৰক",
      9: "ଦୟାକରି ୱାଟସ୍ଆପ୍ ନମ୍ବର କିମ୍ବା ଇମେଲ୍ ଦରଖାସ୍ତ କରନ୍ତୁ",
      10: "कृपया व्हॉट्सअॅप नंबर किंवा ईमेल प्रविष्ट करा",
      11: "தயவுசெய்து வாட்ஸ்அப் எண் அல்லது மின்னஞ்சல் உள்ளிடவும்",
      12: "దయచేసి వాట్సాప్ నంబర్ లేదా ఇమెయిల్ నమోదు చేయండి",
      13: "ದಯವಿಟ್ಟು ವಾಟ್ಸಪ್ ಸಂಖ್ಯೆ ಅಥವಾ ಇಮೇಲ್ ನಮೂದಿಸಿ",
      14: "ദയവായി വാട്ട്സ്ആപ്പ് നമ്പർ അല്ലെങ്കിൽ ഇമെയിൽ നൽകുക",
      15: "Please enter a Whatsapp no or an Email",
    },
    "couldNotLaunchWA": {
      0: "واٹس ایپ لانچ نہیں ہو سکا",
      1: "ਵਾਟਸਐਪ ਸ਼ੁਰੂ ਨਹੀਂ ਕੀਤਾ ਜਾ ਸਕਿਆ",
      2: "व्हाट्सएप लॉन्च नहीं होया",
      3: "व्हाट्सएप लॉन्च नहीं हो सका",
      4: "व्हाट्सएप लॉन्च नीं होयो",
      5: "व्हाट्सएप लॉन्च ना हो पावल",
      6: "হোয়াটসঅ্যাপ চালু করা যায়নি",
      7: "વોટ્સએપ લોંચ કરી શકાયો નથી",
      8: "ৱাটছএপ আৰম্ভ কৰিব পৰা নগ'ল",
      9: "ୱାଟସ୍ଆପ୍ ଆରମ୍ଭ କରିପାରିଲା ନାହିଁ",
      10: "व्हॉट्सअॅप लॉन्च करता आला नाही",
      11: "வாட்ஸ்அப் துவக்க முடியவில்லை",
      12: "వాట్సాప్ ప్రారంభించలేము",
      13: "ವಾಟ್ಸಪ್ ಲಾಂಚ್ ಮಾಡಲಾಗಲಿಲ್ಲ",
      14: "വാട്ട്സാപ്പ് ലോഞ്ച് ചെയ്യാനായില്ല",
      15: "Could not launch WhatsApp",
    },
    "chatShareSubject": {
      0: "چیٹ شیئر",
      1: "ਚੈਟ ਸਾਂਝਾ ਵਿਸ਼ਾ",
      2: "चैट शेयर विषय",
      3: "चैट शेयर विषय",
      4: "चैट शेयर विषय",
      5: "चैट शेयर विषय",
      6: "চ্যাট শেয়ার বিষয়",
      7: "ચેટ શેર વિષય",
      8: "চেট শ্বেয়াৰ বিষয়",
      9: "ଚାଟ୍ ସେୟାର ବିଷୟ",
      10: "चॅट शेअर विषय",
      11: "சாட் பகிர்வு பொருள்",
      12: "చాట్ షేర్ విషయం",
      13: "ಚಾಟ್ ಹಂಚಿಕೆ ವಿಷಯ",
      14: "ചാറ്റ് ഷെയർ വിഷയം",
      15: "Chat Share",
    },
    "couldNotLaunchEmail": {
      0: "ایمیل کلائنٹ لانچ نہیں ہو سکا",
      1: "ਈਮੇਲ ਕਲਾਇੰਟ ਸ਼ੁਰੂ ਨਹੀਂ ਕੀਤਾ ਜਾ ਸਕਿਆ",
      2: "ईमेल क्लाइंट लॉन्च नहीं होया",
      3: "ईमेल क्लाइंट लॉन्च नहीं हो सका",
      4: "ईमेल क्लाइंट लॉन्च नीं होयो",
      5: "ईमेल क्लाइंट लॉन्च ना हो पावल",
      6: "ইমেইল ক্লায়েন্ট চালু করা যায়নি",
      7: "ઈમેઇલ ક્લાયંટ લૉન્ચ કરી શકાયો નથી",
      8: "ইমেইল ক্লায়েন্ট আৰম্ভ কৰিব পৰা নগ'ল",
      9: "ଇମେଲ୍ କ୍ଲାଏଣ୍ଟ ଆରମ୍ଭ କରିପାରିଲା ନାହିଁ",
      10: "ईमेल क्लायंट लॉन्च करता आला नाही",
      11: "மின்னஞ்சல் கிளையன்ட் துவக்க முடியவில்லை",
      12: "ఇమెయిల్ క్లయింట్ ప్రారంభించలేము",
      13: "ಇமೇಲ್ ಕ್ಲೈಯಂಟ್ ಲಾಂಚ್ ಮಾಡಲಾಗಲಿಲ್ಲ",
      14: "ഇമെയിൽ ക്ലയന്റ് ലോഞ്ച് ചെയ്യാനായില്ല",
      15: "Could not launch Email client",
    },
    "like": {
      0: "پسند کریں",
      1: "ਪਸੰਦ ਕਰੋ",
      2: "लाइक",
      3: "लाइक",
      4: "लाइक",
      5: "लाइक",
      6: "পছন্দ করুন",
      7: "લાઈક કરો",
      8: "লাইক কৰক",
      9: "ଲାଇକ୍ କରନ୍ତୁ",
      10: "लाईक करा",
      11: "லைக் செய்யவும்",
      12: "లైక్",
      13: "ಲೈಕ್ ಮಾಡಿ",
      14: "ലൈക് ചെയ്യുക",
      15: "Like",
    },
    "comment": {
      0: "تبصرہ کریں",
      1: "ਟਿੱਪਣੀ ਕਰੋ",
      2: "टिप्पणी",
      3: "टिप्पणी",
      4: "टिप्पणी",
      5: "टिप्पणी",
      6: "মন্তব্য করুন",
      7: "ટિપ્પણી કરો",
      8: "মন্তব্য কৰক",
      9: "ଟିପ୍ପଣୀ କରନ୍ତୁ",
      10: "टिप्पणी करा",
      11: "கருத்து சொல்லவும்",
      12: "కమెంట్",
      13: "ಕಾಮೆಂಟ್ ಮಾಡಿ",
      14: "കമന്റ് ചെയ്യുക",
      15: "Comment",
    },
    "share": {
      0: "شیئر کریں",
      1: "ਸਾਂਝਾ ਕਰੋ",
      2: "शेयर",
      3: "साझा",
      4: "शेयर",
      5: "शेयर",
      6: "শেয়ার করুন",
      7: "શેર કરો",
      8: "শ্বেয়াৰ কৰক",
      9: "ସେୟାର୍ କରନ୍ତୁ",
      10: "शेअर करा",
      11: "பகிரவும்",
      12: "షేర్",
      13: "ಶೇರ್ ಮಾಡಿ",
      14: "പങ്കിടുക",
      15: "Share",
    },
    "feed": {
      0: "فِیڈ",
      1: "ਫੀਡ",
      2: "फ़ीड",
      3: "फीड",
      4: "फीड",
      5: "फीड",
      6: "ফিড",
      7: "ફીડ",
      8: "ফিড",
      9: "ଫିଡ",
      10: "फीड",
      11: "ஃபீட்",
      12: "ఫీడ్",
      13: "ಫೀಡ್",
      14: "ഫീഡ്",
      15: "Feed",
    },
    "noPosts": {
      0: "کوئی پوسٹ دستیاب نہیں",
      1: "ਕੋਈ ਪੋਸਟ ਉਪਲਬਧ ਨਹੀਂ",
      2: "कोई पोस्ट उपलब्ध नहीं",
      3: "कोई पोस्ट उपलब्ध नहीं",
      4: "कोई पोस्ट उपलब्ध नीं",
      5: "कोनो पोस्ट उपलब्ध नइखे",
      6: "কোনো পোস্ট উপলব্ধ নয়",
      7: "કોઈ પોસ્ટ ઉપલબ્ધ નથી",
      8: "কোনো প'ষ্ট উপলব্ধ নহয়",
      9: "କୌଣସି ପୋଷ୍ଟ ଉପଲବ୍ଧ ନୁହେଁ",
      10: "कोणतीही पोस्ट उपलब्ध नाही",
      11: "எந்தப் போஸ்டும் கிடைக்கவில்லை",
      12: "ఏ పోస్టు అందుబాటులో లేదు",
      13: "ಯಾವುದೇ ಪೋಸ್ಟ್ ಲಭ್ಯವಿಲ್ಲ",
      14: "ഏതെങ്കിലും പോസ്റ്റ് ലഭ്യമല്ല",
      15: "No posts available",
    },
    "errorLoadingImage": {
      0: "تصویر لوڈ کرنے میں خرابی",
      1: "ਤਸਵੀਰ ਲੋਡ ਕਰਨ ਵਿੱਚ ਗਲਤੀ",
      2: "छवि लोड करने में त्रुटि",
      3: "छवि लोड करने में त्रुटि",
      4: "छवि लोड करने में गलती",
      5: "इमेज लोड होखत में गलती भइल",
      6: "ছবি লোড করতে সমস্যা",
      7: "છબી લોડ કરવામાં ભૂલ",
      8: "ছবি লোড কৰাত ত্ৰুটি",
      9: "ଚିତ୍ର ଲୋଡ଼ କରିବାରେ ତ୍ରୁଟି",
      10: "प्रतिमा लोड करण्यात त्रुटी",
      11: "படம் ஏற்றும்போது பிழை",
      12: "చిత్రాన్ని లోడ్ చేయడంలో లోపం",
      13: "ಚಿತ್ರವನ್ನು ಲೋಡ್ ಮಾಡುವಲ್ಲಿ ದೋಷ",
      14: "ചിത്രം ലോഡുചെയ്യുമ്പോൾ പിശക്",
      15: "Error loading image",
    },
    // New key for "404 Error Not Found"
    "error404": {
      0: "404 ایرر: موجود نہیں",
      1: "404 ਗਲਤੀ: ਨਹੀਂ ਮਿਲੀ",
      2: "404 गलती: ना मिली",
      3: "404 त्रुटि: नहीं मिला",
      4: "404 त्रुटि: नहीं मिली",
      5: "404 गलती: ना मिली",
      6: "404 ত্রুটি: পাওয়া যায়নি",
      7: "404 ભૂલ: નથી મળ્યું",
      8: "404 ভুল: পোৱা নগ'ল",
      9: "404 ତ୍ରୁଟି: ମିଳିଲା ନାହିଁ",
      10: "404 त्रुटी: सापडली नाही",
      11: "404 பிழை: கண்டுபிடிக்கப்படவில்லை",
      12: "404 లోపం: కనబడలేదు",
      13: "404 ದೋಷ: ಕಂಡುಬಂದಿಲ್ಲ",
      14: "404 പിഴവ്: കണ്ടുകിടക്കുന്നില്ല",
      15: "404 Error: Not Found",
    },
  };

  /// Helper method to get the localized text for a given key.
  String getText(String key) {
    return localizedTexts[key]?[widget.languageIndex] ??
        localizedTexts[key]?[15] ??
        "";
  }

  // Firebase Realtime Database reference.
  final DatabaseReference _postsRef = FirebaseDatabase.instance.ref('posts');

  // Controller for the post text field.
  final TextEditingController _postController = TextEditingController();

  // Controllers for share dialog.
  final TextEditingController _exportWAController = TextEditingController();
  final TextEditingController _exportEmailController = TextEditingController();

  // Variables to store the media (image/video) in Base64 format and media type.
  String? _mediaBase64;
  String? _mediaType;

  // Set to track which posts the user has liked (simulate one like per user).
  final Set<String> _likedPosts = {};

  /// Opens the bottom sheet for creating a new post.
  void _openNewPostSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with title and Cancel button.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        getText("createPost"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          getText("cancel"),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _postController,
                    maxLines: 5,
                    style: const TextStyle(
                      color: Color(0xFFD1D1D1),
                    ),
                    decoration: InputDecoration(
                      hintText: getText("whatsOnYourMind"),
                      hintStyle: const TextStyle(
                        color: Color(0xFFB0B0B0),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF323232),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: const Color(0xFF5BC0EB)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5BC0EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _pickMedia,
                        icon: const Icon(Icons.attach_file),
                        label: Text(getText("addMedia")),
                      ),
                      const SizedBox(width: 16),
                      _mediaBase64 != null
                          ? const Icon(Icons.check, color: Colors.green)
                          : const SizedBox.shrink(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BC0EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final content = _postController.text.trim();
                        if (content.isNotEmpty || _mediaBase64 != null) {
                          await _postsRef.push().set({
                            "author": FirebaseAuth
                                    .instance.currentUser?.displayName ??
                                "Unknown",
                            "content": content,
                            "timestamp": DateTime.now().toIso8601String(),
                            "likes": 0,
                            "comments": {},
                            "media": _mediaBase64 ?? "",
                            "mediaType": _mediaType ?? ""
                          });
                          _postController.clear();
                          setState(() {
                            _mediaBase64 = null;
                            _mediaType = null;
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: Text(getText("post")),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Opens the file picker using ImagePicker in a bottom sheet.
  Future<void> _pickMedia() async {
    showModalBottomSheet(
      backgroundColor: const Color(0xFF101010),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: Color(0xFF5BC0EB)),
                title: Text(
                  getText("image"),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final picker = ImagePicker();
                  final pickedFile =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    final bytes = await pickedFile.readAsBytes();
                    String base64Image = base64Encode(bytes);
                    setState(() {
                      _mediaBase64 = base64Image;
                      _mediaType = 'image';
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Color(0xFF5BC0EB)),
                title: Text(
                  getText("video"),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(getText("videoNotSupported"))),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.attach_file, color: Color(0xFF5BC0EB)),
                title: Text(
                  getText("file"),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(getText("fileNotSupported"))),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Handles the "Like" functionality by incrementing the like count.
  /// Allows only one like per valid user.
  Future<void> _handleLike(String postId, int currentLikes) async {
    if (_likedPosts.contains(postId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getText("alreadyLiked")),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    await _postsRef.child(postId).update({"likes": currentLikes + 1});
    setState(() {
      _likedPosts.add(postId);
    });
  }

  /// Opens the comment sheet where users can view and add comments.
  void _openCommentSheet(String postId, Map<dynamic, dynamic> postData) {
    final TextEditingController commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            // Get existing comments if any.
            Map<dynamic, dynamic> comments = {};
            if (postData['comments'] != null) {
              comments = Map<dynamic, dynamic>.from(postData['comments']);
            }
            List<Map<dynamic, dynamic>> commentsList =
                comments.entries.map((entry) {
              return Map<dynamic, dynamic>.from(entry.value);
            }).toList();
            // Sort comments by recency.
            commentsList.sort((a, b) {
              final timeA =
                  DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
              final timeB =
                  DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
              return timeB.compareTo(timeA);
            });
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Column(
                children: [
                  // Top row with title and Cancel button.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        getText("comments"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          getText("cancel"),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: commentsList.length,
                      itemBuilder: (context, index) {
                        final comment = commentsList[index];
                        return ListTile(
                          title: Text(
                            comment['author'] ?? getText("anonymous"),
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            comment['content'] ?? "",
                            style: const TextStyle(color: Color(0xFFD1D1D1)),
                          ),
                          trailing: Text(
                            comment['timestamp'] ?? "",
                            style: const TextStyle(
                                color: Color(0xFFB0B0B0), fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: getText("addAComment"),
                            hintStyle:
                                const TextStyle(color: Color(0xFFB0B0B0)),
                            filled: true,
                            fillColor: const Color(0xFF323232),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: const Color(0xFF5BC0EB)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5BC0EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final commentContent = commentController.text.trim();
                          if (commentContent.isNotEmpty) {
                            await _postsRef
                                .child(postId)
                                .child("comments")
                                .push()
                                .set({
                              "author": FirebaseAuth
                                      .instance.currentUser?.displayName ??
                                  getText("anonymous"),
                              "content": commentContent,
                              "timestamp": DateTime.now().toIso8601String(),
                            });
                            commentController.clear();
                          }
                        },
                        child: Text(
                          getText("send"),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Opens a dialog to share the post content via WhatsApp or Email.
  void _handleShare(String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F1F1F),
          title: Text(
            getText("shareChat"),
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                getText("shareChatContent"),
                style: const TextStyle(color: Color(0xFFD1D1D1)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _exportWAController,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: getText("shareViaWA"),
                  hintText: getText("enterWANumber"),
                  prefixIcon: const Icon(Icons.message_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _exportEmailController,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(' '))
                ],
                decoration: InputDecoration(
                  labelText: getText("shareViaEmail"),
                  hintText: getText("enterEmail"),
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF5BC0EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      getText("cancel"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF5BC0EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final String waNumber = _exportWAController.text.trim();
                      final String email = _exportEmailController.text.trim();

                      // Check if at least one contact method is provided.
                      if (waNumber.isEmpty && email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(getText("enterContact"))),
                        );
                        return;
                      }

                      // Share via WhatsApp if a number is provided.
                      if (waNumber.isNotEmpty) {
                        final String message = Uri.encodeComponent(
                            "Hello, I wanted to share this chat with you.\n\n$content");
                        final String waUrl =
                            "https://wa.me/$waNumber?text=$message";

                        if (await canLaunch(waUrl)) {
                          await launch(waUrl);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(getText("couldNotLaunchWA"))),
                          );
                        }
                      }

                      // Share via Email if an email address is provided.
                      if (email.isNotEmpty) {
                        final String subject =
                            Uri.encodeComponent(getText("chatShareSubject"));
                        final String body = Uri.encodeComponent(
                            "Hello, I wanted to share this chat with you.\n\n$content");
                        final String emailUrl =
                            "mailto:$email?subject=$subject&body=$body";

                        if (await canLaunch(emailUrl)) {
                          await launch(emailUrl);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(getText("couldNotLaunchEmail"))),
                          );
                        }
                      }

                      Navigator.of(context).pop();
                    },
                    child: Text(
                      getText("send"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Builds the widget for a single post card.
  Widget _buildPostCard(String postId, Map<dynamic, dynamic> postData) {
    // Use the user's name from FirebaseAuth if available.
    final author = postData['author'] ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'Unknown';
    final content = postData['content'] ?? '';
    final timestamp = postData['timestamp'] ?? '';
    final likes = postData['likes'] ?? 0;
    final media = postData['media'] ?? "";
    final mediaType = postData['mediaType'] ?? "";

    return InkWell(
      onTap: () => _openCommentSheet(postId, postData),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Avatar, author, and timestamp.
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF323232),
                    child: Text(
                      author.isNotEmpty ? author[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timestamp,
                          style: const TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: const TextStyle(
                  color: Color(0xFFD1D1D1),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              // Display media if available.
              media != ""
                  ? mediaType == "image"
                      ? Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Image.memory(
                            base64Decode(media),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                getText("errorLoadingImage"),
                                style: const TextStyle(color: Colors.red),
                              );
                            },
                          ),
                        )
                      : mediaType == "video"
                          ? Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: VideoPlayerWidget(mediaBase64: media),
                            )
                          : const SizedBox.shrink()
                  : const SizedBox.shrink(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Like button.
                  InkWell(
                    onTap: () => _handleLike(postId, likes),
                    child: Row(
                      children: [
                        const Icon(Icons.thumb_up_alt_outlined,
                            size: 20, color: Color(0xFFB0B0B0)),
                        const SizedBox(width: 4),
                        Text(
                          "${getText("like")} ($likes)",
                          style: const TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Comment button.
                  InkWell(
                    onTap: () => _openCommentSheet(postId, postData),
                    child: Row(
                      children: [
                        const Icon(Icons.comment_outlined,
                            size: 20, color: Color(0xFFB0B0B0)),
                        const SizedBox(width: 4),
                        Text(
                          getText("comment"),
                          style: const TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Share button.
                  InkWell(
                    onTap: () => _handleShare(content),
                    child: Row(
                      children: [
                        const Icon(Icons.share_outlined,
                            size: 20, color: Color(0xFFB0B0B0)),
                        const SizedBox(width: 4),
                        Text(
                          getText("share"),
                          style: const TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Main build method.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<DatabaseEvent>(
        stream: _postsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                getText("error404"),
                style: TextStyle(color: Colors.red),
              ),
            );
          }
          if (snapshot.hasData) {
            final data = snapshot.data!.snapshot.value;
            if (data != null) {
              final postsMap = Map<String, dynamic>.from(data as Map);
              // Convert map to list and include the key for reference.
              List<Map<String, dynamic>> postsList =
                  postsMap.entries.map((entry) {
                var post = Map<String, dynamic>.from(entry.value as Map);
                post['key'] = entry.key;
                return post;
              }).toList();

              // Sort posts by engagement (likes + number of comments) and recency.
              postsList.sort((a, b) {
                int aLikes = a['likes'] ?? 0;
                int bLikes = b['likes'] ?? 0;
                int aComments = (a['comments'] != null)
                    ? (Map.from(a['comments']).length)
                    : 0;
                int bComments = (b['comments'] != null)
                    ? (Map.from(b['comments']).length)
                    : 0;
                int aEngagement = aLikes + aComments;
                int bEngagement = bLikes + bComments;
                DateTime aTime =
                    DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
                DateTime bTime =
                    DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();

                if (bEngagement != aEngagement) {
                  return bEngagement.compareTo(aEngagement);
                } else {
                  return bTime.compareTo(aTime);
                }
              });

              return ListView.builder(
                itemCount: postsList.length,
                itemBuilder: (context, index) {
                  return _buildPostCard(
                      postsList[index]['key'], postsList[index]);
                },
              );
            } else {
              return Center(
                child: Text(
                  getText("noPosts"),
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      // Place the floating button a bit higher (above the bottom nav bar)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 95.0),
        child: FloatingActionButton(
          onPressed: _openNewPostSheet,
          backgroundColor: const Color(0xFF5BC0EB),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

/// A helper function to return a basic InputDecoration.
InputDecoration textFormDecoration(String label, String hint, IconData icon,
    {required BuildContext context}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
  );
}

/// A widget that plays a video from Base64 data.

class VideoPlayerWidget extends StatefulWidget {
  final String mediaBase64;
  const VideoPlayerWidget({Key? key, required this.mediaBase64})
      : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    // Convert base64 to bytes, write to a temporary file, and initialize the controller.
    final bytes = base64Decode(widget.mediaBase64);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_video.mp4');
    await tempFile.writeAsBytes(bytes);
    _controller = VideoPlayerController.file(tempFile);
    await _controller!.initialize();
    setState(() {});
    _controller!.setLooping(true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(
        height: 200,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Stack(
        children: [
          VideoPlayer(_controller!),
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_controller!.value.isPlaying) {
                    _controller!.pause();
                  } else {
                    _controller!.play();
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
