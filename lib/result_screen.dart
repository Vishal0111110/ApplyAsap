// ignore_for_file: unnecessary_string_escapes, prefer_const_constructors

import 'dart:convert';
import 'home.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:dart_openai/dart_openai.dart';
import 'package:url_launcher/url_launcher.dart';
import 'question_data.dart';
import 'chat_screen.dart';
import 'start_screen.dart';
import 'user_controller.dart';
import 'community.dart';
import 'feed.dart';

class ResultScreen extends StatefulWidget {
  final QuestionData answers;

  const ResultScreen({super.key, required this.answers});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late Future<ResultData> futureResult;
  late String systemString, userString;
  int _languageIndex = 15;
  int _selectedIndex = 0;

  late NotchBottomBarController _notchBottomBarController;
  @override
  void initState() {
    super.initState();
    _notchBottomBarController = NotchBottomBarController();
    // Updated system prompt instructs Gemini to reply in JSON with a language key.
    systemString = """
You are a super thoughtful Job domains and job recommender and link provider for every type of audience.
You read data given to you in JSON format and ONLY reply in JSON format AND LANGUAGE OF YOUR REPONSE SHOULD BE STRICTLY IN LANGUAGE PREFERNCE CHOSEN EVEN RETURN LANGUAGE PREFERNCE CHOSEN ALSO EVEN GIVE SKILLLS REWUIRED STRICCTLY IN PREFFERD LANGUAGE ONLY .
You recommend 20 Job domains based on the input JSON and provide:
1. A very enthusiastic and short reasoning (20 words) for each Job domain.
2. A list of 3-5 skills (with short names) that should be polished for success in that field.
3. An EXACT JOB LINK from a reputable job board (e.g., https://jobs.lever.co/, Indeed, LinkedIn, company website etc) for job listings in that field.
4. An EXACT YouTube COURSES LINK offering free courses to improve skills in that domain.
The output should be in this exact format:
{"Language Prefernce":"language here","Job domain Name1": ["reasoning1", "Skills Required: skill1, skill2, skill3", "jobLink1", "coursesLink1"], "Job domain Name2": ["reasoning2", "Skills Required: skill1, skill2, skill3, skill4, skill5", "jobLink2"]}
""";

    userString = """
      HERE IS THE USER'S ANSWERS:
      ${widget.answers.toJson()}
    """;

    // Fetch from Gemini by default.
    futureResult = fetchResultFromGemini();
  }

  Future<ResultData> fetchResultFromGPT() async {
    OpenAI.apiKey = await rootBundle.loadString('assets/openai.key');
    OpenAI.showLogs = true;
    OpenAI.showResponsesLogs = true;

    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      role: OpenAIChatMessageRole.system,
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(systemString)
      ],
    );
    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      role: OpenAIChatMessageRole.user,
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(userString)
      ],
    );

    final completion = await OpenAI.instance.chat.create(
      model: 'gpt-3.5-turbo',
      messages: [systemMessage, userMessage],
      maxTokens: 500,
      temperature: 0.2,
    );

    if (completion.choices.isNotEmpty) {
      debugPrint(
          'Result: ${completion.choices.first.message.content!.first.text}');
      return ResultData.fromJson(
        completion.choices.first.message.content!.first.text.toString(),
      );
    } else {
      throw Exception('Failed to load result from GPT');
    }
  }

  Future<ResultData> fetchResultFromGemini() async {
    final apiKey = await rootBundle.loadString('assets/gemini.key');
    final endpoint =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?alt=json&key=$apiKey";

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': 'system: $systemString'}
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': userString}
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
          'temperature': 1.2,
          'topP': 0.8,
        },
      }),
    );

    if (response.statusCode == 200) {
      final jsonResp = jsonDecode(response.body);
      final text = jsonResp['candidates'][0]['content']['parts'][0]['text'];
      debugPrint('Gemini raw text: $text');
      return ResultData.fromJson(text);
    } else {
      throw Exception('Failed to load result: ${response.body}');
    }
  }

  // Returns UI texts based on the language received from Gemini.
  Map<String, dynamic> getLocalizedTexts(String lang) {
    switch (lang) {
      case "कश्मीरी":
        return {
          "dashboardTitle": "نوکری ڈیش بورڈ",
          "dashboardTitle1": "سمارٹ لرننگ",
          "dashboardTitle2": "بات چیت اور ترقی",
          "dashboardTitle3": "اپ ٹو ڈیٹ رہیں",
          "dashboardTitle4": "کمائیں اور سیکھیں",
          "applyNow": "فوراً درخواست دیں",
          "learnNow": "فوراً سیکھیں",
          "skillsRequired": "ضروری مہارتیں:",
          "loadingPhrases": [
            "ایک لمحہ انتظار کریں۔",
            "میں جلد ہی بتاتا ہوں۔",
            "برائے مہربانی تھوڑی دیر۔",
            "میں چیک کر رہا ہوں۔",
            "تقریباً مکمل ہو رہا ہے۔",
            "ذرا ٹھہریں۔",
            "ابھی آ رہا ہوں۔",
            "واہ، یہ دلچسپ ہے۔",
            "میں اس پر ہوں۔",
            "تھوڑی دیر۔",
            "بس ایک لمحہ۔"
          ]
        };
      case "ਪੰਜਾਬੀ":
        return {
          "dashboardTitle": "ਨੌਕਰੀ ਡੈਸ਼ਬੋਰਡ",
          "dashboardTitle1": "ਸਮਾਰਟ ਲਰਨਿੰਗ",
          "dashboardTitle2": "ਚਰਚਾ ਕਰੋ ਅਤੇ ਵਧੋ",
          "dashboardTitle3": "ਅਪਡੇਟ ਰਹੋ",
          "dashboardTitle4": "ਕਮਾਓ ਅਤੇ ਸਿੱਖੋ",
          "applyNow": "ਹੁਣ ਅਰਜ਼ੀ ਦਿਓ",
          "learnNow": "ਹੁਣ ਸਿੱਖੋ",
          "skillsRequired": "ਲੋੜੀਂਦੀਆਂ ਹੁਨਰ:",
          "loadingPhrases": [
            "ਕਿਰਪਾ ਕਰਕੇ ਇਕ ਪਲ ਰੁਕੋ।",
            "ਮੈਂ ਇਸ ਤੇ ਕੰਮ ਕਰ ਰਿਹਾ ਹਾਂ।",
            "ਕੁਝ ਸਕਿੰਟ ਦਿਓ।",
            "ਮੈਂ ਵੇਖ ਰਿਹਾ ਹਾਂ।",
            "ਲਗਭਗ ਤਿਆਰ।",
            "ਥੋੜਾ ਜਿਹਾ ਠਹਿਰੋ।",
            "ਤੁਰੰਤ ਆ ਰਿਹਾ ਹਾਂ।",
            "ਇਹ ਦਿਲਚਸਪ ਹੈ।",
            "ਮੈਂ ਇਸ ਤੇ ਹਾਂ।",
            "ਇੱਕ ਪਲ।",
            "ਕ੍ਰਿਪਾ ਕਰਕੇ ਰੁਕੋ।"
          ]
        };
      case "हरियाणवी":
        return {
          "dashboardTitle": "नौकरी डैशबोर्ड",
          "dashboardTitle1": "स्मार्ट लर्निंग",
          "dashboardTitle2": "बातचीत करो और बढ़ो",
          "dashboardTitle3": "ताजा रहो",
          "dashboardTitle4": "कमाओ और सीखो",
          "applyNow": "अभी आवेदन करो",
          "learnNow": "अभी सीखो",
          "skillsRequired": "ज़रूरी कौशल:",
          "loadingPhrases": [
            "एक मिनट, काम चल रया सै।",
            "मैं इस पे काम कर रया सूं।",
            "थोड़ा रुक जा।",
            "देख रया सूं मैं।",
            "लगभग हो रया सै।",
            "जरा ठहर।",
            "जल्दी आ रया सूं।",
            "अरे, इब्बे तो मजेदार सै।",
            "मैं इस पे सै।",
            "थोड़ा सा इंतजार कर।",
            "बस एक पल।"
          ]
        };
      case "हिन्दी":
        return {
          "dashboardTitle": "नौकरी डैशबोर्ड",
          "dashboardTitle1": "स्मार्ट लर्निंग",
          "dashboardTitle2": "चर्चा करें और बढ़ें",
          "dashboardTitle3": "अप-टू-डेट रहें",
          "dashboardTitle4": "कमाएं और सीखें",
          "applyNow": "अभी आवेदन करें",
          "learnNow": "अभी सीखें",
          "skillsRequired": "आवश्यक कौशल:",
          "loadingPhrases": [
            "एक मिनट, काम हो रहा है।",
            "मैं इस पर काम कर रहा हूँ।",
            "कृपया एक पल प्रतीक्षा करें।",
            "मैं यह देख रहा हूँ।",
            "मैं लगभग पूरा कर रहा हूँ।",
            "थोड़ा इंतजार करें।",
            "जल्दी आ रहा हूँ।",
            "वाह, यह तो दिलचस्प है।",
            "मैं इस पर हूँ।",
            "थोड़ा समय दीजिए।",
            "बस एक क्षण।"
          ]
        };
      case "राजस्थानी":
        return {
          "dashboardTitle": "नौकरी डैशबोर्ड",
          "dashboardTitle1": "स्मार्ट लर्निंग",
          "dashboardTitle2": "चर्चा करो और बढ़ो",
          "dashboardTitle3": "अप-टू-डेट रहो",
          "dashboardTitle4": "कमाओ और सीखो",
          "applyNow": "अब आवेदन करें",
          "learnNow": "अब सीखें",
          "skillsRequired": "जरूरी कौशल:",
          "loadingPhrases": [
            "थोड़ा सा रुकजो।",
            "मैं काम में लाग्यो हूँ।",
            "कृपया एक पल रुकजो।",
            "मैं देख रयो हूँ।",
            "लगभग पूरो हो रह्यो है।",
            "थोड़ा ठहरजो।",
            "जल्दी आ रह्यो हूँ।",
            "वाह, यो रोचक है।",
            "मैं इस पे हूँ।",
            "थोड़ी देर रुकजो।",
            "बस एक क्षण।"
          ]
        };
      case "भोजपुरी":
        return {
          "dashboardTitle": "नौकरी डैशबोर्ड",
          "dashboardTitle1": "स्मार्ट लर्निंग",
          "dashboardTitle2": "चर्चा करीं आ बढ़ीं",
          "dashboardTitle3": "अप-टू-डेट रहऽ",
          "dashboardTitle4": "कमाईं आ सीखीं",
          "applyNow": "अब आवेदन करीं",
          "learnNow": "अब सीखी",
          "skillsRequired": "जरूरी कौशल:",
          "loadingPhrases": [
            "एक मिनट, काम हो रहल बा।",
            "हम ए पर काम करत बानी।",
            "कृपया थोड़े देर रुकीं।",
            "हम देखत बानी।",
            "लगभग हो गइल बा।",
            "थोड़ा इंतजार करीं।",
            "जल्दी आवत बानी।",
            "वाह, ई रोचक बा।",
            "हम ए पर बानी।",
            "थोड़ा देर दीं।",
            "बस एक पल।"
          ]
        };
      case "বাংলা":
        return {
          "dashboardTitle": "চাকরি ড্যাশবোর্ড",
          "dashboardTitle1": "স্মার্ট লার্নিং",
          "dashboardTitle2": "আলোচনা করুন এবং বৃদ্ধি করুন",
          "dashboardTitle3": "আপডেট থাকুন",
          "dashboardTitle4": "উপার্জন করুন ও শিখুন",
          "applyNow": "এখন আবেদন করুন",
          "learnNow": "এখন শিখুন",
          "skillsRequired": "প্রয়োজনীয় দক্ষতা:",
          "loadingPhrases": [
            "এক মিনিট, কাজ চলছে।",
            "আমি কাজ করছি।",
            "কিছুক্ষণের জন্য অপেক্ষা করুন।",
            "আমি দেখছি।",
            "প্রায় শেষ।",
            "দয়া করে একটু অপেক্ষা করুন।",
            "শীঘ্রই আসছে।",
            "বাহ, এটি আকর্ষণীয়।",
            "আমি কাজ করছি।",
            "দয়া করে একটু সময় দিন।",
            "কেবল এক মুহূর্ত।"
          ]
        };
      case "ગુજરાતી":
        return {
          "dashboardTitle": "નોકરી ડેશબોર્ડ",
          "dashboardTitle1": "સ્માર્ટ લર્નિંગ",
          "dashboardTitle2": "ચર્ચા કરો અને વધો",
          "dashboardTitle3": "અપડેટ રહો",
          "dashboardTitle4": "કમાઓ અને શીખો",
          "applyNow": "હવે અરજી કરો",
          "learnNow": "હવે શીખો",
          "skillsRequired": "જરૂરી કુશળતા:",
          "loadingPhrases": [
            "એક મિનિટ, કામ ચાલી રહ્યું છે.",
            "હું આ પર કામ કરી રહ્યો છું.",
            "થોડી વાર રાહ જુઓ.",
            "હું જોઈ રહ્યો છું.",
            "લગભગ પૂરું.",
            "કૃપા કરી થોડી રાહ જુઓ.",
            "હમણાં આવી રહ્યો છું.",
            "અરે, આ રસપ્રદ છે.",
            "હું આ પર છું.",
            "થોડી વાર રાહ આપો.",
            "માત્ર એક ક્ષણ."
          ]
        };
      case "অসমীয়া":
        return {
          "dashboardTitle": "চাকৰি ডেশবোর্ড",
          "dashboardTitle1": "স্মাৰ্ট লাৰ্নিং",
          "dashboardTitle2": "আলোচনা কৰক আৰু বৃদ্ধি কৰক",
          "dashboardTitle3": "আপডেট থাকক",
          "dashboardTitle4": "উপার্জন কৰক আৰু শিকক",
          "applyNow": "এতিয়া আবেদন কৰক",
          "learnNow": "এতিয়া শিকক",
          "skillsRequired": "আৱশ্যক দক্ষতা:",
          "loadingPhrases": [
            "এখন মিনি, কাম চলি আছে।",
            "মই কাম কৰিছো।",
            "কিছু ক্ষণ অপেক্ষা কৰক।",
            "মই চাইছো।",
            "প্ৰায় শেষ।",
            "অনুগ্ৰহ কৰি অলপ ৰোৱা।",
            "সোনকালে আহি আছে।",
            "বাহ, ই আকৰ্ষণীয়।",
            "মই কামত আছো।",
            "অনুগ্ৰহ কৰি অলপ সময় দিয়ক।",
            "মাত্ৰ এক ক্ষণ।"
          ]
        };
      case "ଓଡ଼ିଆ":
        return {
          "dashboardTitle": "ଚାକିରି ଡ୍ୟାଶବୋର୍ଡ",
          "dashboardTitle1": "ସ୍ମାର୍ଟ ଶିକ୍ଷା",
          "dashboardTitle2": "ଆଲୋଚନା କରନ୍ତୁ ଏବଂ ବୃଦ୍ଧି ହୁଅନ୍ତୁ",
          "dashboardTitle3": "ଅପଡେଟ୍ ରୁହନ୍ତୁ",
          "dashboardTitle4": "ଆର୍ଜନ କରନ୍ତୁ ଏବଂ ଶିଖନ୍ତୁ",
          "applyNow": "ଏବେ ଆବେଦନ କରନ୍ତୁ",
          "learnNow": "ଏବେ ଶିଖନ୍ତୁ",
          "skillsRequired": "ଆବଶ୍ୟକ ଦକ୍ଷତା:",
          "loadingPhrases": [
            "ଏକ ମିନିଟ୍, କାମ ଚାଲିଛି।",
            "ମୁଁ କାମ କରୁଛି।",
            "କୃପୟା ଥୋଡ଼ା ସମୟ ଦିଅନ୍ତୁ।",
            "ମୁଁ ଦେଖୁଛି।",
            "ପ୍ରାୟ ସମାପ୍ତ।",
            "ଥୋଡ଼ା ବିଳମ୍ବ ହେଉ।",
            "ଖୁବ ଶୀଘ୍ର ଆସୁଛି।",
            "ହା, ଏହା ଆକର୍ଷଣୀୟ।",
            "ମୁଁ ଏହାରେ ଅଛି।",
            "ଦୟାକରି କିଛି ସମୟ ଦିଅନ୍ତୁ।",
            "ମାତ୍ର ଏକ ମୁହୂର୍ତ୍ତ।"
          ]
        };
      case "मराठी":
        return {
          "dashboardTitle": "नोकरी डॅशबोर्ड",
          "dashboardTitle1": "स्मार्ट लर्निंग",
          "dashboardTitle2": "चर्चा करा आणि वाढा",
          "dashboardTitle3": "अप-टू-डेट रहा",
          "dashboardTitle4": "कमवा आणि शिका",
          "applyNow": "आता अर्ज करा",
          "learnNow": "आता शिका",
          "skillsRequired": "आवश्यक कौशल्य:",
          "loadingPhrases": [
            "एक मिनिट, काम सुरू आहे.",
            "मी काम करत आहे.",
            "कृपया थोडा वेळ थांबा.",
            "मी पाहत आहे.",
            "सुमारे पूर्ण.",
            "थोडा वेळ थांबा.",
            "लवकर येत आहे.",
            "अरे, हे रुचकर आहे.",
            "मी कामात आहे.",
            "थोडा वेळ द्या.",
            "फक्त एक क्षण."
          ]
        };
      case "தமிழ்":
        return {
          "dashboardTitle": "வேலை டேஷ்போர்டு",
          "dashboardTitle1": "ஸ்மார்ட் லேர்னிங்",
          "dashboardTitle2": "உரையாடி வளருங்கள்",
          "dashboardTitle3": "புதுப்பிக்கப்பட்ட நிலையில் இருங்கள்",
          "dashboardTitle4": "சம்பாதியுங்கள் மற்றும் கற்றுக்கொள்ளுங்கள்",
          "applyNow": "இப்போதே விண்ணப்பிக்கவும்",
          "learnNow": "இப்போதே கற்றுக்கொள்ளவும்",
          "skillsRequired": "தேவையான திறன்கள்:",
          "loadingPhrases": [
            "ஒரு நிமிடம், வேலை நடக்குது.",
            "நான் இதைப் பற்றி வேலை செய்கிறேன்.",
            "தயவுசெய்து காத்திருங்கள்.",
            "நான் பார்க்கிறேன்.",
            "சுமார் முடிந்துவிட்டது.",
            "சற்று காத்திருங்கள்.",
            "விரைவில் வருகிறது.",
            "அருகில், இது சுவாரஸ்யம்.",
            "நான் இதில் இருக்கிறேன்.",
            "சற்று நேரம் கொடுக்கவும்.",
            "மாத்திரம் ஒரு நொடி."
          ]
        };
      case "తెలుగు":
        return {
          "dashboardTitle": "ఉద్యోగ డాష్‌బోర్డ్",
          "dashboardTitle1": "స్మార్ట్ లర్నింగ్",
          "dashboardTitle2": "చర్చించండి మరియు ఎదగండి",
          "dashboardTitle3": "అప్‌డేట్‌గా ఉండండి",
          "dashboardTitle4": "సంపాదించండి మరియు నేర్చుకోండి",
          "applyNow": "దరఖాస్తు",
          "learnNow": "నేర్చుకోండి",
          "skillsRequired": "అవసరమైన నైపుణ్యాలు:",
          "loadingPhrases": [
            "ఒక నిమిషం, పని జరుగుతోంది.",
            "నేను పని చేస్తున్నాను.",
            "దయచేసి కొంత సమయం వేచి ఉండండి.",
            "నేను చూస్తున్నాను.",
            "సుమారు పూర్తి.",
            "కొంతసేపు రండి.",
            "త్వరగా వస్తోంది.",
            "వావ్, ఇది ఆసక్తికరంగా ఉంది.",
            "నేను దీనిపై ఉన్నాను.",
            "కొద్దిగా సమయం ఇవ్వండి.",
            "కేవలం ఒక క్షణం."
          ]
        };
      case "ಕನ್ನಡ":
        return {
          "dashboardTitle": "ಉದ್ಯೋಗ ಡ್ಯಾಶ್ಬೋರ್ಡ್",
          "dashboardTitle1": "ಸ್ಮಾರ್ಟ್ ಲರ್ನಿಂಗ್",
          "dashboardTitle2": "ಚರ್ಚಿಸಿ ಮತ್ತು ಬೆಳೆಯಿರಿ",
          "dashboardTitle3": "ನವೀಕರಿತವಾಗಿರಿ",
          "dashboardTitle4": "ಆದಾಯ ಮಾಡಿ ಮತ್ತು ಕಲಿಯಿರಿ",
          "applyNow": "ಈಗ ಅರ್ಜಿ ಸಲ್ಲಿಸಿ",
          "learnNow": "ಈಗ ಕಲಿಯಿರಿ",
          "skillsRequired": "ಅಗತ್ಯ ಕೌಶಲ್ಯಗಳು:",
          "loadingPhrases": [
            "ಒಂದು ನಿಮಿಷ, ಕೆಲಸ ನಡೆಯುತ್ತಿದೆ.",
            "ನಾನು ಕೆಲಸಮಾಡುತ್ತಿದ್ದೇನೆ.",
            "ದಯವಿಟ್ಟು ಸ್ವಲ್ಪ ಕಾಯಿರಿ.",
            "ನಾನು ನೋಡುತ್ತಿದ್ದೇನೆ.",
            "ಸಂಪೂರ್ಣವಾಗಿ ಮುಗಿಯುತ್ತಿದೆ.",
            "ಸ್ವಲ್ಪ ವಿರಾಮ ಕೊಡಿ.",
            "ಶೀಘ್ರದಲ್ಲೇ ಬರುತ್ತಿದೆ.",
            "ಓ, ಇದು ಆಸಕ್ತಿದಾಯಕವಾಗಿದೆ.",
            "ನಾನು ಇದರಲ್ಲಿ ಇದ್ದೇನೆ.",
            "ಸ್ವಲ್ಪ ಸಮಯ ನೀಡಿ.",
            "ಮಾತ್ರ ಒಂದು ಕ್ಷಣ."
          ]
        };
      case "മലയാളം":
        return {
          "dashboardTitle": "ജോലി ഡാഷ്ബോർഡ്",
          "dashboardTitle1": "സ്മാർട്ട് ലേണിംഗ്",
          "dashboardTitle2": "സംവാദം നടത്തി വളരുക",
          "dashboardTitle3": "അപ്‌ഡേറ്റ് ആയിരിക്കുക",
          "dashboardTitle4": "സമ്പാദിക്കുകയും പഠിക്കുകയും ചെയ്യുക",
          "applyNow": "ഇപ്പോൾ അപേക്ഷിക്കുക",
          "learnNow": "ഇപ്പോൾ പഠിക്കുക",
          "skillsRequired": "ആവശ്യമായ നൈപുണ്യങ്ങൾ:",
          "loadingPhrases": [
            "ഒരു മിനിറ്റ്, ജോലി നടക്കുന്നുണ്ട്.",
            "ഞാൻ ജോലി ചെയ്യുന്നു.",
            "ദയവായി കുറച്ച് നിമിഷം കാത്തിരിക്കുക.",
            "ഞാൻ നോക്കുന്നു.",
            "സമീപത്തിൽ ആണ്.",
            "ദയവായി കാത്തിരിക്കുക.",
            "തുറന്നുകൊണ്ടിരിക്കുന്നു.",
            "വൗ, ഇത് രസകരമാണ്.",
            "ഞാൻ ഇതിൽ പ്രവർത്തിക്കുന്നു.",
            "ദയവായി കുറച്ച് സമയം കൊടുക്കുക.",
            "ഒരിക്കൽ മാത്രം."
          ]
        };
      case "English":
      default:
        return {
          "dashboardTitle": "Job Dashboard",
          "dashboardTitle1": "Smart Learning",
          "dashboardTitle2": "Discuss and grow",
          "dashboardTitle3": "Stay Updated",
          "dashboardTitle4": "Earn and Learn",
          "applyNow": "Apply Now",
          "learnNow": "Learn Now",
          "skillsRequired": "Skills Required:",
          "loadingPhrases": [
            "Working on it, one sec.",
            "I'll get back to you on that.",
            "Just a moment, please.",
            "Let me check on that.",
            "I'm almost there.",
            "Hang tight.",
            "Coming right up.",
            "Well.. well that's interesting.",
            "I'm on it.",
            "Be right back.",
            "Just a sec, I'm buffering."
          ]
        };
    }
  }

  int getLanguageIndex(String lang) {
    switch (lang) {
      case "कश्मीरी":
        return 0;
      case "ਪੰਜਾਬੀ":
        return 1;
      case "हरियाणवी":
        return 2;
      case "हिन्दी":
        return 3;
      case "राजस्थानी":
        return 4;
      case "भोजपुरी":
        return 5;
      case "বাংলা":
        return 6;
      case "ગુજરાતી":
        return 7;
      case "অসমীয়া":
        return 8;
      case "ଓଡ଼ିଆ":
        return 9;
      case "मराठी":
        return 10;
      case "தமிழ்":
        return 11;
      case "తెలుగు":
        return 12;
      case "ಕನ್ನಡ":
        return 13;
      case "മലയാളം":
        return 14;
      case "English":
      default:
        return 15;
    }
  }

  void dispose() {
    // Dispose the controller when the widget is removed
    _notchBottomBarController.dispose();
    super.dispose();
  }

  static final Color cardBorder = Colors.grey[800]!;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Dark background
      extendBody: true,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Dashboard Page with FutureBuilder and ListView.
          Center(
            child: FutureBuilder<ResultData>(
              future: futureResult,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SpinKitPouringHourGlassRefined(
                    color: const Color(0xFF5BC0EB), // Accent color for spinner
                    size: 120,
                  );
                } else if (snapshot.hasError) {
                  return Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  );
                } else if (snapshot.hasData) {
                  final lang = snapshot.data!.language ?? "English";
                  // Update language index if needed.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final newIndex = getLanguageIndex(lang);
                    if (_languageIndex != newIndex) {
                      setState(() {
                        _languageIndex = newIndex;
                      });
                    }
                  });
                  final localizedTexts = getLocalizedTexts(lang);
                  final data = snapshot.data!.result;
                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final entry = data.entries.elementAt(index);
                      return FutureBuilder(
                        future:
                            Future.delayed(Duration(milliseconds: 200 * index)),
                        builder: (context, delayedSnapshot) {
                          if (delayedSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container();
                          } else {
                            String skillsString = entry.value[1];
                            if (skillsString.contains("Skills Required:")) {
                              skillsString = skillsString
                                  .replaceFirst("Skills Required:", "")
                                  .trim();
                            }
                            final skills = skillsString.split(',');

                            // Create an AnimationController for the slide transition.
                            final slideController = AnimationController(
                              duration: const Duration(milliseconds: 300),
                              vsync: this,
                            )..forward();

                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: slideController,
                                  curve: Curves.easeInOutSine,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          career: entry.key,
                                          ans: widget.answers,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      side: BorderSide(
                                        color: cardBorder,
                                        width: 2,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1F1F1F),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 25, vertical: 12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Title text.
                                            Text(
                                              entry.key,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            // Space between title and description.
                                            const SizedBox(height: 5),
                                            // Description text.
                                            Text(
                                              entry.value[0],
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFFD1D1D1),
                                              ),
                                            ),
                                            // Space between description and divider.
                                            const SizedBox(height: 7),
                                            const Divider(
                                              thickness: 4.5,
                                              color: Color(0xFF2A2A2A),
                                            ),
                                            // Space between divider and "Skills Required" text.
                                            const SizedBox(height: 7),
                                            Text(
                                              localizedTexts["skillsRequired"],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFB0B0B0),
                                              ),
                                            ),
                                            const SizedBox(height: 6.5),
                                            Wrap(
                                              spacing: 4,
                                              runSpacing: 2,
                                              children: [
                                                for (var skill in skills)
                                                  Chip(
                                                    backgroundColor:
                                                        const Color(0xFF323232),
                                                    label: Text(
                                                      skill.trim(),
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      side: const BorderSide(
                                                        color:
                                                            Color(0xFF5BC0EB),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            // Buttons row.
                                            if (entry.value.length > 2 ||
                                                entry.value.length > 3)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 15),
                                                child: Row(
                                                  children: [
                                                    if (entry.value.length > 2)
                                                      Expanded(
                                                        child: ElevatedButton(
                                                          onPressed: () async {
                                                            final url =
                                                                entry.value[2];
                                                            if (await canLaunch(
                                                                url)) {
                                                              await launch(url);
                                                            } else {
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    localizedTexts[
                                                                            "applyNow"] +
                                                                        " - Could not launch job link",
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                const Color(
                                                                    0xFF5BC0EB),
                                                            foregroundColor:
                                                                Colors.white,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10.0),
                                                            ),
                                                          ),
                                                          child: Text(
                                                              localizedTexts[
                                                                  "applyNow"]),
                                                        ),
                                                      ),
                                                    if (entry.value.length >
                                                            2 &&
                                                        entry.value.length > 3)
                                                      const SizedBox(width: 2),
                                                    if (entry.value.length > 3)
                                                      Expanded(
                                                        child: ElevatedButton(
                                                          onPressed: () async {
                                                            final coursesUrl =
                                                                entry.value[3];
                                                            if (await canLaunch(
                                                                coursesUrl)) {
                                                              await launch(
                                                                  coursesUrl);
                                                            } else {
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    localizedTexts[
                                                                            "learnNow"] +
                                                                        " - Could not launch courses link",
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                const Color(
                                                                    0xFF5BC0EB),
                                                            foregroundColor:
                                                                Colors.white,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10.0),
                                                            ),
                                                          ),
                                                          child: Text(
                                                              localizedTexts[
                                                                  "learnNow"]),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                } else {
                  return const Text(
                    'No data found.',
                    style: TextStyle(color: Colors.white),
                  );
                }
              },
            ),
          ),
          // Home Page (or any other page) with language index passed.
          HomePage(langIndex: _languageIndex),
          CommunityPage(languageIndex: _languageIndex),
          FeedPage(languageIndex: _languageIndex),
          // Add additional pages if required.
        ],
      ),
      bottomNavigationBar: AnimatedNotchBottomBar(
        notchBottomBarController: _notchBottomBarController,
        bottomBarItems: [
          BottomBarItem(
            inActiveItem: Icon(Icons.home, color: const Color(0xFFB0B0B0)),
            activeItem: Icon(Icons.home, color: const Color(0xFF5BC0EB)),
            itemLabel: '',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.book, color: const Color(0xFFB0B0B0)),
            activeItem: Icon(Icons.book, color: const Color(0xFF5BC0EB)),
            itemLabel: '',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.people, color: const Color(0xFFB0B0B0)),
            activeItem: Icon(Icons.people, color: const Color(0xFF5BC0EB)),
            itemLabel: '',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.rss_feed, color: const Color(0xFFB0B0B0)),
            activeItem: Icon(Icons.rss_feed, color: const Color(0xFF5BC0EB)),
            itemLabel: '',
          ),
        ],
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        removeMargins: true,
        bottomBarHeight: 20.0,
        durationInMilliSeconds: 300,
        notchColor: const Color(0xFF121212), // Nav Bar background
        kIconSize: 25.0,
        kBottomRadius: 2.0,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    switch (_selectedIndex) {
      case 0:
        return AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: FutureBuilder<ResultData>(
            future: futureResult,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final lang = snapshot.data!.language ?? "English";
                return Text(
                  getLocalizedTexts(lang)["dashboardTitle"],
                  style: const TextStyle(
                    fontSize: 20.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              } else {
                return Container();
              }
            },
          ),
          actions: [
            FutureBuilder<ResultData>(
              future: futureResult,
              builder: (context, snapshot) {
                // You might conditionally show the image based on snapshot data if needed.
                // For now, if snapshot has data we display the image, else we show nothing.
                if (snapshot.hasData) {
                  return GestureDetector(
                    onTap: () async {
                      await UserController.signOut();
                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const StartScreen(),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        foregroundImage: NetworkImage(
                          UserController.user?.photoURL ?? '',
                        ),
                      ),
                    ),
                  );
                } else {
                  return Container();
                }
              },
            ),
          ],
        );

      case 1:
        return AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: FutureBuilder<ResultData>(
            future: futureResult,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final lang = snapshot.data!.language ?? "English";
                return Text(
                  getLocalizedTexts(lang)["dashboardTitle1"],
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              } else {
                return Container();
              }
            },
          ),
        );
      case 2:
        return AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: FutureBuilder<ResultData>(
            future: futureResult,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final lang = snapshot.data!.language ?? "English";
                return Text(
                  getLocalizedTexts(lang)["dashboardTitle2"],
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              } else {
                return Container();
              }
            },
          ),
        );
      default:
        return AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: FutureBuilder<ResultData>(
            future: futureResult,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final lang = snapshot.data!.language ?? "English";
                return Text(
                  getLocalizedTexts(lang)["dashboardTitle3"],
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              } else {
                return Container();
              }
            },
          ),
        );
    }
  }
}

// Updated ResultData class that extracts the language directly from the Gemini JSON.
// The language is stored separately and then removed from the job domains.
class ResultData {
  final Map<String, List<String>> result;
  final String? language;

  ResultData({required this.result, this.language});

  factory ResultData.fromJson(String jsonString) {
    jsonString = jsonString.trim();

    // Remove markdown code fences if present.
    if (jsonString.startsWith("```")) {
      final startIndex = jsonString.indexOf('{');
      final endIndex = jsonString.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        jsonString = jsonString.substring(startIndex, endIndex + 1);
      }
    }

    final Map<String, dynamic> rawMap = jsonDecode(jsonString);
    String? lang;
    if (rawMap.containsKey("Language Prefernce")) {
      lang = rawMap["Language Prefernce"].toString();
      rawMap.remove("Language Prefernce");
    }
    final resultMap = <String, List<String>>{};

    rawMap.forEach((key, value) {
      if (value is List) {
        final items = value.map((item) => item.toString()).toList();
        resultMap[key] = items;
      }
    });

    return ResultData(result: resultMap, language: lang);
  }
}
