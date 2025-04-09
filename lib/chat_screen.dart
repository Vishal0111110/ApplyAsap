
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'web.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:markdown_widget/config/all.dart';
import 'package:markdown_widget/widget/markdown.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'question_data.dart';
import 'widgets.dart';

Map<String, dynamic> getLocalizedTexts(String lang) {
  switch (lang) {
    case "कश्मीरी":
      return {
        "chatTitle": "فرینڈ سے بات کریں",
        "shareChat": "چیٹ شیئر کریں",
        "shareChatContent": "آپ اپنی گفتگو کو کس طرح شیئر کرنا چاہیں گے؟",
        "shareViaWA": "واٹس ایپ کے ذریعے شیئر کریں",
        "enterWANumber": "اپنا WA نمبر درج کریں",
        "shareViaEmail": "ای میل کے ذریعے شیئر کریں",
        "enterEmail": "اپنا ای میل پتہ درج کریں",
        "cancel": "منسوخ کریں",
        "couldNotLaunchOverleaf": "اوورلیف URL لانچ نہیں ہو سکا",
        "messageHint": "آپ کیا جاننا چاہیں گے...",
        "you": "آپ",
        "friday": "فرائیڈے",
        "openInOverleaf": "اوورلیف میں کھولیں",
        "loadingPhrases": [],
        "initialMessage": "مجھے [\${widget.career}] کیوں تجویز کیا گیا؟"
      };
    case "ਪੰਜਾਬੀ":
      return {
        "chatTitle": "ਫ੍ਰਾਈਡੇ ਨਾਲ ਗੱਲ ਕਰੋ",
        "shareChat": "ਚੈਟ ਸਾਂਝੀ ਕਰੋ",
        "shareChatContent": "ਤੁਸੀਂ ਆਪਣੀ ਗੱਲਬਾਤ ਕਿਵੇਂ ਸਾਂਝੀ ਕਰਨਾ ਚਾਹੋਗੇ?",
        "shareViaWA": "ਵਟਸਐਪ ਰਾਹੀਂ ਸਾਂਝਾ ਕਰੋ",
        "enterWANumber": "ਆਪਣਾ WA ਨੰਬਰ ਦਰਜ ਕਰੋ",
        "shareViaEmail": "ਈਮੇਲ ਰਾਹੀਂ ਸਾਂਝਾ ਕਰੋ",
        "enterEmail": "ਆਪਣਾ ਈਮੇਲ ਪਤਾ ਦਰਜ ਕਰੋ",
        "cancel": "ਰੱਦ ਕਰੋ",
        "couldNotLaunchOverleaf": "Overleaf URL ਲਾਂਚ ਨਹੀਂ ਹੋ ਸਕਿਆ",
        "messageHint": "ਤੁਸੀਂ ਕੀ ਜਾਣਨਾ ਚਾਹੋਗੇ...",
        "you": "ਤੁਸੀਂ",
        "friday": "ਫ੍ਰਾਈਡੇ",
        "openInOverleaf": "Overleaf 'ਚ ਖੋਲ੍ਹੋ",
        "loadingPhrases": [],
        "initialMessage": "ਮੈਨੂੰ [\${widget.career}] ਕਿਉਂ ਸੁਝਾਇਆ ਗਿਆ?"
      };
    case "हरियाणवी":
      return {
        "chatTitle": "फ्राइडे सै बात करो",
        "shareChat": "चैट बांटौ",
        "shareChatContent": "तुम्हें अपनी बातचीत क्यूं बांटना से?",
        "shareViaWA": "व्हाट्सएप सै बांटौ",
        "enterWANumber": "अपना WA नंबर लिखो",
        "shareViaEmail": "ईमेल सै बांटौ",
        "enterEmail": "अपना ईमेल पता लिखो",
        "cancel": "रद्द करो",
        "couldNotLaunchOverleaf": "ओवरलीफ URL खोलण में दिक्कत",
        "messageHint": "तुम्हें के जाणना से...",
        "you": "तू",
        "friday": "फ्राइडे",
        "openInOverleaf": "ओवरलीफ में खोलो",
        "loadingPhrases": [],
        "initialMessage": "म्हने [\${widget.career}] क्यूं सुझाया गया?"
      };
    case "हिन्दी":
      return {
        "chatTitle": "फ्राइडे से बात करें",
        "shareChat": "चैट शेयर करें",
        "shareChatContent": "आप अपनी बातचीत किस तरह शेयर करना चाहेंगे?",
        "shareViaWA": "व्हाट्सएप के जरिए शेयर करें",
        "enterWANumber": "अपना WA नंबर दर्ज करें",
        "shareViaEmail": "ईमेल के जरिए शेयर करें",
        "enterEmail": "अपना ईमेल पता दर्ज करें",
        "cancel": "रद्द करें",
        "couldNotLaunchOverleaf": "ओवरलीफ URL लॉन्च नहीं हो सका",
        "messageHint": "आप क्या जानना चाहेंगे...",
        "you": "आप",
        "friday": "फ्राइडे",
        "openInOverleaf": "ओवरलीफ में खोलें",
        "loadingPhrases": [],
        "initialMessage": "मुझे [\${widget.career}] की सिफारिश क्यों की गई?"
      };
    case "राजस्थानी":
      return {
        "chatTitle": "फ्राइडे री बात करो",
        "shareChat": "चैट शेयर करो",
        "shareChatContent": "थाने अपनी बातचीत किण री शेयर करणी है?",
        "shareViaWA": "व्हाट्सऐप थां share करो",
        "enterWANumber": "अपनो WA नंबर लिखो",
        "shareViaEmail": "ईमेल थां share करो",
        "enterEmail": "अपनो ईमेल पता लिखो",
        "cancel": "रद्द करो",
        "couldNotLaunchOverleaf": "ओवरलीफ URL खोलण में दिक्कत",
        "messageHint": "थाने काई जाणनो है...",
        "you": "थां",
        "friday": "फ्राइडे",
        "openInOverleaf": "ओवरलीफ में खोलो",
        "loadingPhrases": [],
        "initialMessage": "मने [\${widget.career}] री सिफारिश क्यूं करी?"
      };
    case "भोजपुरी":
      return {
        "chatTitle": "फ्राइडे से बतियाईं",
        "shareChat": "चैट शेयर करीं",
        "shareChatContent": "रउआ अपना बातचीत के कइसे शेयर करीं?",
        "shareViaWA": "व्हाट्सऐप से शेयर करीं",
        "enterWANumber": "अपना WA नंबर डालल जाव",
        "shareViaEmail": "ईमेल से शेयर करीं",
        "enterEmail": "अपना ईमेल पता डालल जाव",
        "cancel": "रद्द करीं",
        "couldNotLaunchOverleaf": "ओवरलीफ URL खोलल ना जा सकल",
        "messageHint": "रउआ का जानल चाहत बानी...",
        "you": "रउआ",
        "friday": "फ्राइडे",
        "openInOverleaf": "ओवरलीफ में खोलल जाव",
        "loadingPhrases": [],
        "initialMessage": "हमके [\${widget.career}] काहें सुझावल गइल?"
      };
    case "বাংলা":
      return {
        "chatTitle": "ফ্রাইডের সাথে কথা বলুন",
        "shareChat": "চ্যাট শেয়ার করুন",
        "shareChatContent": "আপনি কিভাবে আপনার কথোপকথন শেয়ার করতে চান?",
        "shareViaWA": "হোয়াটসঅ্যাপের মাধ্যমে শেয়ার করুন",
        "enterWANumber": "আপনার WA নম্বর প্রবেশ করুন",
        "shareViaEmail": "ইমেইলের মাধ্যমে শেয়ার করুন",
        "enterEmail": "আপনার ইমেইল ঠিকানা প্রবেশ করুন",
        "cancel": "বাতিল করুন",
        "couldNotLaunchOverleaf": "Overleaf URL লঞ্চ করা যায়নি",
        "messageHint": "আপনি কি জানতে চান...",
        "you": "আপনি",
        "friday": "ফ্রাইডে",
        "openInOverleaf": "Overleaf-এ খুলুন",
        "loadingPhrases": [],
        "initialMessage": "আমাকে [\${widget.career}] কেন সুপারিশ করা হলো?"
      };
    case "ગુજરાતી":
      return {
        "chatTitle": "ફ્રાઇડે સાથે વાત કરો",
        "shareChat": "ચેટ શેર કરો",
        "shareChatContent": "તમે તમારી વાતચીત કેવી રીતે શેર કરશો?",
        "shareViaWA": "વોટ્સએપ મારફતે શેર કરો",
        "enterWANumber": "તમારો WA નંબર દાખલ કરો",
        "shareViaEmail": "ઇમેઇલ મારફતે શેર કરો",
        "enterEmail": "તમારો ઇમેઇલ સરનામું દાખલ કરો",
        "cancel": "રદ કરો",
        "couldNotLaunchOverleaf": "Overleaf URL લોંચ કરી શક્યા નથી",
        "messageHint": "તમે શું જાણવું છે...",
        "you": "તમે",
        "friday": "ફ્રાઇડે",
        "openInOverleaf": "Overleaf માં ખોલો",
        "loadingPhrases": [],
        "initialMessage": "મને [\${widget.career}]ની ભલામણ કેમ કરી?"
      };
    case "অসমীয়া":
      return {
        "chatTitle": "ফ্ৰাইডে সৈতে কথা",
        "shareChat": "চেট শ্বেয়াৰ কৰক",
        "shareChatContent": "আপুনি কেনেকৈ আপোনাৰ কথা-বতৰা শ্বেয়াৰ কৰিব?",
        "shareViaWA": "ৱাটচএপৰ জৰিয়তে শ্বেয়াৰ কৰক",
        "enterWANumber": "আপোনাৰ WA নম্বৰ লিখক",
        "shareViaEmail": "ইমেইলৰ জৰিয়তে শ্বেয়াৰ কৰক",
        "enterEmail": "আপোনাৰ ইমেইল ঠিকনা লিখক",
        "cancel": "বাতিল কৰক",
        "couldNotLaunchOverleaf": "Overleaf URL খোলাত অসুবিধা হৈছে",
        "messageHint": "আপুনি কি জানিব বিচাৰে...",
        "you": "আপুনি",
        "friday": "ফ্ৰাইডে",
        "openInOverleaf": "Overleaf-ত খোলক",
        "loadingPhrases": [],
        "initialMessage": "মোক [\${widget.career}] কিয় পৰামৰ্শ দিয়া হৈছে?"
      };
    case "ଓଡ଼ିଆ":
      return {
        "chatTitle": "ଫ୍ରାଇଡେ ସହିତ କଥାବାର୍ତ୍ତା କରନ୍ତୁ",
        "shareChat": "ଚାଟ୍ ଶେୟର୍ କରନ୍ତୁ",
        "shareChatContent":
        "ଆପଣ ଆପଣଙ୍କର କଥାବାର୍ତ୍ତା କେମିତି ଶେୟର୍ କରିବାକୁ ଚାହାଁତି?",
        "shareViaWA": "ୱାଟସ୍ଆପ୍ ଦ୍ୱାରା ଶେୟର୍ କରନ୍ତୁ",
        "enterWANumber": "ଆପଣଙ୍କର WA ନମ୍ବର ଦିଅନ୍ତୁ",
        "shareViaEmail": "ଇମେଲ୍ ଦ୍ୱାରା ଶେୟର୍ କରନ୍ତୁ",
        "enterEmail": "ଆପଣଙ୍କର ଇମେଲ୍ ଠିକଣା ଦିଅନ୍ତୁ",
        "cancel": "ରଦ୍ଦ କରନ୍ତୁ",
        "couldNotLaunchOverleaf": "Overleaf URL ଖୋଲିପାରିଲା ନାହିଁ",
        "messageHint": "ଆପଣ କଣ ଜାଣିବାକୁ ଚାହାଁତି...",
        "you": "ଆପଣ",
        "friday": "ଫ୍ରାଇଡେ",
        "openInOverleaf": "Overleafରେ ଖୋଲନ୍ତୁ",
        "loadingPhrases": [],
        "initialMessage": "ମୋତେ [\${widget.career}] କାହିଁକି ସୁପାରିଶ କରାଯାଇଛି?"
      };
    case "मराठी":
      return {
        "chatTitle": "फ्राइडे सोबत बोला",
        "shareChat": "चॅट शेअर करा",
        "shareChatContent": "तुम्ही तुमची संभाषणे कशी शेअर कराल?",
        "shareViaWA": "व्हॉट्सअॅपद्वारे शेअर करा",
        "enterWANumber": "तुमचा WA नंबर प्रविष्ट करा",
        "shareViaEmail": "ईमेलद्वारे शेअर करा",
        "enterEmail": "तुमचा ईमेल पत्ता प्रविष्ट करा",
        "cancel": "रद्द करा",
        "couldNotLaunchOverleaf": "Overleaf URL लॉन्च होऊ शकला नाही",
        "messageHint": "तुम्हाला काय जाणून घ्यायचे आहे...",
        "you": "तुम्ही",
        "friday": "फ्राइडे",
        "openInOverleaf": "Overleaf मध्ये उघडा",
        "loadingPhrases": [],
        "initialMessage": "मला [\${widget.career}] ची शिफारस का केली?"
      };
    case "தமிழ்":
      return {
        "chatTitle": "பிரைடே உடன் பேசுங்கள்",
        "shareChat": "சாட் பகிரவும்",
        "shareChatContent": "உங்கள் உரையாடலை எப்படி பகிர விரும்புகிறீர்கள்?",
        "shareViaWA": "வாட்ஸ்அப்பின் மூலம் பகிரவும்",
        "enterWANumber": "உங்கள் WA எண்ணை உள்ளிடவும்",
        "shareViaEmail": "இமெயிலின் மூலம் பகிரவும்",
        "enterEmail": "உங்கள் இமெயில் முகவரியை உள்ளிடவும்",
        "cancel": "ரத்துசெய்",
        "couldNotLaunchOverleaf": "Overleaf URL திறக்க முடியவில்லை",
        "messageHint": "நீங்கள் என்ன தெரிந்து கொள்ள விரும்புகிறீர்கள்...",
        "you": "நீங்கள்",
        "friday": "பிரைடே",
        "openInOverleaf": "Overleaf இல் திறக்கவும்",
        "loadingPhrases": [],
        "initialMessage": "என்னை [\${widget.career}] பரிந்துரைக்கப்பட்டது ஏன்?"
      };
    case "తెలుగు":
      return {
        "chatTitle": "ఫ్రైడేతో మాట్లాడండి",
        "shareChat": "చాట్ షేర్ చేయండి",
        "shareChatContent": "మీ సంభాషణను మీరు ఎలా షేర్ చేయాలనుకుంటున్నారు?",
        "shareViaWA": "వాట్సాప్ ద్వారా షేర్ చేయండి",
        "enterWANumber": "మీ WA నంబర్ నమోదు చేయండి",
        "shareViaEmail": "ఇమెయిల్ ద్వారా షేర్ చేయండి",
        "enterEmail": "మీ ఇమెయిల్ చిరునామాను నమోదు చేయండి",
        "cancel": "రద్దు చేయండి",
        "couldNotLaunchOverleaf": "Overleaf URL ప్రారంభించలేకపోయింది",
        "messageHint": "మీరు ఏమి తెలుసుకోవాలనుకుంటున్నారు...",
        "you": "మీరు",
        "friday": "ఫ్రైడే",
        "openInOverleaf": "Overleafలో తెరవండి",
        "loadingPhrases": [],
        "initialMessage": "నాకు [\${widget.career}] ను ఎందుకు సిఫార్సు చేశారు?"
      };
    case "ಕನ್ನಡ":
      return {
        "chatTitle": "ಫ್ರೈಡೆಯೊಂದಿಗೆ ಮಾತಾಡಿ",
        "shareChat": "ಚಾಟ್ ಹಂಚಿಕೊಳ್ಳಿ",
        "shareChatContent": "ನಿಮ್ಮ ಸಂಭಾಷಣೆಯನ್ನು ನೀವು ಹೇಗೆ ಹಂಚಿಕೊಳ್ಳಬಯಸುತ್ತೀರಿ?",
        "shareViaWA": "ವಾಟ್ಸಾಪ್ ಮೂಲಕ ಹಂಚಿಕೊಳ್ಳಿ",
        "enterWANumber": "ನಿಮ್ಮ WA ನಂಬರ್ ನಮೂದಿಸಿ",
        "shareViaEmail": "ಇಮೇಲ್ ಮೂಲಕ ಹಂಚಿಕೊಳ್ಳಿ",
        "enterEmail": "ನಿಮ್ಮ ಇಮೇಲ್ ವಿಳಾಸ ನಮೂದಿಸಿ",
        "cancel": "ರದ್ದು ಮಾಡಿ",
        "couldNotLaunchOverleaf": "Overleaf URL ಅನ್ನು ಲಾಂಚ್ ಮಾಡಲಾಗಲಿಲ್ಲ",
        "messageHint": "ನೀವು ಏನು ತಿಳಿಯಲು ಬಯಸುತ್ತೀರಿ...",
        "you": "ನೀವು",
        "friday": "ಫ್ರೈಡೆ",
        "openInOverleaf": "Overleaf ನಲ್ಲಿ ತೆರೆಯಿರಿ",
        "loadingPhrases": [],
        "initialMessage": "ನನಗೆ [\${widget.career}] ಶಿಫಾರಸು ಮಾಡಲಾದುದು ಯಾಕೆ?"
      };
    case "മലയാളം":
      return {
        "chatTitle": "ഫ്രൈഡുമായി സംസാരിക്കുക",
        "shareChat": "ചാറ്റ് പങ്കിടുക",
        "shareChatContent":
        "നിങ്ങളുടെ സംവാദം എങ്ങനെ പങ്കിടണമെന്ന് നിങ്ങൾ ആഗ്രഹിക്കുന്നു?",
        "shareViaWA": "വാട്ട്‌സ്ആപ്പിലൂടെ പങ്കിടുക",
        "enterWANumber": "നിങ്ങളുടെ WA നമ്പർ നൽകുക",
        "shareViaEmail": "ഇമെയിലിലൂടെ പങ്കിടുക",
        "enterEmail": "നിങ്ങളുടെ ഇമെയിൽ വിലാസം നൽകുക",
        "cancel": "റദ്ദാക്കുക",
        "couldNotLaunchOverleaf": "Overleaf URL ആരംഭിക്കാൻ കഴിയില്ല",
        "messageHint": "നിങ്ങൾ എന്ത് അറിയാൻ ആഗ്രഹിക്കുന്നു...",
        "you": "നിങ്ങൾ",
        "friday": "ഫ്രൈഡി",
        "openInOverleaf": "Overleaf-ൽ തുറക്കുക",
        "loadingPhrases": [],
        "initialMessage":
        "എനിക്ക് [\${widget.career}] എന്ന കരിയർ എന്തുകൊണ്ടാണ് ശുപാർശ ചെയ്തത്?"
      };
    case "English":
      return {
        "chatTitle": "Talk to Friday",
        "shareChat": "Share Chat",
        "shareChatContent": "How would you like to share your conversation?",
        "shareViaWA": "Share Via WhatsApp",
        "enterWANumber": "Enter your WA Number",
        "shareViaEmail": "Share Via Email",
        "enterEmail": "Enter your Email Address",
        "cancel": "Cancel",
        "couldNotLaunchOverleaf": "Could not launch Overleaf URL.",
        "messageHint": "What would you like to know...",
        "you": "You",
        "friday": "Friday",
        "openInOverleaf": "Open in Overleaf",
        "loadingPhrases": [],
        "initialMessage":
        "Why was I recommended the career [\${widget.career}]?"
      };
    default:
      return {
        "chatTitle": "Talk to Friday",
        "shareChat": "Share Chat",
        "shareChatContent": "How would you like to share your conversation?",
        "shareViaWA": "Share Via WhatsApp",
        "enterWANumber": "Enter your WA Number",
        "shareViaEmail": "Share Via Email",
        "enterEmail": "Enter your Email Address",
        "cancel": "Cancel",
        "couldNotLaunchOverleaf": "Could not launch Overleaf URL.",
        "messageHint": "What would you like to know...",
        "you": "You",
        "friday": "Friday",
        "openInOverleaf": "Open in Overleaf",
        "loadingPhrases": [],
        "initialMessage":
        "Why was I recommended the career [\${widget.career}]?"
      };
  }
}

class ChatScreen extends StatefulWidget {
  final String career;
  final QuestionData ans;

  const ChatScreen({super.key, required this.career, required this.ans});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _exportWAController = TextEditingController();
  final _exportEmailController = TextEditingController();
  var _awaitingResponse = false;
  String? _overleafUrl;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  late final FocusNode _keyboardFocusNode;
  late Stream<String> _loadingPhraseStream;
  final List<MessageBubble> _chatHistory = [];
  late Map<String, dynamic> localized;

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = FocusNode();
    // Load language preference asynchronously.
    _loadLanguagePreference();
    initMessage();
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Future<void> initMessage() async {
    if (_awaitingResponse) return;
    setState(() => _awaitingResponse = true);
    String prompt = localized["initialMessage"] ??
        "Why was I recommended the career [${widget.career}]";
    try {
      String response = await fetchResultFromGemini(prompt);
      setState(() {
        _addMessage(response, false);
        _awaitingResponse = false;
      });
    } catch (e) {
      debugPrint('Error in initMessage: $e');
      setState(() {
        _addMessage("Error: $e", false);
        _awaitingResponse = false;
      });
    }
  }
  String getChatContent() {
    final StringBuffer buffer = StringBuffer();
    for (var message in _chatHistory) {
      final sender = message.isUserMessage ? (localized["you"] ?? "You") : (localized["friday"] ?? "Friday");
      buffer.writeln("$sender: ${message.content}");
    }
    return buffer.toString();
  }


  Future<void> _onSubmitted(String message) async {
    if (_awaitingResponse)
      return; // block new submissions if already processing
    _messageController.clear();
    setState(() {
      _addMessage(message, true);
      _awaitingResponse = true;
      _overleafUrl = null; // Reset any previous URL.
    });
    try {
      final result = await fetchResultFromGemini(message);
      setState(() {
        _addMessage(result, false);
        _awaitingResponse = false;
      });
      // Check for LaTeX and set overleaf URL.
      if (_isLatex(result)) {
        final base64Latex = base64Encode(utf8.encode(result));
        final overleafUrl =
            'https://www.overleaf.com/docs?snip_uri=data:application/x-tex;base64,$base64Latex';
        setState(() {
          _overleafUrl = overleafUrl;
        });
      }
    } catch (e) {
      debugPrint('Error in _onSubmitted: $e');
      setState(() {
        _addMessage("Error: $e", false);
        _awaitingResponse = false;
      });
    }
  }

  Future<void> _loadLanguagePreference() async {
    String lang = "English";
    try {
      final jsonString = widget.ans.toJson();
      debugPrint("QuestionData JSON: $jsonString");
      final data = jsonDecode(jsonString);
      if (data.containsKey("Language Preference")) {
        var langValue = data["Language Preference"];
        lang = (langValue is List && langValue.isNotEmpty)
            ? langValue.first.toString()
            : langValue.toString();
      } else if (data.containsKey("language")) {
        var langValue = data["language"];
        lang = (langValue is List && langValue.isNotEmpty)
            ? langValue.first.toString()
            : langValue.toString();
      }
    } catch (e) {
      debugPrint("Error extracting language: $e");
      lang = "English";
    }
    localized = getLocalizedTexts(lang);

    setState(() {});
  }

  void _addMessage(String response, bool isUserMessage) {
    _chatHistory.add(MessageBubble(
      content: response,
      isUserMessage: isUserMessage,
      userName: localized["you"] ?? "You",
      botName: localized["friday"] ?? "Friday",
    ));
    try {
      if (_listKey.currentState != null) {
        _listKey.currentState!.insertItem(_chatHistory.length - 1);
      }
    } catch (e) {
      debugPrint("AnimatedList insertion error: $e");
    }
    // Scroll to the bottom after the frame builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isLatex(String text) {
    return text.contains(r'\documentclass') ||
        text.contains(r'\begin{document}');
  }

  Future<String> extractTextFromBytes(
      Uint8List bytes, String? extension) async {
    if (extension == null) return "Unsupported file format.";

    if (extension.toLowerCase() == 'pdf') {
      try {
        PdfDocument document = PdfDocument(inputBytes: bytes);
        PdfTextExtractor extractor = PdfTextExtractor(document);
        String extractedText = extractor.extractText();
        document.dispose();
        return extractedText;
      } catch (e) {
        return "Error extracting PDF text: $e";
      }
    } else {
      return "Unsupported file format.";
    }
  }

  Future<String> fetchResultFromGPT(String career) async {
    OpenAI.apiKey = await rootBundle.loadString('assets/openai.key');
    OpenAI.showLogs = true;
    OpenAI.showResponsesLogs = true;

    final prompt =
        "Hello! I'm interested in learning more about $career. Can you tell me more about the career and provide some suggestions on what I should learn first?";

    final completion = await OpenAI.instance.chat.create(
      model: 'gpt-3.5-turbo',
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
          ],
        ),
      ],
      maxTokens: 150,
      temperature: 0.7,
    );

    if (completion.choices.isNotEmpty) {
      return completion.choices.first.message.content!.first.text.toString();
    } else {
      throw Exception('Failed to load result');
    }
  }

  Future<String> fetchResultFromGemini(String message) async {
    final apiKey = await rootBundle.loadString('assets/gemini.key');
    final endpoint =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?alt=sse&key=$apiKey";

    final chatHistory =
    _chatHistory.map((bubble) => {"content": bubble.content}).toList();
    if (chatHistory.isEmpty) chatHistory.add({"content": message});

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'system_instruction': {
          'parts': [
            {
              'text': '''
You are Friday, a very friendly, career recommendation bot who helps students pick the best career for them. You are trained to reject answering questions that are too off-topic and to reply in under 100-160 words unless more detail is required.

You are chatting with a person who is interested in the career ["${widget.career}"] and will speak only regarding it. Dont use any other language than LANGUAGE IN CONTENT in this. Base your responses on the survey JSON data provided below:
${widget.ans.toJson()}

Depending on the student's request:

• If the student asks for career suggestions or advice, provide clear and concise guidance in markdown with all publicly available resources links.

• If the student requests a tailored resume or modified resume or updated resume or changes in resume or anything related to resume, generate a Basic level latex code WITH ALL PROPER FORMATTING FONTS ALIGNMENT AND EXTREMELY PROFESSIONAL with divider line between these fields containing all the relevant resume details—including personal information, objective, education, work experience, skills, certifications, projects, achievements, and references—using the structure outlined below and tailor or modify, update or change that resume according to job domain and job links. Output LaTeX code ONLY NOT EVEN ANY SINGLE LINE OF TEXT OTHER THAN THAT.

• If student asks for ATS score or resume review, output that ATS score and give suggestions only to maximize it.
'''
            }
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': message}
            ],
          },
        ],
        'safetySettings': [
          {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
          {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_NONE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_NONE'
          },
        ],
        'generationConfig': {
          'candidateCount': 1,
          'temperature': 0.7,
          'topP': 0.8,
        },
      }),
    );

    debugPrint("Chat history: $chatHistory");
    if (response.statusCode == 200) {
      // Decode the response body using UTF-8
      final decodedBody = utf8.decode(response.bodyBytes);
      final lines = decodedBody.split('\n');
      final dataLines =
      lines.where((line) => line.startsWith("data:")).toList();
      final resultText =
      dataLines.map((line) => line.replaceFirst("data: ", "")).join('');
      debugPrint("Result text: $resultText");

      try {
        final jsonResponse = jsonDecode(resultText);
        debugPrint('Response JSON: $jsonResponse');
        final candidateText =
        jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        return candidateText;
      } catch (e) {
        debugPrint("Error decoding JSON: $e");
        return 'Error decoding response: ${decodedBody}';
      }
    } else {
      return 'Status [${response.statusCode}]\nFailed to load result: ${response.body}';
    }
  }

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          localized["chatTitle"] ?? "Chat",
          style: const TextStyle(
            fontSize: 20.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1F1F1F),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
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
                          localized["shareChatContent"] ??
                              "Share this chat with others",
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
                              child: Text(
                                localized["cancel"] ?? "Cancel",
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
                                    SnackBar(content: Text(localized["enterContact"] ?? "Please enter a Whatsapp no or an Email")),
                                  );
                                  return;
                                }
                                // Get the chat content that will be shared.
                                final String chatContent = getChatContent();
                                // Share via WhatsApp if a number is provided.
                                if (waNumber.isNotEmpty) {
                                  final String message = Uri.encodeComponent(
                                      "Hello, I wanted to share this chat with you.\n\n$chatContent");
                                  final String waUrl =
                                      "https://wa.me/$waNumber?text=$message";
                                  if (await canLaunch(waUrl)) {
                                    await launch(waUrl);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(localized["couldNotLaunchWA"] ?? "Could not launch WhatsApp")),
                                    );
                                  }
                                }
                                // Share via Email if an email address is provided.
                                if (email.isNotEmpty) {
                                  final String subject =
                                  Uri.encodeComponent(localized["chatShareSubject"] ?? "Chat Share");
                                  final String body = Uri.encodeComponent(
                                      "Hello, I wanted to share this chat with you.\n\n$chatContent");
                                  final String emailUrl =
                                      "mailto:$email?subject=$subject&body=$body";
                                  if (await canLaunch(emailUrl)) {
                                    await launch(emailUrl);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(localized["couldNotLaunchEmail"] ?? "Could not launch Email")),
                                    );
                                  }
                                }
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                localized["send"] ?? "Send",
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
            },
          ),
        ],
      ),
      body: _chatHistory.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: AnimatedList(
                  key: _listKey,
                  controller: _scrollController,
                  initialItemCount: _chatHistory.length,
                  itemBuilder: (context, index, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: _chatHistory[index],
                    );
                  },
                ),
              ),
              if (_overleafUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to in-app web view for the Overleaf link.
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => InAppWebViewScreen(
                          url: _overleafUrl!,
                          title: localized["openInOverleaf"] ?? "Open in Overleaf",
                        ),
                      ));
                    },
                    child: Text(
                      localized["openInOverleaf"] ?? "Open in Overleaf",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: const Color(0xFF424242), width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: !_awaitingResponse
                          ? TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _onSubmitted(value.trim());
                            _messageController.clear();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: localized["messageHint"] ?? "Type your message...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          prefixIcon: const Icon(
                            Icons.question_answer,
                            color: Color(0xFF5BC0EB),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.attach_file,
                              color: Color(0xFF5BC0EB),
                            ),
                            onPressed: () async {
                              FilePickerResult? result =
                              await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['pdf', 'doc', 'docx'],
                                withData: true,
                              );
                              if (result != null) {
                                final file = result.files.single;
                                if (file.bytes != null) {
                                  String extractedText = await extractTextFromBytes(
                                      file.bytes!, file.extension);
                                  _messageController.text =
                                  "${_messageController.text}\n$extractedText";
                                }
                              }
                            },
                          ),
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: SpinKitPouringHourGlassRefined(
                              color: const Color(0xFF5BC0EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: !_awaitingResponse
                          ? () {
                        final text = _messageController.text.trim();
                        if (text.isNotEmpty) {
                          _onSubmitted(text);
                          _messageController.clear();
                        }
                      }
                          : null,
                      icon: const Icon(Icons.send, color: Color(0xFF5BC0EB)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitPouringHourGlassRefined(
              color: const Color(0xFF5BC0EB), size: 120),
          const SizedBox(height: 10),
          StreamBuilder<String>(
            stream: Stream.periodic(
              const Duration(seconds: 3),
                  (i) => localized["loadingPhrases"]
              [Random().nextInt(localized["loadingPhrases"].length)],
            ),
            builder: (context, snapshot) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      axis: Axis.horizontal,
                      axisAlignment: -1,
                      child: child,
                    ),
                  );
                },
                child: Text(
                  snapshot.data ?? "",
                  key: ValueKey<String>(snapshot.data ?? ""),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              );
            },
          ),
        ],
      ),
    );
  }





}

class MessageBubble extends StatelessWidget {
  final String content;
  final bool isUserMessage;
  final String userName;
  final String botName;

  const MessageBubble({
    required this.content,
    required this.isUserMessage,
    required this.userName,
    required this.botName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF424242)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isUserMessage ? userName : botName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            MarkdownWidget(
              data: content,
              shrinkWrap: true,
              config: MarkdownConfig.darkConfig,
            ),
          ],
        ),
      ),
    );
  }
}
