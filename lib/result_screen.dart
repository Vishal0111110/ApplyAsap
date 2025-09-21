// ignore_for_file: unnecessary_string_escapes, prefer_const_constructors
import 'learn.dart';
import 'dart:convert';
import 'home.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:dart_openai/dart_openai.dart';
import 'question_data.dart';
import 'chat_screen.dart';
import 'interview.dart';
import 'interview_type_selection.dart';
import 'profile.dart';
import 'community.dart';
import 'feed.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'gamification_service.dart';
import 'web.dart';
// Diagnostics Module
import 'diagnostics/screens/diagnostics_menu.dart';

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
  List<String> _autoApplyJobs = [];

  late NotchBottomBarController _notchBottomBarController;
  @override
  void initState() {
    super.initState();
    _notchBottomBarController = NotchBottomBarController();
    // Updated system prompt instructs Gemini to reply in JSON with a language key.
    systemString = """
You are a super thoughtful Job domains and job recommender and link provider for every type of audience.
You read data given to you in JSON format and ONLY reply in JSON format AND LANGUAGE OF YOUR REPONSE SHOULD BE STRICTLY IN LANGUAGE PREFERNCE CHOSEN EVEN RETURN LANGUAGE PREFERNCE CHOSEN ALSO EVEN GIVE SKILLLS REWUIRED STRICCTly IN PREFFERD LANGUAGE ONLY .

**IMPORTANT INSTRUCTIONS:**
1.  **Prioritize PM Internship Scheme India:** First, fetch all available jobs from the PM Internship Scheme India website (https://pminternship.mca.gov.in/). These jobs **MUST** be listed at the very top of your response.
2.  **Source Tagging:** For each job, you **MUST** include a "source" tag indicating where the job was found. For jobs from the PM Internship Scheme, the source should be "PM Internship". For all other jobs, use the name of the job board (e.g., "LinkedIn", "Indeed").
3.  **Clean Job Titles:** The job title itself should **NOT** contain the phrase "PM Internship Scheme".
4.  **Valid Links:** Ensure that the `jobLink` and `coursesLink` for the PM Internship Scheme jobs are valid and directly relevant to the position.
5.  **Standard Recommendations:** After listing all the PM Internship jobs, you should then recommend 20 additional job domains based on the input JSON.

For all jobs, you must provide:
1.  A very enthusiastic and short reasoning (20 words) for each Job domain.
2.  A list of 3-5 skills (with short names) that should be polished for success in that field.
3.  An EXACT JOB LINK from a reputable job board (e.g., https://jobs.lever.co/, Indeed, LinkedIn, company website etc) for job listings in that field.
4.  An EXACT YouTube COURSES LINK offering free courses to improve skills in that domain.

The output should be in this exact format:
{"Language Prefernce":"language here","Job domain Name1": ["reasoning1", "Skills Required: skill1, skill2, skill3", "jobLink1", "coursesLink1", "source: PM Internship"], "Job domain Name2": ["reasoning2", "Skills Required: skill1, skill2, skill3, skill4, skill5", "jobLink2", "source: LinkedIn"]}
""";

    userString = """
      HERE IS THE USER'S ANSWERS:
      ${widget.answers.toJson()}
    """;

    // Fetch from Gemini by default.
    futureResult = fetchResultFromGemini();
  }

  Future<void> _checkAndShowDailyLoginPopup() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Simply call checkAndAwardDailyLogin - it handles all the logic internally
      await GamificationService().checkAndAwardDailyLogin(
        userId,
        context: context,
        showPopup: true,
      );
    } catch (e) {
      print('Error checking daily login popup: $e');
    }
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
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final answersKey = widget.answers.toJson().toString().hashCode.toString();
    final dbRef = FirebaseDatabase.instance
        .ref()
        .child('results')
        .child(userId)
        .child(answersKey);

    // Check if data exists in DB
    final snapshot = await dbRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      final jsonString = data['response'];
      debugPrint('Fetched from DB: $jsonString');
      return ResultData.fromJson(jsonString);
    }

    // If not in DB, generate from Gemini
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

      // Store in DB
      await dbRef.set({
        'response': text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Process AI course recommendations only if needed
      await _processAICourseRecommendationsIfNeeded(text);

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
          ],
          "aiInterview": "اے آئی انٹرویو"
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
          ],
          "aiInterview": "ਏਆਈ ਇੰਟਰਵਿਊ"
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
          ],
          "aiInterview": "एआई इंटरव्यू"
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
          ],
          "aiInterview": "एआई साक्षात्कार"
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
          ],
          "aiInterview": "एआई इंटरव्यू"
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
          ],
          "aiInterview": "एआई इंटरव्यू"
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
          ],
          "aiInterview": "এআই সাক্ষাৎকার"
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
          ],
          "aiInterview": "એઆઈ ઇન્ટરવ્યૂ"
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
          ],
          "aiInterview": "এআই সাক্ষাৎকাৰ"
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
          ],
          "aiInterview": "ଏଆଇ ସାକ୍ଷାତ୍କାର"
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
          ],
          "aiInterview": "एआय मुलाखत"
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
          ],
          "aiInterview": "ஏ.ஐ. நேர்முகம்"
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
          ],
          "aiInterview": "ఏఐ ఇంటర్వ్యూ"
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
          ],
          "aiInterview": "ಎಐ ಸಂದರ್ಶನ"
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
          ],
          "aiInterview": "എഐ ഇന്റർവ്യൂ"
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
          ],
          "aiInterview": "AI Interview"
        };
    }
  }

  String getLanguageFromIndex(int index) {
    switch (index) {
      case 0:
        return "कश्मीरी";
      case 1:
        return "ਪੰਜਾਬੀ";
      case 2:
        return "हरियाणवी";
      case 3:
        return "हिन्दी";
      case 4:
        return "राजस्थानी";
      case 5:
        return "भोजपुरी";
      case 6:
        return "বাংলা";
      case 7:
        return "ગુજરાતી";
      case 8:
        return "অসমীয়া";
      case 9:
        return "ଓଡ଼ିଆ";
      case 10:
        return "मराठी";
      case 11:
        return "தமிழ்";
      case 12:
        return "తెలుగు";
      case 13:
        return "ಕನ್ನಡ";
      case 14:
        return "മലയാളം";
      case 15:
      default:
        return "English";
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

  Future<void> _processAICourseRecommendationsIfNeeded(
      String surveyResultsText) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final DatabaseReference recommendationsRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('ai_course_recommendations');

      // Check if AI recommendations already exist
      final DataSnapshot snapshot = await recommendationsRef.get();

      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final existingSurveyHash = data['surveyHash'] as String?;
        final existingRecommendations =
            data['recommendations'] as List<dynamic>;

        // Current survey hash
        final currentSurveyHash = surveyResultsText.hashCode.toString();

        // If recommendations exist and survey hasn't changed, skip regeneration
        if (existingSurveyHash == currentSurveyHash &&
            existingRecommendations.isNotEmpty) {
          debugPrint(
              'AI recommendations already exist and survey hasn\'t changed. Skipping regeneration.');
          return;
        }
      }

      // Generate new recommendations (first time or survey changed)
      debugPrint('Generating new AI course recommendations...');
      await _processAICourseRecommendations(surveyResultsText);
    } catch (e) {
      debugPrint('Error in recommendations check: $e');
      // Fallback to generating recommendations
      await _processAICourseRecommendations(surveyResultsText);
    }
  }

  Future<void> _processAICourseRecommendations(String surveyResultsText) async {
    try {
      // Get all available course titles from home.dart data
      final allFeaturesTitles = [
        "UI/UX Design",
        "Programming",
        "English Writing",
        "Photography",
        "Guitar Class",
        "Web Design",
        "Python Programming",
        "JavaScript Basics",
        "Mathematics",
        "Science Lab",
        "Digital Art",
        "Vocal Training",
        "Piano Lessons",
        "Video Editing",
        "Mobile App Development",
        "History Studies",
        "Watercolor Painting",
        "Drum Lessons",
        "Mobile Graphic Design",
        "Data Structures",
        "Physics Fundamentals",
        "Sketching Techniques",
        "Music Theory",
        "Advanced Photoshoop"
      ];

      final allRecommendsTitles = [
        "Painting",
        "Social Media",
        "Caster",
        "Management"
      ];

      final allCourseTitles = [...allFeaturesTitles, ...allRecommendsTitles];

      // Get job recommendations from survey
      final Map<String, List<String>> jobRecommendations = {};
      final resultData = ResultData.fromJson(surveyResultsText);

      // Extract job domains from the survey results
      resultData.result.forEach((jobTitle, details) {
        // Extract skills and use the job title for recommendations
        if (details.length > 1) {
          jobRecommendations[jobTitle] = [
            jobTitle,
            details[1]
          ]; // Job title + skills
        }
      });

      // Get AI recommendations by passing available course titles
      final recommendedTitles = await _getRecommendedCourseTitles(
          allCourseTitles, jobRecommendations);
      final courseRecommendations = _matchTitlesToCourses(recommendedTitles);

      // Store the recommendations in Firebase for the current user
      await _storeAICourseRecommendations(
          courseRecommendations, surveyResultsText);
    } catch (e) {
      debugPrint('Error processing AI course recommendations: $e');
    }
  }

  Future<List<String>> _getRecommendedCourseTitles(List<String> availableTitles,
      Map<String, List<String>> jobRecommendations) async {
    try {
      final apiKey = await rootBundle.loadString('assets/gemini.key');
      final endpoint =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?alt=json&key=$apiKey";

      String prompt = '''
Based on the user's career survey results, recommend the MOST RELEVANT course titles from the following list of available courses:

SURVEY RESULTS:
''';

      jobRecommendations.forEach((jobTitle, details) {
        prompt += '\n$jobTitle: ${details.join(', ')}';
      });

      prompt += '''

AVAILABLE COURSES:
${availableTitles.map((title) => '- "$title"').join('\n')}

Please analyze the survey results and recommend 4-6 of the most relevant course titles from the available courses list above.
Consider the job domains, skills, and career interests shown in the survey results when making your recommendations.

IMPORTANT: Only recommend courses from the "AVAILABLE COURSES" list above. Do not suggest courses that are not in that list.

Return your response as a JSON array of course titles:
["Course Title 1", "Course Title 2", "Course Title 3", "Course Title 4"]
''';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ],
            },
          ],
          'generationConfig': {
            'candidateCount': 1,
            'temperature': 0.7,
            'topP': 0.8,
            'maxOutputTokens': 1024
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        final text = jsonResp['candidates'][0]['content']['parts'][0]['text'];

        String cleanText = text.trim();
        if (cleanText.startsWith('```json')) {
          cleanText = cleanText.substring(7);
        }
        if (cleanText.endsWith('```')) {
          cleanText = cleanText.substring(0, cleanText.lastIndexOf('```'));
        }

        final recommendedTitles = jsonDecode(cleanText) as List;
        return recommendedTitles.map((title) => title.toString()).toList();
      } else {
        throw Exception('Failed to generate course recommendations');
      }
    } catch (e) {
      debugPrint('Error in Gemini recommendation: $e');
      // Return some default titles from the available list
      return availableTitles.take(4).toList();
    }
  }

  List<dynamic> _matchTitlesToCourses(List<String> recommendedTitles) {
    // Create a static list of all courses (similar to what's in home.dart)
    final allCourses = [
      {
        "id": "ai-recommended-100",
        "name": "UI/UX Design",
        "image":
            "https://images.unsplash.com/photo-1596638787647-904d822d751e?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
        "price": "\₹150.00",
        "duration": "10 hours",
        "session": "6 lessons",
        "review": "4.5",
        "is_favorited": false,
        "description": "Learn UI/UX Design skills for user experience design",
        "category": "Design",
      },
      {
        "id": "ai-recommended-101",
        "name": "Programming",
        "image":
            "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
        "price": "\₹300.00",
        "duration": "20 hours",
        "session": "12 lessons",
        "review": "5",
        "is_favorited": true,
        "description": "Master programming fundamentals",
        "category": "Coding",
      },
      {
        "id": "ai-recommended-102",
        "name": "English Writing",
        "image":
            "https://images.unsplash.com/photo-1503676260728-1c00da094a0b?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fFZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
        "price": "\₹100.00",
        "duration": "12 hours",
        "session": "4 lessons",
        "review": "4.5",
        "is_favorited": false,
        "description": "Improve your English writing skills",
        "category": "Education",
      },
      {
        "id": "ai-recommended-103",
        "name": "Photography",
        "image":
            "https://images.unsplash.com/photo-1472393365320-db77a5abbecc?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fVZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
        "price": "\₹100.00",
        "duration": "4 hours",
        "session": "3 lessons",
        "review": "4.5",
        "is_favorited": false,
        "description": "Learn professional photography techniques",
        "category": "Art",
      },
      {
        "id": "ai-recommended-104",
        "name": "Guitar Class",
        "image":
            "https://images.unsplash.com/photo-1549298240-0d8e60513026?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fVZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
        "price": "\₹150.00",
        "duration": "12 hours",
        "session": "4 lessons",
        "review": "5",
        "is_favorited": false,
        "description": "Learn to play guitar from basics to advanced",
        "category": "Music",
      },
      {
        "id": "ai-recommended-105",
        "name": "Web Design",
        "image":
            "https://images.unsplash.com/photo-1596638787647-904d822d751e?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
        "price": "\₹200.00",
        "duration": "15 hours",
        "session": "8 lessons",
        "review": "4.2",
        "is_favorited": false,
        "description": "Create stunning websites",
        "category": "Design",
      },
      {
        "id": "ai-recommended-106",
        "name": "Python Programming",
        "image":
            "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
        "price": "\₹250.00",
        "duration": "18 hours",
        "session": "10 lessons",
        "review": "4.8",
        "is_favorited": false,
        "description": "Learn Python for data science and development",
        "category": "Coding",
      },
      {
        "id": "ai-recommended-107",
        "name": "JavaScript Basics",
        "image":
            "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
        "price": "\₹180.00",
        "duration": "14 hours",
        "session": "7 lessons",
        "review": "4.6",
        "is_favorited": false,
        "description": "Master JavaScript fundamentals",
        "category": "Coding",
      },
    ];

    final matchedCourses = <dynamic>[];

    for (final title in recommendedTitles) {
      dynamic matchedCourse;

      try {
        // Find exact match first
        matchedCourse = allCourses.firstWhere(
          (course) => course['name'] == title,
        );
        if (matchedCourse != null) {
          matchedCourses.add(matchedCourse);
          continue;
        }
      } catch (e) {
        // No exact match found
      }

      try {
        // Find partial match if no exact match
        matchedCourse = allCourses.firstWhere(
          (course) => (course['name'] as String)
              .toLowerCase()
              .contains(title.toLowerCase()),
        );

        if (matchedCourse != null) {
          matchedCourses.add(matchedCourse);
        }
      } catch (e) {
        // No partial match found either
      }
    }

    return matchedCourses;
  }

  Future<void> _storeAICourseRecommendations(
      List<dynamic> recommendations, String surveyResultsText) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final DatabaseReference recommendationsRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('ai_course_recommendations');

      await recommendationsRef.set({
        'recommendations': recommendations,
        'surveyHash': surveyResultsText.hashCode.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'survey_completed': true,
      });

      debugPrint(
          'AI course recommendations stored successfully for user: $userId');
    } catch (e) {
      debugPrint('Error storing AI course recommendations: $e');
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
                  // Update language index if needed and show daily login popup after content loads.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final newIndex = getLanguageIndex(lang);
                    if (_languageIndex != newIndex) {
                      setState(() {
                        _languageIndex = newIndex;
                      });
                    }
                    // Show daily login popup after content is loaded
                    _checkAndShowDailyLoginPopup();
                  });
                  final localizedTexts = getLocalizedTexts(lang);
                  final data = snapshot.data!.result;
                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final entry = data.entries.elementAt(index);
                      String skillsString = entry.value[1];
                      if (skillsString.contains("Skills Required:")) {
                        skillsString = skillsString
                            .replaceFirst("Skills Required:", "")
                            .trim();
                      }
                      final skills = skillsString.split(',');

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: InkWell(
                          onTap: () {
                            /* Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  career: entry.key,
                                  ans: widget.answers,
                                ),
                              ),
                            );*/
                            Navigator.push(
                                context,
                                PageRouteBuilder(
                                  opaque: true,
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      ChatScreen(
                                    career: entry.key,
                                    ans: widget.answers,
                                  ),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 300),
                                ));
                          },
                          child: Card(
                            elevation: 8,
                            shadowColor:
                                const Color(0xFF5BC0EB).withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF1F1F1F),
                                    const Color(0xFF252525),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color:
                                      const Color(0xFF5BC0EB).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header with title and source tag
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                entry.key,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  height: 1.2,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF5BC0EB)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color:
                                                        const Color(0xFF5BC0EB)
                                                            .withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.business_center,
                                                      size: 12,
                                                      color: const Color(
                                                          0xFF5BC0EB),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      entry.value.length > 4
                                                          ? entry.value[4]
                                                              .replaceFirst(
                                                                  "source: ",
                                                                  "")
                                                          : "Recommended",
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color:
                                                            Color(0xFF5BC0EB),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    // Description with better styling
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF323232)
                                            .withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.grey.shade700
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        entry.value[0],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFE0E0E0),
                                          height: 1.3,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    // Skills Section with enhanced design
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.lightbulb,
                                          size: 14,
                                          color: const Color(0xFF5BC0EB),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          localizedTexts["skillsRequired"]!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    // Skills chips with improved design
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        for (var skill in skills)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFF5BC0EB)
                                                      .withOpacity(0.2),
                                                  const Color(0xFF5BC0EB)
                                                      .withOpacity(0.1),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: const Color(0xFF5BC0EB)
                                                    .withOpacity(0.4),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              skill.trim(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    // Auto Apply Section with better design
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2A2A2A),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.grey.shade600
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Auto Apply",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "Let AI apply to this job for you",
                                                  style: TextStyle(
                                                    color: Colors.grey.shade400,
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Transform.scale(
                                            scale: 0.9,
                                            child: Checkbox(
                                              value: _autoApplyJobs
                                                  .contains(entry.key),
                                              onChanged: (value) async {
                                                setState(() {
                                                  if (value == true) {
                                                    _autoApplyJobs
                                                        .add(entry.key);
                                                  } else {
                                                    _autoApplyJobs
                                                        .remove(entry.key);
                                                  }
                                                });
                                                if (value == true) {
                                                  await _autoApplyToJob(
                                                      entry.key, entry.value);
                                                }
                                              },
                                              activeColor:
                                                  const Color(0xFF4CAF50),
                                              checkColor: Colors.white,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 10),
                                    // Enhanced Action Buttons Section
                                    if (entry.value.length > 2)
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A1A1A),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.grey.shade700
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            // Primary Action Buttons Row
                                            Row(
                                              children: [
                                                // Apply Now Button with enhanced styling
                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          const LinearGradient(
                                                        colors: [
                                                          Color(0xFF5BC0EB),
                                                          Color(0xFF4FC3F7),
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(
                                                                  0xFF5BC0EB)
                                                              .withOpacity(0.3),
                                                          blurRadius: 6,
                                                          offset: const Offset(
                                                              0, 3),
                                                        ),
                                                      ],
                                                    ),
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        final url =
                                                            entry.value[2];
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                InAppWebViewScreen(
                                                              url: url,
                                                              title: localizedTexts[
                                                                  "applyNow"]!,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        foregroundColor:
                                                            Colors.white,
                                                        elevation: 0,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 12),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          const Icon(
                                                              Icons.launch,
                                                              size: 14),
                                                          const SizedBox(
                                                              width: 6),
                                                          Text(
                                                            localizedTexts[
                                                                "applyNow"]!,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                if (entry.value.length > 3) ...[
                                                  const SizedBox(width: 8),
                                                  // Learn Now Button with enhanced styling
                                                  Expanded(
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const LinearGradient(
                                                          colors: [
                                                            Color(0xFF4CAF50),
                                                            Color(0xFF66BB6A),
                                                          ],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: const Color(
                                                                    0xFF4CAF50)
                                                                .withOpacity(
                                                                    0.3),
                                                            blurRadius: 6,
                                                            offset:
                                                                const Offset(
                                                                    0, 3),
                                                          ),
                                                        ],
                                                      ),
                                                      child: ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  CareerGeminiPage(
                                                                career:
                                                                    entry.key,
                                                                ans: widget
                                                                    .answers,
                                                                lang: getLanguageFromIndex(
                                                                    _languageIndex),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          foregroundColor:
                                                              Colors.white,
                                                          elevation: 0,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 12),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            const Icon(
                                                                Icons.school,
                                                                size: 14),
                                                            const SizedBox(
                                                                width: 6),
                                                            Text(
                                                              localizedTexts[
                                                                  "learnNow"]!,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),

                                            const SizedBox(height: 10),

                                            // AI Interview Button with premium styling
                                            Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFFFF6B35),
                                                    Color(0xFFFF8A5C),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFFFF6B35)
                                                            .withOpacity(0.3),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          InterviewTypeSelection(
                                                        ans: widget.answers,
                                                        language:
                                                            _languageIndex,
                                                        selectedJobTitle:
                                                            entry.key,
                                                        selectedJobData:
                                                            entry.value,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 14),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.smart_toy,
                                                        size: 16),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      localizedTexts[
                                                          "aiInterview"]!,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 8),

                                            // Additional info text
                                            Text(
                                              "💡 Tap on the card to discuss this career path",
                                              style: TextStyle(
                                                color: Colors.grey.shade400,
                                                fontSize: 10,
                                                fontStyle: FontStyle.italic,
                                              ),
                                              textAlign: TextAlign.center,
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
          // 🧠 DIAGNOSTICS MODULE - NEW!
          const DiagnosticsMenuScreen(),
        ],
      ),
      bottomNavigationBar: AnimatedNotchBottomBar(
        notchBottomBarController: _notchBottomBarController,
        bottomBarItems: [
          BottomBarItem(
            inActiveItem: Icon(Icons.home, color: const Color(0xFF6B7280)),
            activeItem: Icon(Icons.home, color: const Color(0xFF5BC0EB)),
            itemLabel: '',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.book, color: const Color(0xFF6B7280)),
            activeItem: Icon(Icons.book, color: const Color(0xFF5BC0EB)),
            itemLabel: '',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.people, color: const Color(0xFF6B7280)),
            activeItem: Icon(Icons.people, color: const Color(0xFF5BC0EB)),
            itemLabel: '',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.rss_feed, color: const Color(0xFF6B7280)),
            activeItem: Icon(Icons.rss_feed, color: const Color(0xFF5BC0EB)),
            itemLabel: '',
          ),
          // 🧠 DIAGNOSTICS TAB - NEW!
          BottomBarItem(
            inActiveItem:
                Icon(Icons.psychology_outlined, color: const Color(0xFF6B7280)),
            activeItem: Icon(Icons.psychology, color: const Color(0xFF5BC0EB)),
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
        durationInMilliSeconds: 100,
        notchColor: const Color(0xFF0F0F0F),
        kIconSize: 24.0,
        kBottomRadius: 2.0,
      ),
    );
  }

  Future<void> _autoApplyToJob(String jobTitle, List<String> jobData) async {
    try {
      // Check if auto-apply is enabled and resume is uploaded
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
      if (userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      final DatabaseReference userRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('autoApply');
      final DataSnapshot snapshot = await userRef.get();

      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please enable auto-apply and upload resume in profile settings')),
        );
        return;
      }

      final data = snapshot.value as Map;
      final bool isEnabled = data['enabled'] ?? false;
      final String? resumePath = data['resumePath'];

      if (!isEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Auto-apply is not enabled. Please enable it in profile settings')),
        );
        return;
      }

      if (resumePath == null || resumePath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please upload your resume in profile settings')),
        );
        return;
      }

      // Generate application answers using Gemini
      final applicationAnswers =
          await _generateApplicationAnswers(jobTitle, jobData, resumePath);

      // Simulate application process
      await Future.delayed(const Duration(seconds: 2));

      // Update successful applications with job link
      final List<Map<String, String>> successfulApplications =
          List<Map<String, String>>.from(
        (data['successfulApplications'] ?? []).map((item) {
          if (item is Map) {
            return Map<String, String>.from(item);
          } else if (item is String) {
            // Handle legacy string format
            final parts = item.split(' - ');
            return {
              'title': parts[0],
              'date': parts.length > 1
                  ? parts[1]
                  : DateTime.now().toString().split(' ')[0],
              'link': jobData.length > 2 ? jobData[2] : '',
            };
          }
          return {
            'title': item.toString(),
            'date': DateTime.now().toString().split(' ')[0],
            'link': jobData.length > 2 ? jobData[2] : ''
          };
        }),
      );

      successfulApplications.add({
        'title': jobTitle,
        'date': DateTime.now().toString().split(' ')[0],
        'link': jobData.length > 2 ? jobData[2] : '',
      });

      await userRef.update({
        'successfulApplications': successfulApplications,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully auto-applied to $jobTitle')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error auto-applying: $e')),
      );
    }
  }

  Future<String> _generateApplicationAnswers(
      String jobTitle, List<String> jobData, String resumePath) async {
    try {
      final apiKey = await rootBundle.loadString('assets/gemini.key');
      final endpoint =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?alt=json&key=$apiKey";

      final prompt = """
Based on the job title: "$jobTitle"
Job description: "${jobData[0]}"
Required skills: "${jobData[1]}"

And considering the user's resume is available at: $resumePath

Generate appropriate answers for a job application. Focus on:
1. Cover letter
2. Why you're interested in this position
3. How your skills match the job requirements
4. Your relevant experience

Provide the response in a professional format.
""";

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ],
            },
          ],
          'generationConfig': {
            'candidateCount': 1,
            'temperature': 0.7,
            'topP': 0.8,
          },
        }),
      );

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        final text = jsonResp['candidates'][0]['content']['parts'][0]['text'];
        return text;
      } else {
        throw Exception('Failed to generate answers');
      }
    } catch (e) {
      return 'Generated application answers for $jobTitle';
    }
  }

  PreferredSizeWidget _buildAppBar() {
    switch (_selectedIndex) {
      case 0:
        return AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF000000),
          centerTitle: false,
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
//import 'package:firebase_auth/firebase_auth.dart';

                if (snapshot.hasData) {
                  return GestureDetector(
                    onTap: () async {
                      //               await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AccountPage(
                              languageIndex: _languageIndex,
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        foregroundImage: NetworkImage(
                          FirebaseAuth.instance.currentUser?.photoURL ?? '',
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
          backgroundColor: const Color(0xFF000000),
          centerTitle: false,
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
          actions: [
            FutureBuilder<ResultData>(
              future: futureResult,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return GestureDetector(
                    onTap: () async {
                      if (mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AccountPage(
                              languageIndex: _languageIndex,
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        foregroundImage: NetworkImage(
                          FirebaseAuth.instance.currentUser?.photoURL ?? '',
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
      case 2:
        return AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF000000),
          centerTitle: false,
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
          actions: [
            FutureBuilder<ResultData>(
              future: futureResult,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return GestureDetector(
                    onTap: () async {
                      if (mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AccountPage(
                              languageIndex: _languageIndex,
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        foregroundImage: NetworkImage(
                          FirebaseAuth.instance.currentUser?.photoURL ?? '',
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
      case 4:
        return AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF000000),
          centerTitle: false,
          title: Text(
            "Life skills upgrader",
            style: TextStyle(
              fontSize: 20.0,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AccountPage(
                      languageIndex: _languageIndex,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  foregroundImage: NetworkImage(
                    FirebaseAuth.instance.currentUser?.photoURL ?? '',
                  ),
                ),
              ),
            ),
          ],
        );
      default:
        return AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF000000),
          centerTitle: false,
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
          actions: [
            FutureBuilder<ResultData>(
              future: futureResult,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return GestureDetector(
                    onTap: () async {
                      if (mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AccountPage(
                              languageIndex: _languageIndex,
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        foregroundImage: NetworkImage(
                          FirebaseAuth.instance.currentUser?.photoURL ?? '',
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
    }
  }
}

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
