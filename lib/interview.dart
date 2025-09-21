import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'question_data.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/javascript.dart' as js_lang;
import 'package:highlight/languages/python.dart' as py_lang;
import 'package:highlight/languages/java.dart' as java_lang;
import 'package:highlight/languages/cpp.dart' as cpp_lang;
import 'package:highlight/languages/php.dart' as php_lang;
import 'package:highlight/languages/ruby.dart' as ruby_lang;
import 'package:highlight/languages/go.dart' as go_lang;
import 'package:highlight/languages/swift.dart' as swift_lang;
import 'jdoodle_service.dart';
import 'gamification_service.dart';

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

class InterviewPage extends StatefulWidget {
  final String career;
  final QuestionData ans;
  final int language;
  final String interviewType;
  final String? jobTitle;

  const InterviewPage({
    Key? key,
    required this.career,
    required this.ans,
    required this.language,
    required this.interviewType,
    this.jobTitle,
  }) : super(key: key);

  @override
  _InterviewPageState createState() => _InterviewPageState();
}

class _InterviewPageState extends State<InterviewPage> {
  CameraController? _cameraController;
  Future<void>? _initializeCameraFuture;

  // Speech-to-text instance.
  late stt.SpeechToText _speech;
  bool _isSpeechAvailable = false;

  // Text-to-speech instance.
  final FlutterTts _flutterTts = FlutterTts();

  bool _isRecording = false;
  String _studentAnswer = '';
  final TextEditingController _answerController = TextEditingController();

  // Interview state variables.
  String _currentQuestion = '';
  String _feedback = '';
  int _score = 0;
  bool _isProcessing = false;
  bool _currentQuestionAnswered =
      false; // Track if current question has been answered
  int _questionCount = 0;
  final int _maxInterviewDurationMinutes = 60; // Changed to 1 hour
  DateTime? _interviewStartTime;
  DateTime? _interviewEndTime;
  DateTime? _currentQuestionStartTime; // When current question was displayed

  // IDE state variables
  bool _showIDE = false;
  String _ideCode = '';
  String _selectedLanguage = 'JavaScript';

  // Timer variables
  Timer? _interviewTimer;
  Duration _remainingTime = const Duration(hours: 1);
  bool _isInterviewActive = true;

  // Rating popup variables
  int _selectedRating = 0;
  final TextEditingController _commentsController = TextEditingController();

  // Store generated questions to avoid duplicates
  final List<String> _generatedQuestions = [];

  // Firebase Realtime Database instance.
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Store the current interview record key for updates
  String? _currentInterviewRecordKey;

  late final int _langIndex;

  final Map<String, List<String>> _localizedStrings = {
    'appTitle': [
      "एआई इंटरव्यू", // Kashmiri (Devanagari)
      "ਏਆਈ ਇੰਟਰਵਿਊ", // Punjabi (Gurmukhi)
      "एआई इंटरव्यू", // Haryanvi
      "एआई इंटरव्यू", // Hindi
      "एआई इंटरव्यू", // Rajasthani
      "एआई इंटरव्यू", // Bhojpuri
      "এআই ইন্টারভিউ", // Bengali
      "એઆઈ ઇન્ટરવ્યુ", // Gujarati
      "এআই ইণ্টাৰভিউ", // Assamese
      "ଏଆଇ ଇଣ୍ଟରଭ୍ୟୁ", // Odia
      "एआय मुलाखत", // Marathi
      "ஏ.ஐ. நேர்காணல்", // Tamil
      "ఏఐ ఇంటర్వ్యూ", // Telugu
      "ಎಐ ಸಂದರ್ಶನ", // Kannada
      "എഐ അഭിമുഖം", // Malayalam
      "AI Interview", // English
    ],
    'interviewQuestionTitle': [
      "इंटरव्यू प्रश्न",
      "ਇੰਟਰਵਿਊ ਸਵਾਲ",
      "इंटरव्यू सवाल",
      "साक्षात्कार प्रश्न",
      "इंटरव्यू प्रश्न",
      "इंटरव्यू सवाल",
      "সাক্ষাৎকার প্রশ্ন",
      "ઇન્ટરવ્યૂ પ્રશ્ન",
      "সাক্ষাৎকাৰ প্ৰশ্ন",
      "ସାକ୍ଷାତକାର ପ୍ରଶ୍ନ",
      "मुलाखत प्रश्न",
      "பேட்டி கேள்வி",
      "ఇంటర్వ్యూ ప్రశ్న",
      "ಸಂಭಾಷಣೆ ಪ್ರಶ್ನೆ",
      "അഭിമുഖം ചോദ്യങ്ങൾ",
      "Interview Question",
    ],
    'yourAnswerTitle': [
      "तुम्हार उत्तर",
      "ਤੁਹਾਡਾ ਜਵਾਬ",
      "तुम्हारा जवाब",
      "आपका उत्तर",
      "आपको उत्तर",
      "आपके जवाब",
      "আপনার উত্তর",
      "તમારો જવાબ",
      "আপোনাৰ উত্তৰ",
      "ଆପଣଙ୍କର ଉତ୍ତର",
      "तुमचं उत्तर",
      "உங்கள் பதில்",
      "మీ జవాబు",
      "ನಿಮ್ಮ ಉತ್ತರ",
      "നിങ്ങളുടെ ഉത്തരവ്",
      "Your Answer",
    ],
    'startRecording': [
      "शुरू",
      "ਸ਼ੁਰੂ",
      "शुरू",
      "शुरू",
      "शुरू",
      "शुरू",
      "শুরু",
      "શરૂ",
      "আৰম্ভ",
      "ଆରମ୍ଭ",
      "सुरू",
      "தொடங்கு",
      "ఆరంభించు",
      "ಆರಂಭಿಸಿ",
      "തുടങ്ങുക",
      "Start",
    ],
    'stopRecording': [
      "रुको",
      "ਰੁਕੋ",
      "रुको",
      "रुको",
      "रुको",
      "रुको",
      "থামো",
      "રुको",
      "ৰুক",
      "ରୁକ",
      "थांब",
      "நிறுத்து",
      "ఆపు",
      "ನಿಲ್ಲಿಸಿ",
      "നിര്‍ത്തുക",
      "Stop",
    ],
    'submitAnswer': [
      "सबमिट",
      "ਸਬਮਿਟ",
      "सबमिट",
      "सबमिट",
      "सबमिट",
      "सबमिट",
      "সাবমিট",
      "સબમિટ",
      "সাবমিট",
      "ସବମିଟ",
      "सबमिट",
      "சமர்ப்பி",
      "సబ్మిట్",
      "ಸಬ್ಮಿಟ್",
      "സബ്മിറ്റ്",
      "Submit",
    ],
    'nextQuestion': [
      "अगला प्रश्न",
      "ਅਗਲਾ ਸਵਾਲ",
      "अगला सवाल",
      "अगला प्रश्न",
      "अगला प्रश्न",
      "अगला सवाल",
      "পরবর্তী প্রশ্ন",
      "આગળનો પ્રશ્ન",
      "পৰৱৰ্তী প্ৰশ্ন",
      "ପରବର୍ତ୍ତୀ ପ୍ରଶ୍ନ",
      "पुढील प्रश्न",
      "அடுத்த கேள்வி",
      "తరువాతి ప్రశ్న",
      "ಮುಂದಿನ ಪ್ರಶ್ನೆ",
      "അടുത്ത ചോദ്യം",
      "Next Question",
    ],
    'interviewCompleted': [
      "इंटरव्यू पूरा हुआ",
      "ਇੰਟਰਵਿਊ ਪੂਰਾ ਹੋਇਆ",
      "इंटरव्यू पूरा हो गया",
      "साक्षात्कार पूर्ण हुआ",
      "इंटरव्यू पूरा हुआ",
      "इंटरव्यू पूरा भइल",
      "সাক্ষাৎকার সম্পন্ন",
      "ઇન્ટરવ્યૂ પૂર્ણ થયું",
      "সাক্ষাৎকাৰ সম্পন্ন",
      "ସାକ୍ଷାତକାର ସମ୍ପୂର୍ଣ୍ଣ",
      "मुलाखत पूर्ण झाली",
      "பேட்டி முடிந்தது",
      "ఇంటర్వ్యూ పూర్తయింది",
      "ಸಂಭಾಷಣೆ ಪೂರ್ಣವಾಯಿತು",
      "അഭിമുഖം പൂർത്തിയായി",
      "Interview Completed",
    ],
    'scoreLabel': [
      "स्कोर:",
      "ਸਕੋਰ:",
      "स्कोर:",
      "स्कोर:",
      "स्कोर:",
      "स्कोर:",
      "স্কোর:",
      "સ્કોર:",
      "স্ক'ৰ:",
      "ସ୍କୋର:",
      "स्कोर:",
      "மதிப்பெண்:",
      "స్కోరు:",
      "ಸ್ಕೋರ್:",
      "സ്കോർ:",
      "Score:",
    ],
    'feedbackLabel': [
      "प्रतिक्रिया:",
      "ਪ੍ਰਤੀਕਿਰਿਆ:",
      "प्रतिक्रिया:",
      "प्रतिक्रिया:",
      "प्रतिक्रिया:",
      "प्रतिक्रिया:",
      "ফিডব্যাক:",
      "ફીડબૅક:",
      "প্ৰতিক্ৰিয়া:",
      "ପ୍ରତିକ୍ରିୟା:",
      "फीडबॅक:",
      "பின்னூட்டம்:",
      "ఫీడ్‌బ్యాక్:",
      "ಪ್ರತಿಕ್ರಿಯೆ:",
      "ഫീഡ്ബാക്ക്:",
      "Feedback:",
    ],
    'errorGeneratingQuestion': [
      "प्रश्न बनाने में त्रुटि। कृपया पुनः प्रयास करें।",
      "ਸਵਾਲ ਤਿਆਰ ਕਰਨ ਵਿੱਚ ਗਲਤੀ। ਕ੍ਰਿਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।",
      "प्रश्न बनाने में गलती। कृपया फिर से कोशिश करें।",
      "प्रश्न जनरेट करने में त्रुटि। कृपया पुनः प्रयास करें।",
      "प्रश्न बनाने में त्रुटि। कृपया फिर से प्रयास करें।",
      "प्रश्न बनावे में गलती। कृपया फेर से कोशिश करीं।",
      "প্রশ্ন তৈরি করতে সমস্যা। অনুগ্রহ করে আবার চেষ্টা করুন।",
      "પ્રશ્ન જનરેટ કરવામાં ભૂલ. કૃપા કરીને ફરીથી પ્રયત્ન કરો.",
      "প্ৰশ্ন নিৰ্মাণত ত্ৰুটি। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।",
      "ପ୍ରଶ୍ନ ତିଆରିରେ ତ୍ରୁଟି। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।",
      "प्रश्न तयार करण्यात त्रुटी. कृपया पुन्हा प्रयत्न करा.",
      "கேள்வி உருவாக்கத்தில் பிழை. தயவுசெய்து மீண்டும் முயற்சிக்கவும்.",
      "ప్రశ్న సృష్టించడంలో లోపం. దయచేసి మళ్లీ ప్రయత్నించండి.",
      "ಪ್ರಶ್ನೆ ರಚನೆಯಲ್ಲಿ ದೋಷ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",
      "ചോദ്യം സൃഷ്ടിക്കുന്നതിൽ പിശക്. ദയവായി വീണ്ടും ശ്രമിക്കുക.",
      "Error generating question. Please try again.",
    ],
    'interviewCompleteMessage': [
      "साक्षात्कार पूरा हुआ। आपके समय के लिए धन्यवाद!",
      "ਇੰਟਰਵਿਊ ਪੂਰਾ ਹੋ ਗਿਆ। ਤੁਹਾਡੇ ਸਮੇਂ ਲਈ ਧੰਨਵਾਦ!",
      "साक्षात्कार पूरा हो गया। आपके समय के लिए धन्यवाद!",
      "साक्षात्कार पूर्ण हुआ। आपके समय के लिए धन्यवाद!",
      "साक्षात्कार पूरा हुआ। आपके समय के लिए धन्यवाद!",
      "साक्षात्कार पूरा भइल। रउरा समय खातिर धन्यवाद!",
      "সাক্ষাৎকার সম্পন্ন। আপনার সময়ের জন্য ধন্যবাদ!",
      "ઇન્ટરવ્યૂ પૂર્ણ થયું. તમારા સમય માટે આભાર!",
      "সাক্ষাৎকাৰ সম্পন্ন। আপোনাৰ সময়ৰ বাবে ধন্যবাদ!",
      "ସାକ୍ଷାତକାର ସମ୍ପୂର୍ଣ୍ଣ। ଆପଣଙ୍କର ସମୟ ପାଇଁ ଧନ୍ୟବାଦ!",
      "मुलाखत पूर्ण झाली. आपल्या वेळेसाठी धन्यवाद!",
      "பேட்டி முடிந்தது. உங்கள் நேரத்திற்கு நன்றி!",
      "ఇంటర్వ్యూ పూర్తయింది. మీ సమయానికి ధన్యవాదాలు!",
      "ಸಂಭಾಷಣೆ ಪೂರ್ಣವಾಯಿತು. ನಿಮ್ಮ ಸಮಯಕ್ಕಾಗಿ ಧನ್ಯವಾದಗಳು!",
      "അഭിമുഖം പൂർത്തിയായി. നിങ്ങളുടെ സമയത്തിന് നന്ദി!",
      "Interview complete. Thank you for your time!",
    ],
    'meetingView': [
      "बैठक दृश्य",
      "ਮੀਟਿੰਗ ਵਿਊ",
      "बैठक दृश्य",
      "मीटिंग दृश्य",
      "बैठक दृश्य",
      "बैठक दृश्य",
      "মিটিং ভিউ",
      "મીટિંગ દૃશ્ય",
      "মিটিং ভিউ",
      "ମିଟିଂ ଭ୍ୟୁ",
      "मीटिंग दृश्य",
      "கூட்டம் பார்வை",
      "మీటింగ్ దృశ్యం",
      "ಮೀಟಿಂಗ್ ದೃಶ್ಯ",
      "മീറ്റിംഗ് വീക്ഷണം",
      "Meeting View",
    ],
  };

  // Helper method to get the localized string by key.
  String _t(String key) {
    return _localizedStrings[key]?[_langIndex] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _langIndex = (widget.language);
    _initializeFirebase();
    _initializeCamera();
    _initializeSpeech();
    _initializeTts();
    _startInterview();
    _startTimer();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    debugPrint("Firebase initialized.");
  }

  Future<void> _initializeSpeech() async {
    _speech = stt.SpeechToText();
    _isSpeechAvailable = await _speech.initialize();
    debugPrint("Speech-to-text initialized: $_isSpeechAvailable");
    setState(() {});
  }

  Future<void> _initializeTts() async {
    // Optional: set TTS language or speech rate here.
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    debugPrint("Text-to-Speech initialized.");
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _answerController.dispose();
    _commentsController.dispose();
    _speech.stop();
    _flutterTts.stop();
    _interviewTimer?.cancel();
    super.dispose();
  }

  /// Initialize the camera by selecting the front camera with improved retry logic.
  Future<void> _initializeCamera() async {
    debugPrint("DEBUG: Starting camera initialization...");

    // Add a longer initial delay to ensure all permissions are granted and camera is ready
    await Future.delayed(const Duration(seconds: 1));
    debugPrint("DEBUG: Initial delay completed, checking permissions...");

    // Retry logic with exponential backoff
    int maxRetries = 3;
    int currentRetry = 0;

    while (currentRetry < maxRetries) {
      try {
        debugPrint(
            "DEBUG: Camera initialization attempt ${currentRetry + 1}/${maxRetries}");

        final cameras = await availableCameras();
        debugPrint("DEBUG: Found ${cameras.length} cameras");

        if (cameras.isEmpty) {
          debugPrint("No cameras available");
          setState(() {});
          return;
        }

        // First try to get front camera
        CameraDescription? selectedCamera;
        try {
          selectedCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
          );
          debugPrint("Found front camera: ${selectedCamera.name}");
        } catch (e) {
          debugPrint("Front camera not found, trying back camera");
          try {
            selectedCamera = cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
            );
            debugPrint("Found back camera: ${selectedCamera.name}");
          } catch (e2) {
            debugPrint("No suitable camera found");
            selectedCamera = cameras.first;
            debugPrint("Using first available camera: ${selectedCamera.name}");
          }
        }

        debugPrint("Attempting to initialize camera: ${selectedCamera.name}");

        // Dispose of any existing controller
        await _cameraController?.dispose();
        debugPrint("DEBUG: Disposed existing camera controller");

        // Use lower resolution for better compatibility on first try
        ResolutionPreset resolution = currentRetry == 0
            ? ResolutionPreset.low
            : (currentRetry == 1
                ? ResolutionPreset.medium
                : ResolutionPreset.low);

        _cameraController = CameraController(selectedCamera, resolution);
        debugPrint(
            "DEBUG: Created new camera controller with ${resolution.toString()} resolution");

        // Set the future and wait for initialization with shorter timeout on retries
        _initializeCameraFuture = _cameraController!.initialize();
        debugPrint("DEBUG: Set initialization future");

        // Shorter timeout on retries to fail faster
        Duration timeout = currentRetry == 0
            ? const Duration(seconds: 15)
            : const Duration(seconds: 10);

        await _initializeCameraFuture!.timeout(
          timeout,
          onTimeout: () {
            debugPrint(
                "Camera initialization timed out on attempt ${currentRetry + 1}");
            throw Exception("Camera initialization timed out");
          },
        );

        debugPrint(
            "Camera initialized successfully with ${selectedCamera.name} on attempt ${currentRetry + 1}");

        // Ensure camera is started
        if (_cameraController!.value.isInitialized) {
          debugPrint("Camera is properly initialized and ready");
          // Try to start image stream to ensure camera is active
          try {
            await _cameraController!.startImageStream((image) {
              // Just consume the image stream to keep camera active
              debugPrint("DEBUG: Camera image stream active");
            });
            debugPrint("DEBUG: Camera image stream started successfully");
          } catch (streamError) {
            debugPrint("DEBUG: Failed to start image stream: $streamError");
            // Don't fail completely if stream fails, camera might still work
          }
        }

        setState(() {});
        debugPrint("DEBUG: Camera initialization completed successfully");
        return; // Success, exit retry loop
      } catch (e) {
        debugPrint(
            "Camera initialization failed on attempt ${currentRetry + 1}: $e");

        currentRetry++;

        if (currentRetry < maxRetries) {
          // Wait before retrying with exponential backoff
          int delaySeconds = currentRetry * 2; // 2s, 4s
          debugPrint("Waiting ${delaySeconds} seconds before retry...");
          await Future.delayed(Duration(seconds: delaySeconds));
        } else {
          debugPrint("All camera initialization attempts failed");
          // Set future to null to indicate camera is not available
          _initializeCameraFuture = null;
          setState(() {});
        }
      }
    }
  }

  /// Extract job title from career string
  String _extractJobTitle(String career) {
    if (career.isEmpty) return 'Unknown Job';

    // Handle JSON format (from questionnaire answers)
    try {
      final jsonData = jsonDecode(career);
      if (jsonData is Map && jsonData.containsKey('jobTitle')) {
        return jsonData['jobTitle'] ?? 'Unknown Job';
      }
    } catch (e) {
      // Not JSON, continue with string parsing
    }

    // Handle formatted string like "Web Developer: Create amazing websites..."
    if (career.contains(':')) {
      final parts = career.split(':');
      if (parts.length >= 2) {
        final jobTitle = parts[0].trim();

        // Clean up common prefixes that might appear
        if (jobTitle.toLowerCase().startsWith('i want to be a') ||
            jobTitle.toLowerCase().startsWith('i want to become')) {
          return jobTitle.substring(jobTitle.indexOf('a') + 1).trim();
        }

        // Check if this looks like a job title followed by description
        // Job titles are typically 1-4 words, not too long
        final titleWords = jobTitle.split(' ');
        if (titleWords.length <= 4 && jobTitle.length <= 50) {
          return jobTitle;
        }
      }
    }

    // If no special format detected, return the career as is
    // but limit length for display
    if (career.length > 30) {
      return career.substring(0, 27) + '...';
    }

    return career;
  }

  /// Start the interview session.
  void _startInterview() async {
    _interviewStartTime = DateTime.now();
    debugPrint("Interview started at $_interviewStartTime");

    // Check if IDE should be shown based on the career.
    // This is done early so it doesn't depend on question generation.
    _checkIfIDEShouldBeShown();

    // Add a small delay to ensure all services are properly initialized
    await Future.delayed(const Duration(milliseconds: 500));

    _generateNextQuestion();
  }

  /// Check if the interview duration is over.
  bool get _isInterviewTimeOver {
    if (_interviewStartTime == null) return false;
    final elapsed = DateTime.now().difference(_interviewStartTime!);
    return elapsed.inMinutes >= _maxInterviewDurationMinutes;
  }

  /// Generate the next question using the Gemini API and display it with a typing effect.
  Future<void> _generateNextQuestion() async {
    if (_isInterviewTimeOver) {
      setState(() {
        _currentQuestion = _t('interviewCompleteMessage');
      });
      debugPrint("Interview time over. No more questions.");
      // Speak out the completion message.
      _speak(_currentQuestion);
      return;
    }
    setState(() {
      _isProcessing = true;
      _studentAnswer = '';
      _feedback = '';
      _answerController.text = '';
      _currentQuestionAnswered = false; // Reset flag for new question
    });
    _questionCount++;

    // Reset the record key for the new question so it gets its own record
    _currentInterviewRecordKey = null;

    try {
      final question = await _generateQuestionWithGemini(
          widget.career, widget.ans, _questionCount);
      debugPrint("Generated question: $question");

      // Store the generated question to avoid duplicates
      _generatedQuestions.add(question);

      // Save the generated question (without answer/feedback yet) to Realtime Database.
      _saveInterviewRecord(question: question);
      // Display the question with typewriter effect.
      _displayQuestionWithTypingEffect(question);
    } catch (e) {
      debugPrint("Error generating question: $e");
      setState(() {
        _currentQuestion = _t('errorGeneratingQuestion');
      });
    }
    setState(() {
      _isProcessing = false;
    });
  }

  /// Call Gemini API for generating a question with retry mechanism.
  Future<String> _generateQuestionWithGemini(
      String career, QuestionData ans, int questionNumber) async {
    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // Load API key from asset.
        String apiKey;
        try {
          apiKey = await rootBundle.loadString('assets/gemini.key');
          if (apiKey.trim().isEmpty) {
            throw Exception("API key is empty");
          }
        } catch (e) {
          debugPrint("Error loading API key: $e");
          throw Exception(
              "Failed to load Gemini API key. Please ensure 'assets/gemini.key' exists and contains a valid key.");
        }

        final endpoint =
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?alt=json&key=$apiKey";

        // Create system and user instructions based on interview type.
        String systemString;
        String userString;

        // Get career-specific technical skills and knowledge areas
        String getCareerSpecificPrompt(String career, String interviewType) {
          String careerLower = career.toLowerCase();

          // Define software-related careers that should prioritize DSA questions
          final softwareCareers = [
            'software engineer',
            'software developer',
            'programmer',
            'developer',
            'full stack developer',
            'frontend developer',
            'backend developer',
            'mobile developer',
            'ios developer',
            'android developer',
            'web developer',
            'data scientist',
            'machine learning engineer',
            'ai engineer',
            'computer scientist',
            'it specialist',
            'system administrator',
            'database administrator',
            'devops engineer',
            'cloud engineer',
            'cybersecurity specialist',
            'blockchain developer',
            'game developer',
            'embedded systems engineer',
            'computer engineer',
            'software architect',
            'technical lead',
            'engineering manager'
          ];

          if (interviewType == 'technical') {
            final isSoftwareRelated = softwareCareers.any((swCareer) =>
                careerLower.contains(swCareer) ||
                swCareer.contains(careerLower));
            if (isSoftwareRelated) {
              // STRUCTURED QUESTION SEQUENCE: DSA -> System Design -> Field Specific
              String questionSequence =
                  "QUESTION SEQUENCE: Generate any qn about dsa of level LeetCode medium to hard level DSA questions or questions about system design, Focus on practical coding problems and real-world scenarios.";

              if (careerLower.contains('web') ||
                  careerLower.contains('frontend') ||
                  careerLower.contains('backend')) {
                return "$questionSequence or generate generate questions about web development, including HTML/CSS/JavaScript, frameworks (React, Angular, Vue, Node.js), APIs, databases, security, and modern development practices.";
              } else if (careerLower.contains('mobile') ||
                  careerLower.contains('ios') ||
                  careerLower.contains('android')) {
                return "$questionSequence or generate questions about mobile development, including platform-specific technologies, UI/UX principles, app architecture, performance optimization, and cross-platform development.";
              } else if (careerLower.contains('data') ||
                  careerLower.contains('machine learning') ||
                  careerLower.contains('ai')) {
                return "$questionSequence or generate questions about data science and ML, including statistics, algorithms, Python/R, data processing, model training, deployment, and industry applications.";
              } else if (careerLower.contains('devops') ||
                  careerLower.contains('cloud') ||
                  careerLower.contains('infrastructure')) {
                return "$questionSequence or generate questions about DevOps and cloud infrastructure, including CI/CD, containerization, cloud platforms (AWS, Azure, GCP), monitoring, and automation.";
              } else if (careerLower.contains('security') ||
                  careerLower.contains('cyber')) {
                return "$questionSequence or generate questions about cybersecurity, including threat analysis, encryption, network security, compliance, and security best practices.";
              } else {
                return "$questionSequence or generate questions about system design, programming paradigms, databases, and software development methodologies.";
              }
            } else if (careerLower.contains('designer') ||
                careerLower.contains('ux') ||
                careerLower.contains('ui')) {
              return "Generate technical questions about design and user experience, including design principles, prototyping tools, user research, accessibility, and design systems.";
            } else if (careerLower.contains('analyst') ||
                careerLower.contains('business') ||
                careerLower.contains('consultant')) {
              return "Generate technical questions about business analysis, including requirements gathering, data analysis, process modeling, and business intelligence tools.";
            } else if (careerLower.contains('marketing') ||
                careerLower.contains('digital')) {
              return "Generate technical questions about digital marketing, including SEO, analytics tools, social media platforms, content management, and marketing automation.";
            } else if (careerLower.contains('sales') ||
                careerLower.contains('account')) {
              return "Generate technical questions about sales technologies, including CRM systems, sales automation, lead generation, and customer relationship management.";
            } else {
              return "Generate technical questions relevant to $career, focusing on industry-specific tools, technologies, and domain knowledge.";
            }
          } else if (interviewType == 'hr') {
            if (careerLower.contains('manager') ||
                careerLower.contains('lead') ||
                careerLower.contains('director')) {
              return "Generate HR questions for management roles, focusing on leadership style, team motivation, performance management, and organizational development.";
            } else if (careerLower.contains('sales') ||
                careerLower.contains('business development')) {
              return "Generate HR questions for sales roles, focusing on customer relationship building, resilience, goal orientation, and communication skills.";
            } else if (careerLower.contains('creative') ||
                careerLower.contains('designer') ||
                careerLower.contains('artist')) {
              return "Generate HR questions for creative roles, focusing on innovation, collaboration, feedback reception, and creative problem-solving.";
            } else if (careerLower.contains('technical') ||
                careerLower.contains('engineer') ||
                careerLower.contains('developer')) {
              return "Generate HR questions for technical roles, focusing on continuous learning, collaboration, problem-solving approach, and adaptability.";
            } else {
              return "Generate HR questions for $career roles, focusing on relevant soft skills, work ethic, and cultural fit for this profession.";
            }
          } else if (interviewType == 'hiring_manager') {
            if (careerLower.contains('manager') ||
                careerLower.contains('lead') ||
                careerLower.contains('director')) {
              return "Generate hiring manager questions for leadership roles, focusing on strategic vision, team building, business impact, and organizational growth.";
            } else if (careerLower.contains('technical') ||
                careerLower.contains('engineer')) {
              return "Generate hiring manager questions for technical roles, focusing on technical leadership, innovation, project delivery, and team mentorship.";
            } else if (careerLower.contains('sales') ||
                careerLower.contains('business development')) {
              return "Generate hiring manager questions for revenue-generating roles, focusing on business development, client relationships, and revenue growth strategies.";
            } else {
              return "Generate hiring manager questions for $career roles, focusing on business impact, strategic thinking, and long-term organizational contribution.";
            }
          }
          return "Generate questions relevant to $career in the context of $interviewType interviews.";
        }

        // Build the list of previously generated questions to avoid duplicates
        String previousQuestionsText = "";
        if (_generatedQuestions.isNotEmpty) {
          previousQuestionsText =
              "\n\nIMPORTANT: DO NOT generate questions similar to these previously asked questions:\n";
          for (int i = 0; i < _generatedQuestions.length; i++) {
            previousQuestionsText += "${i + 1}. ${_generatedQuestions[i]}\n";
          }
          previousQuestionsText +=
              "\nEnsure the new question is completely different in topic, approach, and difficulty level.";
        }

        switch (widget.interviewType) {
          case 'technical':
            String careerSpecificTech =
                getCareerSpecificPrompt(career, 'technical');
            systemString =
                "You are an experienced technical interviewer conducting a professional job interview. Generate a unique, challenging technical question that demonstrates deep understanding of the field. $careerSpecificTech Make it comprehensive and challenging for experienced professionals. For software-related careers, focus on data structures, algorithms (LeetCode medium to hard level), system design, and practical coding problems. Frame the question professionally as an interviewer would ask it, with proper context and clear expectations.$previousQuestionsText";
            userString =
                "Interview Type: Technical, Career: $career, Data: ${jsonEncode(ans.toJson())}, Question Number: $questionNumber. As a professional interviewer, ask a question that tests domain-specific technical depth, problem-solving skills, and practical knowledge relevant to $career. Make it sound natural and professional.";
            break;
          case 'hr':
            String careerSpecificHR = getCareerSpecificPrompt(career, 'hr');
            systemString =
                "You are a professional HR interviewer assessing candidate fit for the role. Generate a behavioral question that reveals the candidate's personality, work ethic, communication skills, and cultural fit for $career roles. $careerSpecificHR Frame the question professionally and focus on scenarios that demonstrate relevant soft skills and professional behavior.$previousQuestionsText";
            userString =
                "Interview Type: HR, Career: $career, Data: ${jsonEncode(ans.toJson())}, Question Number: $questionNumber. Ask a professional behavioral question that assesses soft skills, behavioral competencies, and professional development relevant to $career roles.";
            break;
          case 'hiring_manager':
            String careerSpecificHM =
                getCareerSpecificPrompt(career, 'hiring_manager');
            systemString =
                "You are a senior hiring manager evaluating candidates for strategic fit within the organization. Generate a question that assesses leadership potential, business acumen, strategic thinking, and long-term organizational contribution for $career roles. $careerSpecificHM Frame the question to reveal how the candidate thinks about business impact and team dynamics.$previousQuestionsText";
            userString =
                "Interview Type: Hiring Manager, Career: $career, Data: ${jsonEncode(ans.toJson())}, Question Number: $questionNumber. Ask a strategic question that evaluates leadership, business impact, and long-term organizational fit relevant to $career roles.";
            break;
          default:
            systemString =
                "You are a professional interviewer conducting a job interview. Generate an insightful, thought-provoking question for the $career job domain that demonstrates deep understanding of the field.$previousQuestionsText";
            userString =
                "Career: $career, Data: ${jsonEncode(ans.toJson())}, Question Number: $questionNumber. Ask a professional question that tests relevant knowledge and skills for this career.";
        }

        final payload = jsonEncode({
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
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_NONE'
            },
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
        });

        debugPrint("Question Generation Payload: $payload");

        final response = await http.post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );

        debugPrint("Response status code: ${response.statusCode}");
        debugPrint("Response body: ${response.body}");

        if (response.statusCode == 200) {
          final jsonResp = jsonDecode(response.body);
          final text = jsonResp['candidates']?[0]?['content']?['parts']?[0]
              ?['text'] as String?;
          debugPrint('Gemini raw text: $text');
          if (text != null && text.isNotEmpty) {
            return text;
          } else {
            throw Exception("Empty response from Gemini API");
          }
        } else {
          debugPrint('Error response: ${response.body}');
          // Try to provide more specific error information
          String errorMessage = "Failed to generate question from Gemini API";
          try {
            final errorJson = jsonDecode(response.body);
            if (errorJson['error'] != null) {
              errorMessage += ": ${errorJson['error']['message']}";
            }
          } catch (e) {
            // If we can't parse the error, just use the status code
            errorMessage += ": Status ${response.statusCode}";
          }
          throw Exception(errorMessage);
        }
      } catch (e) {
        retryCount++;
        debugPrint("Attempt $retryCount failed: $e");

        if (retryCount >= maxRetries) {
          debugPrint("All retry attempts failed");
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(Duration(seconds: retryCount));
      }
    }

    // This should never be reached, but added for safety
    throw Exception("Failed to generate question after all retries");
  }

  /// Simulate typewriter effect to display the question letter by letter.
  void _displayQuestionWithTypingEffect(String fullText) {
    setState(() {
      _currentQuestion = "";
      _currentQuestionStartTime =
          DateTime.now(); // Track when question was displayed
    });
    int index = 0;
    Timer.periodic(const Duration(milliseconds: 50), (Timer timer) {
      if (index < fullText.length) {
        setState(() {
          _currentQuestion += fullText[index];
        });
        index++;
      } else {
        timer.cancel();
        // Once fully displayed, speak out the question.
        _speak(_currentQuestion);
        // Check if IDE should be shown for this question
      }
    });
  }

  /// Check if IDE should be shown based on interview type and career
  void _checkIfIDEShouldBeShown() {
    final career = widget.career.toLowerCase().trim();
    final interviewType = widget.interviewType.toLowerCase();

    debugPrint(
        "DEBUG: Checking IDE visibility for career: '$career', interview type: '$interviewType'");

    // HR interviews don't need IDE
    if (interviewType == 'hr') {
      setState(() {
        _showIDE = false;
        debugPrint("DEBUG: IDE not shown - HR interview type");
      });
      return;
    }

    // For Technical and Hiring Manager interviews, check if career is software-related
    if (interviewType == 'technical' || interviewType == 'hiring_manager') {
      // Define software-related careers that should show IDE
      final softwareCareers = [
        'software engineer',
        'software developer',
        'programmer',
        'developer',
        'full stack developer',
        'frontend developer',
        'backend developer',
        'mobile developer',
        'ios developer',
        'android developer',
        'web developer',
        'data scientist',
        'machine learning engineer',
        'ai engineer',
        'computer scientist',
        'it specialist',
        'system administrator',
        'database administrator',
        'devops engineer',
        'cloud engineer',
        'cybersecurity specialist',
        'blockchain developer',
        'game developer',
        'embedded systems engineer',
        'computer engineer',
        'software architect',
        'technical lead',
        'engineering manager'
      ];

      // Check if the full career string contains any of the software-related keywords.
      final isSoftwareRelated =
          softwareCareers.any((swCareer) => career.contains(swCareer));

      debugPrint("DEBUG: Is software related: $isSoftwareRelated");

      setState(() {
        _showIDE = isSoftwareRelated;
        if (_showIDE) {
          _ideCode = _getInitialCodeForLanguage(_selectedLanguage);
          debugPrint("DEBUG: IDE code initialized: $_ideCode");
          debugPrint("DEBUG: IDE should be visible now - _showIDE set to true");
        } else {
          debugPrint("DEBUG: IDE not shown - career is not software-related");
        }
      });

      debugPrint("DEBUG: Final _showIDE value: $_showIDE");
    } else {
      // For any other interview types, don't show IDE
      setState(() {
        _showIDE = false;
        debugPrint("DEBUG: IDE not shown - unknown interview type");
      });
    }
  }

  /// Get initial code for the selected language
  String _getInitialCodeForLanguage(String languageName) {
    switch (languageName) {
      case 'JavaScript':
        return '// Write your JavaScript code here\nfunction solution() {\n    // Your code here\n    return;\n}';
      case 'Python':
        return '# Write your Python code here\ndef solution():\n    # Your code here\n    pass';
      case 'Java':
        return '// Write your Java code here\npublic class Solution {\n    public static void main(String[] args) {\n        // Your code here\n    }\n}';
      case 'C++':
        return '// Write your C++ code here\n#include <iostream>\nusing namespace std;\n\nint main() {\n    // Your code here\n    return 0;\n}';
      case 'C':
        return '// Write your C code here\n#include <stdio.h>\n\nint main() {\n    // Your code here\n    return 0;\n}';
      case 'C#':
        return '// Write your C# code here\nusing System;\n\nclass Program {\n    static void Main() {\n        // Your code here\n    }\n}';
      case 'PHP':
        return '<?php\n// Write your PHP code here\nfunction solution() {\n    // Your code here\n}\n?>';
      case 'Ruby':
        return '# Write your Ruby code here\ndef solution\n    # Your code here\nend';
      case 'Go':
        return '// Write your Go code here\npackage main\n\nimport "fmt"\n\nfunc main() {\n    // Your code here\n}';
      case 'Swift':
        return '// Write your Swift code here\nfunc solution() {\n    // Your code here\n}';
      default:
        return '// Write your code here';
    }
  }

  /// Get language definition for syntax highlighting
  dynamic _getLanguage(String languageName) {
    switch (languageName) {
      case 'JavaScript':
        return js_lang.javascript;
      case 'Python':
        return py_lang.python;
      case 'Java':
        return java_lang.java;
      case 'C++':
        return cpp_lang.cpp;
      default:
        return js_lang.javascript; // Default to JavaScript
    }
  }

  /// Build the IDE component - opens full IDE screen
  Widget _buildIDEComponent() {
    return Card(
      color: const Color(0xFF1F1F1F),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          // Create a coding question from the current interview question
          final codingQuestion = CodingQuestion(
            questionText: _currentQuestion,
            initialCode: _getInitialCodeForLanguage(_selectedLanguage),
            solution:
                'Solution approach will be provided here with step-by-step pseudo code logic.',
            category: 'interview',
            testCases: [], // No test cases for interview mode
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InterviewIDEScreen(
                question: codingQuestion,
                initialLanguage: _selectedLanguage,
                onCodeChanged: (code) {
                  setState(() {
                    _ideCode = code;
                  });
                },
                onSubmit: (code) {
                  setState(() {
                    _ideCode = code;
                  });
                  _evaluateAnswer();
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.code,
                    color: Color(0xFF5BC0EB),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Code Editor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF323232),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedLanguage,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F0F),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: const Center(
                  child: Text(
                    'Tap to open full IDE',
                    style: TextStyle(
                      color: Color(0xFFB0B0B0),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Note: Your code will be submitted along with your text answer for evaluation.',
                style: TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Convert given text to speech.
  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  /// Start voice recording using the speech_to_text module.
  void _startRecording() async {
    if (!_isSpeechAvailable) return;
    setState(() {
      _isRecording = true;
      _studentAnswer = '';
      _answerController.text = '';
    });
    debugPrint("Starting voice recording...");
    _speech.listen(
      onResult: (result) {
        setState(() {
          _studentAnswer = result.recognizedWords;
          _answerController.text = result.recognizedWords;
        });
        debugPrint("Speech recognition result: ${result.recognizedWords}");
      },
      listenMode: stt.ListenMode.confirmation,
    );
  }

  /// Stop recording and finalize speech recognition.
  void _stopRecording() async {
    if (!_isRecording) return;
    debugPrint("Stopping voice recording...");
    _speech.stop();
    setState(() {
      _isRecording = false;
    });
  }

  /// Evaluate the answer using the Gemini API.
  Future<void> _evaluateAnswer() async {
    if (_answerController.text.trim().isEmpty) return;
    setState(() {
      _isProcessing = true;
    });

    // Add a small delay to ensure all services are properly initialized
    await Future.delayed(const Duration(milliseconds: 500));

    // Prepare the answer content (text + code if IDE is shown)
    String fullAnswer = _answerController.text;
    if (_showIDE && _ideCode.trim().isNotEmpty) {
      fullAnswer +=
          "\n\n--- Code Solution ---\nLanguage: $_selectedLanguage\n\n${_ideCode.trim()}";
    }

    debugPrint("Evaluating answer: $fullAnswer");
    try {
      final result = await _evaluateAnswerWithGemini(fullAnswer);
      debugPrint("Evaluation result: $result");
      setState(() {
        _score = result["score"] ?? 0;
        _feedback = result["feedback"] ?? "No feedback provided.";
        _currentQuestionAnswered = true; // Mark question as answered
      });
      // Speak out the feedback.
      _speak(_feedback);
      // Save the answer evaluation to the Realtime Database.
      _saveInterviewRecord(
        question: _currentQuestion,
        answer: fullAnswer,
        score: _score,
        feedback: _feedback,
      );

      // Award points for completing the interview question
      await GamificationService().awardPointsWithPopup(
        context,
        FirebaseAuth.instance.currentUser?.uid ?? '',
        15, // Base points for completing an interview question
        'Interview Question Completed!',
      );

      // Award bonus points for high scores
      if (_score >= 8) {
        await GamificationService().awardPointsWithPopup(
          context,
          FirebaseAuth.instance.currentUser?.uid ?? '',
          10, // Bonus points for high score
          'Excellent Performance! High Score Bonus!',
        );
      }
    } catch (e) {
      debugPrint("Error evaluating answer: $e");
      setState(() {
        _feedback = "Error evaluating answer. Please try again.";
      });
    }
    setState(() {
      _isProcessing = false;
    });
  }

  /// Call Gemini API for answer evaluation.
  Future<Map<String, dynamic>> _evaluateAnswerWithGemini(String answer) async {
    // Load API key from asset.
    final apiKey = await rootBundle.loadString('assets/gemini.key');
    final endpoint =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?alt=json&key=$apiKey";

    // Create system instruction based on whether IDE is shown (software vs non-software)
    String systemInstruction;
    if (_showIDE) {
      systemInstruction =
          'You are an experienced technical interviewer providing professional feedback to a candidate. Evaluate their technical interview response as you would in a real interview setting. Consider: 1) Technical accuracy and depth of understanding 2) Code quality, efficiency, and best practices 3) Problem-solving approach and thought process 4) Communication clarity and completeness. Provide constructive, encouraging feedback that helps the candidate improve. Frame your response as a professional interviewer would - be supportive yet honest, highlight strengths, and suggest specific areas for improvement. Give a score from 0-10 based on overall performance.';
    } else {
      systemInstruction =
          'You are a professional interviewer providing constructive feedback on a candidate\'s response. Evaluate their answer as you would in a real job interview, considering: 1) Understanding and insight shown 2) Communication effectiveness and clarity 3) Relevance to the question asked 4) Overall suitability and potential. Provide encouraging, professional feedback that highlights strengths and suggests specific improvements. Frame your response as a supportive interviewer who wants to help the candidate succeed. Give a score from 0-10 reflecting their overall performance.';
    }

    // Create payload for evaluation.
    final payload = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': systemInstruction}
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  'Question: ${_currentQuestion}\n\nCandidate Answer: $answer\n\nPlease evaluate this answer and provide feedback with a score from 0-10.'
            }
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
        'temperature': 1.0,
        'topP': 0.8,
      },
    });

    debugPrint("Evaluation Payload: $payload");

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );

    debugPrint("Evaluation Response status code: ${response.statusCode}");
    debugPrint("Evaluation Response body: ${response.body}");

    if (response.statusCode == 200) {
      final jsonResp = jsonDecode(response.body);
      final text =
          jsonResp['candidates'][0]['content']['parts'][0]['text'] as String?;
      debugPrint('Evaluation raw text: $text');
      if (text != null) {
        try {
          // Try to parse as JSON first
          final parsed = jsonDecode(text);
          debugPrint("Parsed evaluation JSON: $parsed");
          return {
            "score": parsed["score"] ?? 0,
            "feedback": parsed["feedback"] ??
                "No detailed feedback provided. Please review your answer."
          };
        } catch (e) {
          debugPrint(
              "JSON parsing error: $e, returning plain text as feedback");
          // If not a valid JSON, extract score and feedback from text
          int extractedScore = 0;
          String extractedFeedback = text;

          // Try to extract score from text (look for patterns like "Score: 8" or "8/10")
          final scoreRegex =
              RegExp(r'(?:score|Score|SCORE)[\s:]*(\d+)', multiLine: true);
          final scoreMatch = scoreRegex.firstMatch(text);
          if (scoreMatch != null) {
            extractedScore = int.tryParse(scoreMatch.group(1) ?? '0') ?? 0;
          }

          return {
            "score": extractedScore,
            "feedback": extractedFeedback,
          };
        }
      } else {
        throw Exception("No content returned from evaluation.");
      }
    } else {
      debugPrint('Evaluation error response: ${response.body}');
      throw Exception(
          "Failed to evaluate answer from Gemini API: ${response.statusCode}");
    }
  }

  /// Save the current interview record to Firebase Realtime Database.
  /// If only a question is provided, it saves the question entry.
  /// If answer evaluation details are provided, it updates the existing record.
  Future<void> _saveInterviewRecord({
    String? question,
    String? answer,
    int? score,
    String? feedback,
  }) async {
    try {
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
      debugPrint("DEBUG: Current user ID: $userId");

      if (userId.isEmpty) {
        debugPrint("User not authenticated, cannot save interview record.");
        return;
      }

      final dataToSave = {
        'userId': userId,
        'career': widget.career,
        'jobTitle': widget.jobTitle ?? _extractJobTitle(widget.career),
        'questionNumber': _questionCount,
        'question': question ?? _currentQuestion,
        'answer': answer ?? _answerController.text,
        'score': score ?? 0,
        'feedback': feedback ?? '',
        'interviewType': widget.interviewType,
        'timestamp': DateTime.now().toIso8601String(),
        'interviewStartTime': _interviewStartTime?.toIso8601String(),
        'interviewEndTime': _interviewEndTime?.toIso8601String(),
        'questionDisplayTime': _currentQuestionStartTime?.toIso8601String(),
        'questionAnswerTime':
            answer != null ? DateTime.now().toIso8601String() : null,
      };

      debugPrint("DEBUG: Saving interview data: $dataToSave");

      // If we have a stored record key and this is an update (has answer), update the existing record
      if (_currentInterviewRecordKey != null && answer != null) {
        debugPrint(
            "DEBUG: Updating existing record with key: $_currentInterviewRecordKey");
        final existingRef = _database
            .child('interviewResponses')
            .child(_currentInterviewRecordKey!);
        await existingRef.update(dataToSave);
        debugPrint(
            "Interview record updated successfully with key: $_currentInterviewRecordKey");
      } else {
        // Create new record for initial question save
        final newRef = _database.child('interviewResponses').push();
        debugPrint("DEBUG: Generated Firebase key: ${newRef.key}");

        await newRef.set(dataToSave);
        debugPrint(
            "Interview record saved to Firebase successfully with key: ${newRef.key}");

        // Store the key for future updates
        _currentInterviewRecordKey = newRef.key;
        debugPrint(
            "DEBUG: Stored record key for updates: $_currentInterviewRecordKey");

        // Verify the data was saved by reading it back
        final snapshot = await newRef.get();
        if (snapshot.exists) {
          debugPrint(
              "DEBUG: Verification - Data exists in Firebase: ${snapshot.value}");
        } else {
          debugPrint(
              "DEBUG: Verification - Data NOT found in Firebase after save!");
        }
      }
    } catch (e) {
      debugPrint('Error saving interview record: $e');
      debugPrint('Error details: ${e.toString()}');
    }
  }

  /// Start the 1-hour timer for the interview.
  void _startTimer() {
    _interviewTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      } else {
        timer.cancel();
        _onTimerComplete();
      }
    });
  }

  /// Handle timer completion - show rating popup.
  void _onTimerComplete() async {
    _interviewEndTime = DateTime.now();
    setState(() {
      _isInterviewActive = false;
    });

    // Award points for completing the full interview
    await _awardInterviewCompletion();

    _showRatingDialog();
  }

  /// Award points for completing the full interview
  Future<void> _awardInterviewCompletion() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (userId.isEmpty) return;

      // Award points for completing the full interview
      await GamificationService().awardPointsWithPopup(
        context,
        userId,
        50, // 50 points for completing full interview
        'Full Interview Completed! 🎉',
      );

      // Update interview completion stats
      await GamificationService()
          .updateActivityStats(userId, 'interview_completion');

      // Update challenge progress for interview sessions
      await GamificationService()
          .updateChallengeProgress(userId, 'interviews_completed', 'weekly');
      await GamificationService()
          .updateChallengeProgress(userId, 'interviews_completed', 'monthly');

      // Award bonus points for high average score
      if (_questionCount > 0) {
        final averageScore = _score / _questionCount;
        if (averageScore >= 8.0) {
          await GamificationService().awardPointsWithPopup(
            context,
            userId,
            25, // Bonus for high performance
            'Outstanding Performance! High Score Bonus! 🌟',
          );
        }
      }

      debugPrint('Interview completion rewards awarded successfully');
    } catch (e) {
      debugPrint('Error awarding interview completion: $e');
    }
  }

  /// Handle manual end interview - show rating popup.
  void _onEndInterview() {
    _interviewTimer?.cancel();
    _interviewEndTime = DateTime.now();
    setState(() {
      _isInterviewActive = false;
    });
    _showRatingDialog();
  }

  /// Show rating dialog for feedback collection.
  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1F1F1F),
              title: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Rate your experience',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'How would you rate this interview?',
                    style: TextStyle(color: Color(0xFFD1D1D1), fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedRating = index + 1;
                          });
                        },
                        icon: Icon(
                          index < _selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: const Color(0xFFFFD700),
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _commentsController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Share your feedback (optional)',
                      hintStyle: const TextStyle(color: Color(0xFFD1D1D1)),
                      filled: true,
                      fillColor: const Color(0xFF323232),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _submitRating();
                  },
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Color(0xFF5BC0EB), fontSize: 16),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Submit rating and comments to Firebase, then navigate to results.
  void _submitRating() async {
    try {
      await _database.child('interviewRatings').push().set({
        'career': widget.career,
        'interviewType': widget.interviewType,
        'rating': _selectedRating,
        'comments': _commentsController.text,
        'timestamp': DateTime.now().toIso8601String(),
        'duration': _maxInterviewDurationMinutes - (_remainingTime.inMinutes),
      });
      debugPrint("Rating submitted to Firebase.");
    } catch (e) {
      debugPrint('Error submitting rating: $e');
    }

    Navigator.of(context).pop(); // Close dialog
    _navigateToResults();
  }

  /// Navigate to results page.
  void _navigateToResults() {
    // Navigate back to results page - you may need to adjust this based on your navigation structure
    Navigator.of(context)
        .pop(); // This will go back to the previous screen (likely results)
  }

  /// Open full-screen meeting view (similar to Google Meet) when the interviewer image is tapped.
  void _openFullScreenMeeting() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMeetingScreen(
          cameraController: _cameraController,
          initializeCameraFuture: _initializeCameraFuture,
        ),
      ),
    );
  }

  // A button style with border radius 10.
  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF5BC0EB),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final hours = twoDigits(duration.inHours);
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return '$hours:$minutes:$seconds';
    }

    return WillPopScope(
      onWillPop: () async => false, // Disable back gesture
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        appBar: AppBar(
          backgroundColor: const Color(0xFF101010),
          automaticallyImplyLeading: false, // Remove back button
          title: Row(
            children: [
              // Timer on the left
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer,
                      color: Color(0xFF5BC0EB),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatDuration(_remainingTime),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // App title in center
              Text(
                _t('appTitle'),
                style: const TextStyle(
                  fontSize: 18.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // End button on the right
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4444),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton.icon(
                  onPressed: _onEndInterview,
                  icon: const Icon(
                    Icons.stop,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'End',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Camera preview area with interviewer image.
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      border: Border.all(color: Colors.grey[800]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _initializeCameraFuture == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.videocam_off,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Camera not available',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Please check camera permissions and try again',
                                  style: TextStyle(
                                    color: Color(0xFFB0B0B0),
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    setState(() {
                                      _initializeCameraFuture =
                                          _initializeCamera();
                                    });
                                    await _initializeCameraFuture;
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry Camera'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5BC0EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : FutureBuilder(
                            future: _initializeCameraFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.done) {
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Camera initialization failed',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Error: ${snapshot.error.toString()}',
                                          style: const TextStyle(
                                            color: Color(0xFFB0B0B0),
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            setState(() {
                                              _initializeCameraFuture =
                                                  _initializeCamera();
                                            });
                                            await _initializeCameraFuture;
                                          },
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Retry Camera'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF5BC0EB),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return CameraPreview(_cameraController!);
                              } else {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SpinKitPouringHourGlassRefined(
                                        color: const Color(0xFF5BC0EB),
                                        size: 50,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Initializing camera...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                  ),
                  // Interviewer image as a rectangle positioned at the bottom right.
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _openFullScreenMeeting,
                      child: Container(
                        width: 100,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[800]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: AssetImage('assets/images/int.png'),
                            fit: BoxFit.cover,
                            onError: (error, stackTrace) {
                              debugPrint("Error loading asset: $error");
                            },
                          ),
                        ),
                        // Fallback if image asset fails to load.
                        child: Image.asset(
                          'assets/images/int.png',
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.white,
                            );
                          },
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Interview question display.
              Card(
                color: const Color(0xFF1F1F1F),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey[800]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _isProcessing
                      ? Center(
                          child: SpinKitPouringHourGlassRefined(
                            color: const Color(
                                0xFF5BC0EB), // Accent color for spinner
                            size: 100,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t('interviewQuestionTitle'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _currentQuestion,
                              style: const TextStyle(
                                color: Color(0xFFD1D1D1),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Voice input and editable answer box.
              Card(
                color: const Color(0xFF1F1F1F),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey[800]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('yourAnswerTitle'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Language dropdown for software jobs
                      if (_showIDE) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF323232),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[700]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedLanguage,
                              dropdownColor: const Color(0xFF323232),
                              style: const TextStyle(color: Colors.white),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Color(0xFF5BC0EB),
                              ),
                              items: [
                                'JavaScript',
                                'Python',
                                'Java',
                                'C++',
                                'C',
                                'C#',
                                'PHP',
                                'Ruby',
                                'Go',
                                'Swift'
                              ].map((String language) {
                                return DropdownMenuItem<String>(
                                  value: language,
                                  child: Row(
                                    children: [
                                      Icon(
                                        language == 'JavaScript'
                                            ? Icons.javascript
                                            : Icons.code,
                                        color: const Color(0xFF5BC0EB),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(language),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedLanguage = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Editable text field for the answer.
                      TextField(
                        controller: _answerController,
                        maxLines: null,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF323232),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[800]!),
                          ),
                          hintText: _showIDE
                              ? 'Type your answer here... (Code will be submitted separately)'
                              : 'Type your answer here...',
                          hintStyle: const TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isRecording
                                  ? _stopRecording
                                  : _startRecording,
                              style: _buttonStyle(),
                              icon: Icon(
                                _isRecording ? Icons.stop : Icons.mic,
                                color: Colors.white,
                              ),
                              label: Text(
                                _isRecording
                                    ? _t('stopRecording')
                                    : _t('startRecording'),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: (!_isRecording &&
                                    _answerController.text.isNotEmpty)
                                ? ElevatedButton(
                                    onPressed:
                                        _isProcessing ? null : _evaluateAnswer,
                                    style: _buttonStyle(),
                                    child: Text(
                                      _t('submitAnswer'),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                  )
                                : Container(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // IDE for software-related careers (shown below text field with spacing)
              if (_showIDE && !_isInterviewTimeOver)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: _buildIDEComponent(),
                ),

              const SizedBox(height: 20),
              // Feedback and score display.
              if (_feedback.isNotEmpty)
                Card(
                  color: const Color(0xFF1F1F1F),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey[800]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text(
                          _t('feedbackLabel'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _feedback,
                          style: const TextStyle(
                            color: Color(0xFFD1D1D1),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Next question button.
              if (!_isInterviewTimeOver)
                Center(
                  child: ElevatedButton(
                    onPressed: (_isProcessing || !_currentQuestionAnswered)
                        ? null
                        : _generateNextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentQuestionAnswered
                          ? const Color(0xFF5BC0EB)
                          : Colors.grey[600],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _t('nextQuestion'),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              if (_isInterviewTimeOver)
                Center(
                  child: Text(
                    _t('interviewCompleted'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coding Question class for interview IDE
class CodingQuestion {
  final String questionText;
  final dynamic initialCode;
  final String solution;
  final String category;
  final List<TestCase> testCases;

  CodingQuestion({
    required this.questionText,
    required this.initialCode,
    required this.solution,
    required this.category,
    required this.testCases,
  });
}

/// Test Case class
class TestCase {
  final String input;
  final String output;
  final bool hidden;

  TestCase({
    required this.input,
    required this.output,
    required this.hidden,
  });
}

/// Interview IDE Screen - Full IDE implementation from learn.dart
class InterviewIDEScreen extends StatefulWidget {
  final CodingQuestion question;
  final String initialLanguage;
  final Function(String) onCodeChanged;
  final Function(String) onSubmit;

  const InterviewIDEScreen({
    Key? key,
    required this.question,
    required this.initialLanguage,
    required this.onCodeChanged,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _InterviewIDEScreenState createState() => _InterviewIDEScreenState();
}

class LanguageOption {
  final String name;
  final String code;
  final String extension;

  const LanguageOption(this.name, this.code, this.extension);
}

class _InterviewIDEScreenState extends State<InterviewIDEScreen> {
  late CodeController _codeController;
  List<Map<String, dynamic>> _testResults = [];
  bool _isRunning = false;
  late LanguageOption _selectedLanguage;

  final List<LanguageOption> _allLanguages = [
    const LanguageOption('JavaScript', 'JAVASCRIPT', 'js'),
    const LanguageOption('Python', 'PYTHON', 'py'),
    const LanguageOption('Java', 'JAVA', 'java'),
    const LanguageOption('C++', 'CPP', 'cpp'),
    const LanguageOption('C', 'C', 'c'),
    const LanguageOption('C#', 'CSHARP', 'cs'),
    const LanguageOption('PHP', 'PHP', 'php'),
    const LanguageOption('Ruby', 'RUBY', 'rb'),
    const LanguageOption('Go', 'GO', 'go'),
    const LanguageOption('Swift', 'SWIFT', 'swift'),
  ];

  late List<LanguageOption> _languages;

  @override
  void initState() {
    super.initState();

    // Filter languages based on question category
    if (widget.question.category == 'Dev') {
      _languages =
          _allLanguages.where((lang) => lang.name == 'JavaScript').toList();
    } else {
      _languages = _allLanguages;
    }

    _selectedLanguage = _languages.firstWhere(
      (lang) => lang.name == widget.initialLanguage,
      orElse: () => _languages[0],
    );

    // Initialize CodeController with proper language and initial code
    _codeController = CodeController(
      text: _getInitialCodeForLanguage(_selectedLanguage.name),
      language: _getLanguage(_selectedLanguage.name),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Get language definition for syntax highlighting
  dynamic _getLanguage(String languageName) {
    switch (languageName) {
      case 'JavaScript':
        return js_lang.javascript;
      case 'Python':
        return py_lang.python;
      case 'Java':
        return java_lang.java;
      case 'C++':
        return cpp_lang.cpp;
      case 'C':
        return cpp_lang.cpp; // Use C++ syntax for C as fallback
      case 'C#':
        return js_lang.javascript; // Use JavaScript syntax for C# as fallback
      case 'PHP':
        return php_lang.php;
      case 'Ruby':
        return ruby_lang.ruby;
      case 'Go':
        return go_lang.go;
      case 'Swift':
        return swift_lang.swift;
      default:
        return js_lang.javascript; // Default to JavaScript
    }
  }

  // Get initial code for the selected language
  String _getInitialCodeForLanguage(String languageName) {
    // Handle different formats of initialCode
    if (widget.question.initialCode is String) {
      // Dev questions: initialCode is a string
      return widget.question.initialCode;
    } else if (widget.question.initialCode is Map) {
      // DSA questions: initialCode is an object with language keys
      final Map<String, dynamic> codeMap =
          widget.question.initialCode as Map<String, dynamic>;

      // Map language names to the keys used in JSON
      String languageKey;
      switch (languageName) {
        case 'JavaScript':
          languageKey = 'javascript';
          break;
        case 'Python':
          languageKey = 'python';
          break;
        case 'Java':
          languageKey = 'java';
          break;
        case 'C++':
          languageKey = 'cpp';
          break;
        case 'C#':
          languageKey = 'csharp';
          break;
        default:
          languageKey = 'javascript'; // Default fallback
      }

      // Return the language-specific code or fallback to JavaScript
      return codeMap[languageKey] ??
          codeMap['javascript'] ??
          '// No code template available';
    }

    // Fallback for unexpected formats
    return '// No code template available';
  }

  // Check if the current code is still the initial template
  bool _isInitialTemplate(String currentText, String? category) {
    if (category == 'Dev') {
      // For dev questions, check if it matches the JavaScript template
      return currentText.trim() ==
          widget.question.initialCode.toString().trim();
    } else {
      // For DSA questions, check if it matches any of the language templates
      if (widget.question.initialCode is Map) {
        final Map<String, dynamic> codeMap =
            widget.question.initialCode as Map<String, dynamic>;
        return codeMap.values.any(
            (template) => currentText.trim() == template.toString().trim());
      }
    }
    return false;
  }

  String _wrapDSACodeWithBoilerplate(String userCode, String inputData) {
    switch (_selectedLanguage.name) {
      case 'JavaScript':
        return _wrapJavaScriptDSA(userCode, inputData);
      case 'Python':
        return _wrapPythonDSA(userCode, inputData);
      case 'Java':
        return _wrapJavaDSA(userCode, inputData);
      case 'C++':
        return _wrapCppDSA(userCode, inputData);
      case 'C':
        return _wrapCDSA(userCode, inputData);
      case 'C#':
        return _wrapCSharpDSA(userCode, inputData);
      case 'PHP':
        return _wrapPhpDSA(userCode, inputData);
      case 'Ruby':
        return _wrapRubyDSA(userCode, inputData);
      case 'Go':
        return _wrapGoDSA(userCode, inputData);
      case 'Swift':
        return _wrapSwiftDSA(userCode, inputData);
      default:
        return userCode; // Fallback
    }
  }

  String _wrapJavaScriptDSA(String userCode, String inputData) {
    final functionMatch = RegExp(r'function\s+(\w+)\s*\(').firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      return '$userCode\n\nconsole.log(JSON.stringify($functionName($inputData)));';
    }
    return userCode;
  }

  String _wrapPythonDSA(String userCode, String inputData) {
    final functionMatch = RegExp(r'def\s+(\w+)\s*\(').firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      return '$userCode\n\nprint($functionName($inputData))';
    }
    return userCode;
  }

  String _wrapJavaDSA(String userCode, String inputData) {
    final functionMatch =
        RegExp(r'public\s+.*\s+(\w+)\s*\(').firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      final classMatch = RegExp(r'public\s+class\s+(\w+)').firstMatch(userCode);
      final className = classMatch?.group(1) ?? 'Solution';

      return '''
$userCode

public class Main {
    public static void main(String[] args) {
        $className solution = new $className();
        System.out.println(solution.$functionName($inputData));
    }
}
''';
    }
    return userCode;
  }

  String _wrapCppDSA(String userCode, String inputData) {
    final functionMatch = RegExp(r'\w+\s+(\w+)\s*\(').firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      return '''
#include <iostream>
using namespace std;

$userCode

int main() {
    cout << $functionName($inputData) << endl;
    return 0;
}
''';
    }
    return userCode;
  }

  String _wrapCDSA(String userCode, String inputData) {
    final functionMatch = RegExp(r'\w+\s+(\w+)\s*\(').firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      return '''
#include <stdio.h>

$userCode

int main() {
    printf("%d\\n", $functionName($inputData));
    return 0;
}
''';
    }
    return userCode;
  }

  String _wrapCSharpDSA(String userCode, String inputData) {
    final functionMatch =
        RegExp(r'(?:public\s+)?(?:static\s+)?\w+\s+(\w+)\s*\(')
            .firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      final classMatch =
          RegExp(r'(?:public\s+)?class\s+(\w+)').firstMatch(userCode);
      final className = classMatch?.group(1) ?? 'Solution';

      return '''
using System;

$userCode

public class Program {
    public static void Main(string[] args) {
        $className solution = new $className();
        Console.WriteLine(solution.$functionName($inputData));
    }
}
''';
    }
    return userCode;
  }

  String _wrapPhpDSA(String userCode, String inputData) {
    final functionMatch = RegExp(r'function\s+(\w+)\s*\(').firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      return '''
$userCode

echo $functionName($inputData);
''';
    }
    return userCode;
  }

  String _wrapRubyDSA(String userCode, String inputData) {
    final functionMatch = RegExp(r'def\s+(\w+)').firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      return '$userCode\n\nputs $functionName($inputData)';
    }
    return userCode;
  }

  String _wrapGoDSA(String userCode, String inputData) {
    final functionMatch = RegExp(r'func\s+(\w+)\s*\(').firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      return '''
package main

import "fmt"

$userCode

func main() {
    fmt.Println($functionName($inputData))
}
''';
    }
    return userCode;
  }

  String _wrapSwiftDSA(String userCode, String inputData) {
    final functionMatch = RegExp(r'func\s+(\w+)\s*\(').firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      return '$userCode\n\nprint($functionName($inputData))';
    }
    return userCode;
  }

  Future<Map<String, dynamic>> _runTestCase(TestCase testCase) async {
    try {
      // Prepare source code based on question type and language
      String sourceCode = _codeController.text;
      String inputData = testCase.input;

      // Handle different question types and languages
      if (widget.question.category == 'Dev') {
        // Dev questions are typically JavaScript functions that need to be called
        if (_selectedLanguage.name == 'JavaScript') {
          // For dev questions, the input contains the function call parameters
          // Parse the input to extract function name and arguments
          if (inputData.contains('\n')) {
            final lines = inputData.split('\n');
            if (lines.length >= 2) {
              final functionCall = lines[0].trim();
              final args = lines.sublist(1).join('\n');
              sourceCode += '\n\nconsole.log(JSON.stringify($functionCall));';
              inputData = args;
            }
          } else {
            // Simple function call
            sourceCode +=
                '\n\nconsole.log(JSON.stringify(${inputData.trim()}));';
            inputData = '';
          }
        }
      } else {
        // DSA questions - wrap the code with proper boilerplate
        sourceCode = _wrapDSACodeWithBoilerplate(sourceCode, inputData);
        inputData = ''; // Input is now embedded in the code
      }

      // Execute code using JDoodle service
      final jdoodleResult = await JDoodleService.executeCode(
        language: _selectedLanguage.code,
        script: sourceCode,
        stdin: inputData,
        timeout: const Duration(seconds: 30),
      );

      print('JDoodle Result: $jdoodleResult');

      if (jdoodleResult['status'] == 'success') {
        final output = jdoodleResult['output'] ?? '';
        final executionStatus = jdoodleResult['executionStatus'] ?? 'Accepted';
        final passed = output.trim() == testCase.output.trim();

        // Provide detailed error information based on execution status
        String actualOutput = output.trim();
        if (executionStatus != 'Accepted') {
          actualOutput =
              '${JDoodleService.mapStatusToDisplay(executionStatus)}: $actualOutput';
        } else if (actualOutput.isEmpty && !passed) {
          actualOutput = 'No output produced';
        }

        return {
          'input': testCase.input,
          'expected': testCase.output,
          'actual': actualOutput,
          'passed': passed,
          'hidden': testCase.hidden,
          'executionStatus': executionStatus,
          'memory': jdoodleResult['memory'],
          'cpuTime': jdoodleResult['cpuTime'],
        };
      } else {
        // Handle error cases
        final errorMessage = jdoodleResult['message'] ?? 'Unknown error';
        final executionStatus = jdoodleResult['executionStatus'] ?? 'RE';

        return {
          'input': testCase.input,
          'expected': testCase.output,
          'actual':
              '${JDoodleService.mapStatusToDisplay(executionStatus)}: $errorMessage',
          'passed': false,
          'hidden': testCase.hidden,
          'executionStatus': executionStatus,
          'error': errorMessage,
        };
      }
    } catch (e) {
      print('Error in _runTestCase: $e');
      return {
        'input': testCase.input,
        'expected': testCase.output,
        'actual': 'Execution failed: $e',
        'passed': false,
        'hidden': testCase.hidden,
        'executionStatus': 'RE',
        'error': e.toString(),
      };
    }
  }

  void _submitCode() async {
    setState(() {
      _isRunning = true;
      _testResults = [];
    });

    for (var testCase in widget.question.testCases) {
      final result = await _runTestCase(testCase);
      setState(() {
        _testResults.add(result);
      });
    }

    setState(() {
      _isRunning = false;
    });
  }

  Color _getSummaryColor() {
    if (_testResults.isEmpty) return Colors.grey;

    int passedCount =
        _testResults.where((result) => result['passed'] == true).length;
    double percentage = passedCount / _testResults.length;

    if (percentage == 1.0) return const Color(0xFF4CAF50); // Professional green
    if (percentage >= 0.5)
      return const Color(0xFFFF9800); // Professional orange
    return const Color(0xFFF44336); // Professional red
  }

  String _getSummaryText() {
    if (_testResults.isEmpty) return 'Ready to Test';

    int passedCount =
        _testResults.where((result) => result['passed'] == true).length;
    int totalCount = _testResults.length;

    if (passedCount == totalCount) {
      return 'All Tests Passed';
    } else if (passedCount > 0) {
      return 'Partial Success';
    } else {
      return 'Tests Failed';
    }
  }

  String _getSummaryDetails() {
    if (_testResults.isEmpty) return 'Run your code to see test results';

    int passedCount =
        _testResults.where((result) => result['passed'] == true).length;
    int totalCount = _testResults.length;
    double percentage = (passedCount / totalCount * 100);

    String details =
        '$passedCount of $totalCount tests passed (${percentage.toStringAsFixed(0)}%)';

    if (passedCount == totalCount) {
      details += '\n\nExcellent! Your solution is correct.';
    } else if (passedCount > 0) {
      details += '\n\nGood progress. Review the failed test cases.';
    } else {
      details += '\n\nCheck your code logic and try again.';
    }

    return details;
  }

  IconData _getSummaryIcon() {
    if (_testResults.isEmpty) return Icons.play_circle_outline;

    int passedCount =
        _testResults.where((result) => result['passed'] == true).length;
    int totalCount = _testResults.length;

    if (passedCount == totalCount) return Icons.check_circle;
    if (passedCount > 0) return Icons.warning;
    return Icons.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Interview Code Playground',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5BC0EB)),
          onPressed: () {
            widget.onCodeChanged(_codeController.text);
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Question Section - Improved layout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1F1F1F),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interview Question',
                    style: TextStyle(
                      color: Color(0xFF5BC0EB),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.question.questionText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content - All in single scroll view
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language Selector
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Language',
                          style: TextStyle(
                            color: Color(0xFF5BC0EB),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF323232),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<LanguageOption>(
                              value: _selectedLanguage,
                              dropdownColor: const Color(0xFF323232),
                              style: const TextStyle(color: Colors.white),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Color(0xFF5BC0EB),
                              ),
                              items: _languages.map((LanguageOption language) {
                                return DropdownMenuItem<LanguageOption>(
                                  value: language,
                                  child: Text(language.name),
                                );
                              }).toList(),
                              onChanged: (LanguageOption? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedLanguage = newValue;
                                    // Check if the current code is still the initial template
                                    String currentText = _codeController.text;
                                    String initialCode =
                                        _getInitialCodeForLanguage(
                                            _selectedLanguage.name);

                                    // If the current code is still the initial template or empty, update it
                                    // Otherwise, keep the user's code but change the language
                                    String newText = currentText;
                                    if (currentText.trim().isEmpty ||
                                        _isInitialTemplate(currentText,
                                            widget.question.category)) {
                                      newText = initialCode;
                                    }

                                    // Create new controller with updated language and text
                                    _codeController = CodeController(
                                      text: newText,
                                      language:
                                          _getLanguage(_selectedLanguage.name),
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Code Editor - Dynamic sizing
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 200,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF323232),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedLanguage.name == 'JavaScript'
                                    ? Icons.javascript
                                    : Icons.code,
                                color: const Color(0xFF5BC0EB),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Code Editor',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5BC0EB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _selectedLanguage.extension.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          constraints: BoxConstraints(
                            minHeight: 200,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: CodeTheme(
                            data: CodeThemeData(styles: monokaiSublimeTheme),
                            child: CodeField(
                              controller: _codeController,
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                              minLines: 10,
                              maxLines: null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Submit Button
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onSubmit(_codeController.text);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Submit Answer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5BC0EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-screen meeting view similar to Google Meet.
class FullScreenMeetingScreen extends StatelessWidget {
  final CameraController? cameraController;
  final Future<void>? initializeCameraFuture;

  const FullScreenMeetingScreen({
    Key? key,
    required this.cameraController,
    required this.initializeCameraFuture,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder(
        future: initializeCameraFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // Full-screen camera preview
                Positioned.fill(
                  child: CameraPreview(cameraController!),
                ),
                // Floating image similar to Google Meet's self-view on the bottom right
                Positioned(
                  bottom: 16.0,
                  right: 16.0,
                  child: Container(
                    width: 150, // Adjust width as needed
                    height: 200, // Adjust height as needed
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/int.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF5BC0EB),
              ),
            );
          }
        },
      ),
    );
  }
}
