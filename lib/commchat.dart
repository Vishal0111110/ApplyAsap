import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'user_controller.dart';
import 'community.dart';
import 'notification_service.dart';

// Chat translations map
const Map<String, List<String>> chatTranslations = {
  'noMessages': [
    'پیغامات نہ ہوند', // Kashmiri
    'ਕੋਈ ਸੁਨੇਹੇ ਨਹੀਂ', // Punjabi
    'संदेश ना हैं', // Haryanvi
    'कोई संदेश नहीं', // Hindi
    'कोई संदेश नीं', // Rajasthani
    'कोनो संदेश नइखे', // Bhojpuri
    'কোনো বার্তা নেই', // Bengali
    'કોઈ સંદેશા નથી', // Gujarati
    'কোনো বাৰ্তা নাই', // Assamese
    'କୌଣସି ସନ୍ଦେଶ ନାହିଁ', // Odia
    'कोणतेही संदेश नाहीत', // Marathi
    'செய்திகள் இல்லை', // Tamil
    'సందేశాలు లేవు', // Telugu
    'ಸಂದೇಶಗಳಿಲ್ಲ', // Kannada
    'സന്ദേശങ്ങളൊന്നുമില്ല', // Malayalam
    'No messages' // English
  ],
  'image': [
    'تصویر', // Kashmiri
    'ਤਸਵੀਰ', // Punjabi
    'तसवीर', // Haryanvi
    'छवि', // Hindi
    'छवि', // Rajasthani
    'तसवीर', // Bhojpuri
    'ছবি', // Bengali
    'છબી', // Gujarati
    'ছবি', // Assamese
    'ଛବି', // Odia
    'प्रतिमा', // Marathi
    'படம்', // Tamil
    'చిత్రం', // Telugu
    'ಚಿತ್ರ', // Kannada
    'ചിത്രം', // Malayalam
    'Image' // English
  ],
  'video': [
    'ویڈیو', // Kashmiri
    'ਵੀਡੀਓ', // Punjabi
    'वीडियो', // Haryanvi
    'वीडियो', // Hindi
    'वीडियो', // Rajasthani
    'वीडियो', // Bhojpuri
    'ভিডিও', // Bengali
    'વિડિઓ', // Gujarati
    'ভিডিঅ', // Assamese
    'ଭିଡିଓ', // Odia
    'व्हिडिओ', // Marathi
    'வீடியோ', // Tamil
    'వీడియో', // Telugu
    'ವೀಡಿಯೊ', // Kannada
    'വിഡിയോ', // Malayalam
    'Video' // English
  ],
  'file': [
    'فائل', // Kashmiri
    'ਫਾਇਲ', // Punjabi
    'फाइल', // Haryanvi
    'फ़ाइल', // Hindi
    'फाइल', // Rajasthani
    'फाइल', // Bhojpuri
    'ফাইল', // Bengali
    'ફાઇલ', // Gujarati
    'ফাইল', // Assamese
    'ଫାଇଲ୍', // Odia
    'फाइल', // Marathi
    'கோப்பு', // Tamil
    'ఫైలు', // Telugu
    'ಫೈಲ್', // Kannada
    'ഫയൽ', // Malayalam
    'File' // English
  ],
  'videoNotSupported': [
    'ویڈیو منسلکات کی حمایت نہیں', // Kashmiri
    'ਵੀਡੀਓ ਐਟੈਚਮੈਂਟਸ ਸਮਰਥਤ ਨਹੀਂ', // Punjabi
    'वीडियो अटैचमेंट सपोर्ट ना करें', // Haryanvi
    'वीडियो अटैचमेंट समर्थित नहीं', // Hindi
    'वीडियो अटैचमेंट समर्थित नहीं', // Rajasthani
    'वीडियो अटैचमेंट समर्थन ना होला', // Bhojpuri
    'ভিডিও সংযুক্তি সমর্থিত নয়', // Bengali
    'વિડિઓ એટેચમેન્ટ્સ સપોર્ટેડ નથી', // Gujarati
    'ভিডিঅ\' এটাচমেণ্ট সমৰ্থিত নহয়', // Assamese
    'ଭିଡିଓ ଏଟାଚମେଣ୍ଟ ସମର୍ଥିତ ନୁହେଁ', // Odia
    'व्हिडिओ अटॅचमेंट समर्थीत नाही', // Marathi
    'வீடியோ இணைப்புகள் ஆதரிக்கப்படவில்லை', // Tamil
    'వీడియో అటాచ్మెంట్లు సపోర్ట్ చేయబడవు', // Telugu
    'ವೀಡಿಯೊ ಅಟ್ಯಾಚ್‌ಮೆಂಟ್‌ಗಳು ಬೆಂಬಲಿಸಲ್ಪಡುತ್ತಿಲ್ಲ', // Kannada
    'വിഡിയോ അറ്റാച്ച്മെന്റുകൾ പിന്തുണയ്ക്കുന്നില്ല', // Malayalam
    'Video attachments are not supported.' // English
  ],
  'fileNotSupported': [
    'فائل منسلکات کی حمایت نہیں', // Kashmiri
    'ਫਾਇਲ ਐਟੈਚਮੈਂਟਸ ਸਮਰਥਤ ਨਹੀਂ', // Punjabi
    'फाइल अटैचमेंट सपोर्ट ना करें', // Haryanvi
    'फ़ाइल अटैचमेंट समर्थित नहीं', // Hindi
    'फ़ाइल अटैचमेंट समर्थित नहीं', // Rajasthani
    'फाइल अटैचमेंट समर्थन ना होला', // Bhojpuri
    'ফাইল সংযুক্তি সমর্থিত নয়', // Bengali
    'ફાઇલ એટેચમેન્ટ્સ સપોર્ટેડ નથી', // Gujarati
    'ফাইল এটাচমেণ্ট সমৰ্থিত নহয়', // Assamese
    'ଫାଇଲ୍ ଏଟାଚମେଣ୍ଟ ସମର୍ଥିତ ନୁହେଁ', // Odia
    'फाइल अटॅचमेंट समर्थीत नाही', // Marathi
    'கோப்பு இணைப்புகள் ஆதரிக்கப்படவில்லை', // Tamil
    'ఫైల్ అటాచ్మెంట్లు సపోర్ట్ చేయబడవు', // Telugu
    'ಫೈಲ್ ಅಟ್ಯಾಚ್‌ಮೆಂಟ್‌ಗಳು ಬೆಂಬಲಿಸಲ್ಪಡುತ್ತಿಲ್ಲ', // Kannada
    'ഫയൽ അറ്റാച്ച്മെന്റുകൾ പിന്തുണയ്ക്കുന്നില്ല', // Malayalam
    'File attachments are not supported.' // English
  ],
  'typeYourMessage': [
    'اپنا پیغام لکھیں...', // Kashmiri
    'ਆਪਣਾ ਸੁਨੇਹਾ ਲਿਖੋ...', // Punjabi
    'आपणो संदेश लिखो...', // Haryanvi
    'अपना संदेश टाइप करें...', // Hindi
    'अपनो संदेश लिखो...', // Rajasthani
    'आपन संदेश टाइप करीं...', // Bhojpuri
    'আপনার বার্তা লিখুন...', // Bengali
    'તમારો સંદેશ ટાઇપ કરો...', // Gujarati
    'আপোনাৰ বাৰ্তা টাইপ কৰক...', // Assamese
    'ଆପଣଙ୍କର ସନ୍ଦେଶ ଟାଇପ୍ କରନ୍ତୁ...', // Odia
    'तुमचा संदेश टाइप करा...', // Marathi
    'உங்கள் செய்தியை தட்டச்சு செய்யவும்...', // Tamil
    'మీ సందేశాన్ని టైప్ చేయండి...', // Telugu
    'ನಿಮ್ಮ ಸಂದೇಶವನ್ನು ಟೈಪ್ ಮಾಡಿ...', // Kannada
    'നിങ്ങളുടെ സന്ദേശം ടൈപ്പ് ചെയ്യുക...', // Malayalam
    'Type your message...' // English
  ],
};

/// Helper function to get the translated text based on a key and language index.
String chatTranslate(String key, int languageIndex) {
  return chatTranslations[key]?[languageIndex] ??
      chatTranslations[key]?[15] ??
      key;
}

// The CommunityChatPage now receives both the Community object and a language index.
class CommunityChatPage extends StatefulWidget {
  final Community community;
  final int languageIndex;

  const CommunityChatPage({
    Key? key,
    required this.community,
    required this.languageIndex,
  }) : super(key: key);

  @override
  _CommunityChatPageState createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late DatabaseReference _messagesRef;
  final String? currentUserId = UserController.user?.uid;

  @override
  void initState() {
    super.initState();
    _messagesRef = FirebaseDatabase.instance
        .ref()
        .child('communityChats')
        .child(widget.community.key)
        .child('messages');
  }

  // Send a text message.
  Future<void> _sendMessage({String? fileUrl, String? fileType}) async {
    String messageText = _messageController.text.trim();
    if (messageText.isEmpty && fileUrl == null) return;
    final currentUser = UserController.user;
    if (currentUser == null) return;

    try {
      await _messagesRef.push().set({
        'senderId': currentUser.uid,
        'senderEmail': currentUser.displayName,
        'message': messageText,
        'fileUrl': fileUrl,
        'fileType': fileType, // image, video, or file
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'status': 'sent',
      });

      // Send notification for community message
      final notificationService = NotificationService();
      await notificationService.sendCommunityMessageNotification(
          widget.community.key,
          widget.community.name,
          currentUser.uid,
          currentUser.displayName ?? "Unknown User",
          messageText.isNotEmpty ? messageText : 'Image');

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  // Function to pick attachments (currently only handles images with Base64 conversion).
  Future<void> _pickAttachment() async {
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
                  chatTranslate('image', widget.languageIndex),
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
                    await _sendMessage(fileUrl: base64Image, fileType: 'image');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Color(0xFF5BC0EB)),
                title: Text(
                  chatTranslate('video', widget.languageIndex),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        chatTranslate(
                            'videoNotSupported', widget.languageIndex),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.attach_file, color: Color(0xFF5BC0EB)),
                title: Text(
                  chatTranslate('file', widget.languageIndex),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        chatTranslate('fileNotSupported', widget.languageIndex),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageItem(
      BuildContext context, Map<dynamic, dynamic> messageData) {
    final String senderEmail = messageData['senderEmail'] ?? 'Unknown';
    final String message = messageData['message'] ?? '';
    final int timestamp = messageData['timestamp'] ?? 0;
    final String fileUrl = messageData['fileUrl'] ?? '';
    final String fileType = messageData['fileType'] ?? '';
    final bool isMe = messageData['senderId'] == currentUserId;
    final DateTime time = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final String formattedTime =
        "${time.hour}:${time.minute.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, top: 2, bottom: 2),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender's email display with ellipsis.
          if (!isMe)
            Container(
              margin: const EdgeInsets.only(bottom: 1, left: 8),
              child: Text(
                senderEmail,
                style: const TextStyle(
                  color: Colors.teal,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // Message bubble.
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.80),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            margin: const EdgeInsets.only(left: 4, right: 4),
            decoration: BoxDecoration(
              color: isMe ? Colors.teal : Colors.grey[750],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft:
                    isMe ? const Radius.circular(18) : const Radius.circular(2),
                bottomRight:
                    isMe ? const Radius.circular(2) : const Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message.isNotEmpty)
                  Text(
                    message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                if (fileUrl.isNotEmpty && fileType == 'image')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        base64Decode(fileUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                            height: 80,
                            color: Colors.grey[600],
                            child: const Icon(Icons.broken_image, size: 20)),
                      ),
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  formattedTime,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(
          widget.community.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _messagesRef.orderByChild('timestamp').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data?.snapshot.value == null) {
                  return Center(
                      child: Text(
                    chatTranslate('noMessages', widget.languageIndex),
                    style: const TextStyle(color: Colors.white),
                  ));
                }
                Map<dynamic, dynamic> messagesMap =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<Map<dynamic, dynamic>> messages = [];
                messagesMap.forEach((key, value) {
                  messages.add(value);
                });
                messages.sort((a, b) =>
                    (a['timestamp'] as int).compareTo(b['timestamp'] as int));
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      _buildMessageItem(context, messages[index]),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey[900],
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.tealAccent),
                  onPressed: _pickAttachment,
                  iconSize: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: chatTranslate(
                            'typeYourMessage', widget.languageIndex),
                        hintStyle: const TextStyle(
                            color: Colors.white60, fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.tealAccent),
                  onPressed: () => _sendMessage(),
                  iconSize: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
