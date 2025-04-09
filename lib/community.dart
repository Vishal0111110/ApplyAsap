import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert'; // For Base64 conversion
// Your existing UserController
import 'commchat.dart';

// Community model
class Community {
  final String key;
  final String name;
  final String description;
  final String imageUrl; // This will now store a Base64 string
  final bool isPublic;
  final String joinCode;
  final Map<dynamic, dynamic>? members;

  Community({
    required this.key,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.isPublic,
    required this.joinCode,
    this.members,
  });

  factory Community.fromData(String key, Map<dynamic, dynamic> data) {
    return Community(
      key: key,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isPublic: data['isPublic'] ?? true,
      joinCode: data['joinCode'] ?? '',
      members: data['members'],
    );
  }
}

// Mapping integer index to language name
// 0  - Kashmiri, 1  - Punjabi, 2  - Haryanvi, 3  - Hindi,
// 4  - Rajasthani, 5  - Bhojpuri, 6  - Bengali, 7  - Gujarati,
// 8  - Assamese, 9  - Odia, 10 - Marathi, 11 - Tamil,
// 12 - Telugu, 13 - Kannada, 14 - Malayalam, 15 - English
const List<String> languageNames = [
  'Kashmiri',
  'Punjabi',
  'Haryanvi',
  'Hindi',
  'Rajasthani',
  'Bhojpuri',
  'Bengali',
  'Gujarati',
  'Assamese',
  'Odia',
  'Marathi',
  'Tamil',
  'Telugu',
  'Kannada',
  'Malayalam',
  'English'
];

// Translation map for all texts displayed on screen.
// For demonstration, each translation is simulated by prefixing the text with the language name.
// In a real app, replace the values with actual translated strings.
const Map<String, List<String>> translations = {
  'enterJoinCode': [
    // Kashmiri (using a style similar to Urdu)
    'جوٚن کوڈ داخل کریں',
    // Punjabi (Gurmukhi)
    'ਜੋੜਨ ਕੋਡ ਦਰਜ ਕਰੋ',
    // Haryanvi (similar to Hindi)
    'जॉइन कोड भरें',
    // Hindi
    'जॉइन कोड दर्ज करें',
    // Rajasthani
    'जॉइन कोड डालो',
    // Bhojpuri
    'जॉइन कोड दर्ज करीं',
    // Bengali
    'যোগ কোড লিখুন',
    // Gujarati
    'જોઈન કોડ દાખલ કરો',
    // Assamese
    'যোগ কোড প্ৰৱেশ কৰক',
    // Odia
    'ଜୋଇନ୍ କୋଡ୍ ପ୍ରବେଶ କରନ୍ତୁ',
    // Marathi
    'जॉइन कोड प्रविष्ट करा',
    // Tamil
    'சேரும் குறியீட்டை உள்ளிடவும்',
    // Telugu
    'జాయిన్ కోడ్ నమోదు చేయండి',
    // Kannada
    'ಜೋನ್ ಕೋಡ್ ನಮೂದಿಸಿ',
    // Malayalam
    'ജോയിൻ കോഡ് നൽകുക',
    // English
    'Enter Join Code',
  ],
  'cancel': [
    'کینسل کریں',
    'ਰੱਦ ਕਰੋ',
    'रद्द कर दे',
    'रद्द करें',
    'रद्द करो',
    'रद्द करीं',
    'বাতিল করুন',
    'રદ્દ કરો',
    'বাতিল কৰক',
    'ବାତିଲ୍ କରନ୍ତୁ',
    'रद्द करा',
    'ரத்து செய்',
    'రద్దు చేయండి',
    'ರದ್ದುಮಾಡಿ',
    'റദ്ദാക്കുക',
    'Cancel',
  ],
  'join': [
    'جوٚن کریں',
    'ਜੋੜੋ',
    'जॉइन हो',
    'शामिल हों',
    'जॉइन करो',
    'जॉइन करीं',
    'যোগ দিন',
    'જોઇન કરો',
    'যোগ দিন',
    'ଯୋଗ ଦିଅନ୍ତୁ',
    'जॉइन करा',
    'சேரவும்',
    'జాయిన్ అవ్వండి',
    'ಜೋನ್ ಮಾಡಿ',
    'ചേർക്കുക',
    'Join',
  ],
  'incorrectJoinCode': [
    'غلط جوٚن کوڈ.',
    'ਗਲਤ ਜੋੜਨ ਕੋਡ।',
    'गलत जॉइन कोड।',
    'गलत जॉइन कोड।',
    'गलत जॉइन कोड।',
    'गलत जॉइन कोड।',
    'ভুল যোগ কোড।',
    'ખોટો જોડાણ કોડ.',
    'ভুল যোগ কোড।',
    'ଭୁଲ୍ ଜୋଇନ୍ କୋଡ୍।',
    'चुकीचा जॉइन कोड.',
    'தவறான சேரும் குறியீடு.',
    'తప్పు జాయిన్ కోడ్.',
    'ತಪ್ಪು ಜೋನ್ ಕೋಡ್.',
    'തെറ്റായ ജോയിൻ കോഡ്.',
    'Incorrect join code.',
  ],
  'createCommunity': [
    'کمیونٹی تشکیل دیں',
    'ਕਮਿਊਨਿਟੀ ਬਣਾਓ',
    'समुदाय बनाओ',
    'समुदाय बनाएँ',
    'समुदाय बनाओ',
    'समुदाय बनाईं',
    'কমিউনিটি তৈরি করুন',
    'સમુદાય બનાવો',
    'সম্প্ৰদায় সৃষ্টি কৰক',
    'ସମୁଦାୟ ସೃଜନ କରନ୍ତୁ',
    'समुदाय तयार करा',
    'சமூகத்தை உருவாக்கு',
    'సమూహాన్ని సృష్టించండి',
    'ಸಮುದಾಯವನ್ನು ರಚಿಸಿ',
    'സമൂഹം സൃഷ്ടിക്കുക',
    'Create Community',
  ],
  'name': [
    'نام',
    'ਨਾਂ',
    'नाम',
    'नाम',
    'नाम',
    'नाम',
    'নাম',
    'નામ',
    'নাম',
    'ନାମ',
    'नाव',
    'பெயர்',
    'పేరు',
    'ಹೆಸರು',
    'പേര്',
    'Name',
  ],
  'enterName': [
    'ایک نام داخل کریں',
    'ਇੱਕ ਨਾਮ ਦਰਜ ਕਰੋ',
    'एक नाम भरें',
    'एक नाम दर्ज करें',
    'एक नाम डालो',
    'एक नाम दर्ज करीं',
    'একটি নাম লিখুন',
    'એક નામ દાખલ કરો',
    'এখন নাম প্ৰৱেশ কৰক',
    'ଏକ ନାମ ପ୍ରବେଶ କରନ୍ତୁ',
    'एक नाव प्रविष्ट करा',
    'ஒரு பெயரை உள்ளிடவும்',
    'ఒక పేరు నమోదు చేయండి',
    'ಒಂದು ಹೆಸರನ್ನು ನಮೂದಿಸಿ',
    'ഒരു പേര് നൽകുക',
    'Enter a name',
  ],
  'description': [
    'تفصیل',
    'ਵੇਰਵਾ',
    'विवरण',
    'विवरण',
    'विवरण',
    'विवरण',
    'বর্ণনা',
    'વર્ણન',
    'বিৱৰণ',
    'ବର୍ଣ୍ଣନା',
    'वर्णन',
    'விவரம்',
    'వివరణ',
    'ವಿವರಣೆ',
    'വിവരണം',
    'Description',
  ],
  'enterDescription': [
    'ایک تفصیل داخل کریں',
    'ਇੱਕ ਵੇਰਵਾ ਦਰਜ ਕਰੋ',
    'एक विवरण भरें',
    'एक विवरण दर्ज करें',
    'एक विवरण डालो',
    'एक विवरण दर्ज करीं',
    'একটি বর্ণনা লিখুন',
    'એક વર્ણન દાખલ કરો',
    'এখন বিৱৰণ প্ৰৱেশ কৰক',
    'ଏକ ବର୍ଣ୍ଣନା ପ୍ରବେଶ କରନ୍ତୁ',
    'एक वर्णन प्रविष्ट करा',
    'ஒரு விவரத்தை உள்ளிடவும்',
    'ఒక వివరణ నమోదు చేయండి',
    'ಒಂದು ವಿವರಣೆಯನ್ನು ನಮೂದಿಸಿ',
    'ഒരു വിവരണം നൽകുക',
    'Enter a description',
  ],
  'selectImage': [
    'تصویر منتخب کریں',
    'ਤਸਵੀਰ ਚੁਣੋ',
    'चित्र चुनो',
    'चित्र चुनें',
    'चित्र चुनो',
    'चित्र चुनल जाव',
    'ছবি নির্বাচন করুন',
    'છબી પસંદ કરો',
    'চিত্ৰ বাচক কৰক',
    'ଛବି ବାଛନ୍ତୁ',
    'प्रतिमा निवडा',
    'படத்தை தேர்ந்தெடுக்கவும்',
    'చిత్రాన్ని ఎంచుకోండి',
    'ಚಿತ್ರ ಆಯ್ಕೆಮಾಡಿ',
    'ചിത്രം തിരഞ്ഞെടുക്കുക',
    'Select Image',
  ],
  'publicCommunity': [
    'عوامی کمیونٹی',
    'ਸਾਰਵਜਨਿਕ ਕਮਿਊਨਿਟੀ',
    'सार्वजनिक समुदाय',
    'सार्वजनिक समुदाय',
    'सार्वजनिक समुदाय',
    'सार्वजनिक समुदाय',
    'সার্বজনীন কমিউনিটি',
    'જાહેર સમુદાય',
    'সাৰ্বজনীন সম্প্ৰদায়',
    'ସାର୍ବଜନୀନ ସମୁଦାୟ',
    'सार्वजनिक समुदाय',
    'பொது சமூக',
    'ప్రజా సంఘం',
    'ಸಾರ್ವಜನಿಕ ಸಮುದಾಯ',
    'പൊതു സമൂഹം',
    'Public Community',
  ],
  'enterJoinCodeInvite': [
    'صرف دعوتی کمیونٹی کے لیے جوٚن کوڈ داخل کریں',
    'ਨਿਮੰਤ੍ਰਿਤ ਸਮੁਦਾਇ ਲਈ ਜੋੜਨ ਕੋਡ ਦਰਜ ਕਰੋ',
    'निमंत्रण वाली समुदाय के लिए जॉइन कोड दर्ज करें',
    'निमंत्रण-केवल समुदाय के लिए जॉइन कोड दर्ज करें',
    'निमंत्रण-केवल समुदाय के लिए जॉइन कोड डालो',
    'निमंत्रण-केवल समुदाय खातिर जॉइन कोड दर्ज करीं',
    'ইনভাইট-ওনলি কমিউনিটির জন্য যোগ কোড লিখুন',
    'નિમંત્રણ પર આધારિત સમુદાય માટે જોડાણ કોડ દાખલ કરો',
    'অহ্বানৰ বাবে বিশেষ সম্প্ৰদায়ৰ বাবে যোগ কোড প্ৰৱেশ কৰক',
    'ମାତ୍ର ଆମନ୍ତ୍ରିତ ସମୁଦାୟ ପାଇଁ ଜୋଇନ୍ କୋଡ୍ ପ୍ରବେଶ କରନ୍ତୁ',
    'फक्त निमंत्रणासाठीच्या समुदायासाठी जॉइन कोड प्रविष्ट करा',
    'அழைப்புக்கேற்ப சமூகத்திற்கு சேரும் குறியீட்டை உள்ளிடவும்',
    'ఆహ్వానితుల కోసం మాత్రమే ఉన్న కమ్యూనిటీకి జాయిన్ కోడ్ నమోదు చేయండి',
    'ಅಹ್ವಾನಿತ ಸಮುದಾಯಕ್ಕೆ ಸೇರಲು ಕೋಡ್ ನಮೂದಿಸಿ',
    'ആഹ്വാനമുള്ള സമുദായത്തിനുള്ള ജോയിൻ കോഡ് നൽകുക',
    'Enter a join code for invite-only community',
  ],
  'create': [
    'تخلیق کریں',
    'ਬਣਾਓ',
    'बनाओ',
    'बनाएँ',
    'बनाओ',
    'बनाईं',
    'তৈরি করুন',
    'બણાવો',
    'সৃষ্টি কৰক',
    'ତିଆରି କରନ୍ତୁ',
    'तयार करा',
    'உருவாக்கு',
    'సృష్టించండి',
    'ರಚಿಸಿ',
    'സൃഷ്ടിക്കുക',
    'Create',
  ],
  'joined': [
    'شامل ہو گئے',
    'ਸ਼ਾਮਿਲ ਹੋ ਚੁੱਕੇ',
    'शामिल हो गए',
    'शामिल हो गए',
    'शामिल हो गए',
    'जॉइन हो गइल',
    'যোগদান করা হয়েছে',
    'જોડાયા',
    'যোগদান কৰা হৈছে',
    'ଜୋଡି ହୋଇଛି',
    'जॉइन झाले',
    'சேர்ந்துவிட்டது',
    'చేరినది',
    'ಸೇರಿದೆ',
    'ചേര്‍ന്നു',
    'JOINED',
  ],
  'userNotLoggedIn': [
    'یوزر لاگ ان نہ ہوٙ',
    'ਵਰਤੋਂਕਾਰ ਲਾਗਿਨ ਨਹੀਂ ਕੀਤਾ।',
    'यूजर लॉग इन नहीं है।',
    'उपयोगकर्ता लॉग इन नहीं है।',
    'यूजर लॉग इन नहीं है।',
    'यूजर लॉग इन नइखे।',
    'ব্যবহারকারী লগ ইন করেনি।',
    'વપરાશકર્તા લોગિન નથી',
    'ব্যৱহাৰকাৰী লগ ইন কৰা নাই।',
    'ଉପଭୋକ୍ତା ଲଗଇନ୍ କରିନାହାନ୍ତି',
    'वापरकर्ता लॉग इन नाही आहे.',
    'பயனர் உள்நுழையவில்லை.',
    'వాడుకరి లాగిన్ కాలేదు.',
    'ಬಳಕೆದಾರ ಲಾಗಿನ್ ಆಗಿಲ್ಲ.',
    'ഉപയോക്താവ് ലോഗിൻ ചെയ്തിട്ടില്ല.',
    'User not logged in.',
  ],
  'noCommunitiesAvailable': [
    'کوئی کمیونٹی دستیاب نہیں',
    'ਕੋਈ ਕਮਿਊਨਿਟੀ ਉਪਲਬਧ ਨਹੀਂ',
    'कोई समुदाय उपलब्ध नहीं है',
    'कोई समुदाय उपलब्ध नहीं है',
    'कोई समुदाय उपलब्ध नहीं है',
    'कवनो समुदाय उपलब्ध नइखे',
    'কোনও কমিউনিটি উপলব্ধ নয়',
    'કોઈ સમુદાય ઉપલબ્ધ નથી',
    'কোনো সম্প্ৰদায় উপলব্ধ নাই',
    'କୌଣସି ସମୁଦାୟ ଉପଲବ୍ଧ ନୁହେଁ',
    'कोणतेही समुदाय उपलब्ध नाहीत',
    'எந்த சமூகமும் இல்லை',
    'ఏ కమ్యూనిటీ లభ్యం లేదు',
    'ಯಾವುದೇ ಸಮುದಾಯ ಲಭ್ಯವಿಲ್ಲ',
    'ഏതെങ്കിലും സമൂഹം ലഭ്യമല്ല',
    'No communities available',
  ],
  'noCommunitiesFound': [
    'کوئی کمیونٹی نہیں ملی',
    'ਕੋਈ ਕਮਿਊਨਿਟੀ ਨਹੀਂ ਮਿਲੀ',
    'कोई समुदाय नहीं मिला',
    'कोई समुदाय नहीं मिला',
    'कोई समुदाय नहीं मिला',
    'कवनो समुदाय ना मिलल',
    'কোনও কমিউনিটি পাওয়া যায়নি',
    'કોઈ સમુદાય મળ્યો નથી',
    'কোনো সম্প্ৰদায় পোৱা নগল',
    'କୌଣସି ସମୁଦାୟ ମିଳିନାହିଁ',
    'कोणतेही समुदाय सापडले नाहीत',
    'எந்த சமூகமும் கிடைக்கவில்லை',
    'ఏ కమ్యూనిటీ కనబడలేదు',
    'ಯಾವುದೇ ಸಮುದಾಯ ಕಂಡುಬಂದಿಲ್ಲ',
    'ഏതെങ്കിലും സമൂഹം കണ്ടെത്തിയിട്ടില്ല',
    'No communities found',
  ],
};

/// Helper function to get the translated text based on key and the language index.
String translate(String key, int languageIndex) {
  // If for some reason the key or index is not available, default to English text.
  return translations[key]?[languageIndex] ?? translations[key]?[15] ?? key;
}

// Main Community Page which now takes an integer to determine the language.
class CommunityPage extends StatefulWidget {
  final int languageIndex; // Language index passed from the parent

  const CommunityPage({Key? key, required this.languageIndex})
      : super(key: key);

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final DatabaseReference _communitiesRef =
      FirebaseDatabase.instance.ref().child('communities');
  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Get the current user id from your UserController

  // Using XFile instead of File to be platform-friendly.
  XFile? imageFile;

  // Helper: Join community by adding the current user's uid to the members list
  Future<void> joinCommunity(Community community) async {
    if (currentUserId == null) return;
    final communityRef = _communitiesRef.child(community.key).child('members');
    try {
      await communityRef.update({currentUserId!: true});
      print('User $currentUserId joined community ${community.key}');
    } catch (e) {
      print('Error joining community: $e');
    }
  }

  // If the community is invite-only, ask for join code.
  Future<void> _showJoinCodeDialog(Community community) async {
    String enteredCode = '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101010),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          translate('enterJoinCode', widget.languageIndex),
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          onChanged: (value) {
            enteredCode = value;
          },
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: translate('join', widget.languageIndex) +
                ' ' +
                translate('joinCode', widget.languageIndex),
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF5BC0EB)),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5BC0EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    translate('cancel', widget.languageIndex),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5BC0EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    if (enteredCode.trim() == community.joinCode) {
                      await joinCommunity(community);
                      Navigator.of(context).pop();
                      setState(() {}); // refresh UI
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            translate(
                                'incorrectJoinCode', widget.languageIndex),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    translate('join', widget.languageIndex),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Create community dialog with refined UI.
  Future<void> _showCreateCommunityDialog() async {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String description = '';
    bool isPublic = true;
    String joinCode = '';

    Future<void> _pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          imageFile = pickedFile;
        });
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            backgroundColor: const Color(0xFF101010),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: Text(
              translate('createCommunity', widget.languageIndex),
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: translate('name', widget.languageIndex),
                        labelStyle: const TextStyle(color: Colors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[800]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Color(0xFF5BC0EB)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) => name = value,
                      validator: (value) => value == null || value.isEmpty
                          ? translate('enterName', widget.languageIndex)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText:
                            translate('description', widget.languageIndex),
                        labelStyle: const TextStyle(color: Colors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[800]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Color(0xFF5BC0EB)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) => description = value,
                      validator: (value) => value == null || value.isEmpty
                          ? translate('enterDescription', widget.languageIndex)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5BC0EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.image, color: Colors.white),
                        label: Text(
                          translate('selectImage', widget.languageIndex),
                          style: const TextStyle(color: Colors.white),
                        ),
                        onPressed: () async {
                          await _pickImage();
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: Text(
                        translate('publicCommunity', widget.languageIndex),
                        style: const TextStyle(color: Colors.white),
                      ),
                      value: isPublic,
                      activeColor: const Color(0xFF5BC0EB),
                      onChanged: (value) {
                        setStateSB(() {
                          isPublic = value;
                        });
                      },
                    ),
                    if (!isPublic)
                      Column(
                        children: [
                          const SizedBox(height: 10),
                          TextFormField(
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: translate(
                                      'join', widget.languageIndex) +
                                  ' ' +
                                  translate('joinCode', widget.languageIndex),
                              labelStyle: const TextStyle(color: Colors.white),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.grey[800]!),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Color(0xFF5BC0EB)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (value) => joinCode = value,
                            validator: (value) => (!isPublic &&
                                    (value == null || value.isEmpty))
                                ? translate(
                                    'enterJoinCodeInvite', widget.languageIndex)
                                : null,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BC0EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        translate('cancel', widget.languageIndex),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2), // Added spacing between buttons
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BC0EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          if (currentUserId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  translate(
                                      'userNotLoggedIn', widget.languageIndex),
                                ),
                              ),
                            );
                            return;
                          }
                          final newCommunityRef = _communitiesRef.push();
                          String imageUrl = '';
                          // Convert image to Base64 string if selected.
                          if (imageFile != null) {
                            try {
                              final bytes = await imageFile!.readAsBytes();
                              imageUrl = base64Encode(bytes);
                            } catch (e) {
                              print('Error converting image: $e');
                            }
                          }
                          await newCommunityRef.set({
                            'name': name,
                            'description': description,
                            'imageUrl': imageUrl,
                            'isPublic': isPublic,
                            'joinCode': isPublic ? '' : joinCode,
                            'members': {currentUserId!: true},
                            'createdAt': DateTime.now().millisecondsSinceEpoch,
                          });
                          print(
                              'Community created with key: ${newCommunityRef.key}');
                          Navigator.of(context).pop();
                          setState(() {}); // refresh UI to show new community
                        }
                      },
                      child: Text(
                        translate('create', widget.languageIndex),
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
      ),
    );
  }

  // Build each community card with refined UI.
  Widget _buildCommunityCard(Community community) {
    final bool isJoined = community.members != null &&
        community.members!.containsKey(currentUserId);
    return Card(
      color: const Color(0xFF1F1F1F),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (isJoined) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommunityChatPage(
                    community: community, languageIndex: widget.languageIndex),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Community image at the top (decodes the Base64 string)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: community.imageUrl.isNotEmpty
                  ? Image.memory(
                      base64Decode(community.imageUrl),
                      height: 150,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 150,
                      color: Colors.grey[800],
                      child: const Icon(Icons.group,
                          color: Colors.white, size: 50),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and JOINED badge if applicable
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          community.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isJoined)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5BC0EB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            translate('joined', widget.languageIndex),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description with ellipsis.
                  Text(
                    community.description,
                    style: const TextStyle(color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Join button if not already a member
            if (!isJoined)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5BC0EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    if (community.isPublic) {
                      await joinCommunity(community);
                      setState(() {});
                    } else {
                      await _showJoinCodeDialog(community);
                    }
                  },
                  child: Text(
                    translate('join', widget.languageIndex),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build list view for communities.
  Widget _buildCommunityList(List<Community> communities) {
    if (communities.isEmpty) {
      return Center(
        child: Text(
          translate('noCommunitiesAvailable', widget.languageIndex),
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: communities.length,
      itemBuilder: (context, index) {
        return _buildCommunityCard(communities[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: StreamBuilder(
          stream: _communitiesRef.onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BC0EB)),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
              return Center(
                child: Text(
                  translate('noCommunitiesFound', widget.languageIndex),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            Map<dynamic, dynamic> communitiesMap =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            List<Community> communities = [];
            communitiesMap.forEach((key, value) {
              communities.add(Community.fromData(key, value));
            });
            return _buildCommunityList(communities);
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF5BC0EB),
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: _showCreateCommunityDialog,
        ),
      ),
    );
  }
}
