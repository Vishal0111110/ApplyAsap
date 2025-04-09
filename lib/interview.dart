import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'question_data.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
/// Returns the language index based on the given language string.
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

  const InterviewPage({
    Key? key,
    required this.career,
    required this.ans,
    required this.language,
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
  int _questionCount = 0;
  final int _maxInterviewDurationMinutes = 40;
  DateTime? _interviewStartTime;

  // Firebase Realtime Database instance.
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  late final int _langIndex;

  final Map<String, List<String>> _localizedStrings = {
    'appTitle': [
      "एआई इंटरव्यू",         // Kashmiri (Devanagari)
      "ਏਆਈ ਇੰਟਰਵਿਊ",       // Punjabi (Gurmukhi)
      "एआई इंटरव्यू",         // Haryanvi
      "एआई इंटरव्यू",         // Hindi
      "एआई इंटरव्यू",         // Rajasthani
      "एआई इंटरव्यू",         // Bhojpuri
      "এআই ইন্টারভিউ",        // Bengali
      "એઆઈ ઇન્ટરવ્યુ",        // Gujarati
      "এআই ইণ্টাৰভিউ",        // Assamese
      "ଏଆଇ ଇଣ୍ଟରଭ୍ୟୁ",       // Odia
      "एआय मुलाखत",         // Marathi
      "ஏ.ஐ. நேர்காணல்",       // Tamil
      "ఏఐ ఇంటర్వ్యూ",         // Telugu
      "ಎಐ ಸಂದರ್ಶನ",       // Kannada
      "എഐ അഭിമുഖം",        // Malayalam
      "AI Interview",         // English
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
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  /// Initialize the camera by selecting the front camera.
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
    _initializeCameraFuture = _cameraController!.initialize();
    debugPrint("Camera initialized with ${frontCamera.name}");
    setState(() {});
  }

  /// Start the interview session.
  void _startInterview() {
    _interviewStartTime = DateTime.now();
    debugPrint("Interview started at $_interviewStartTime");
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
    });
    _questionCount++;
    try {
      final question = await _generateQuestionWithGemini(
          widget.career, widget.ans, _questionCount);
      debugPrint("Generated question: $question");
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

  /// Call Gemini API for generating a question.
  Future<String> _generateQuestionWithGemini(
      String career, QuestionData ans, int questionNumber) async {
    // Load API key from asset.
    final apiKey = await rootBundle.loadString('assets/gemini.key');
    final endpoint =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?alt=json&key=$apiKey";

    // Create system and user instructions.
    final systemString =
        "Generate an extremely insightful, thought-provoking, analytical and tough question for the given job domain.";
    final userString =
        "Career: $career, Data: ${jsonEncode(ans.toJson())}, Question Number: $questionNumber";

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
      final text = jsonResp['candidates'][0]['content']['parts'][0]['text'] as String?;
      debugPrint('Gemini raw text: $text');
      return text ?? "Could not generate question.";
    } else {
      debugPrint('Error response: ${response.body}');
      throw Exception(
          "Failed to generate question from Gemini API: ${response.statusCode}");
    }
  }

  /// Simulate typewriter effect to display the question letter by letter.
  void _displayQuestionWithTypingEffect(String fullText) {
    setState(() {
      _currentQuestion = "";
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
      }
    });
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
    debugPrint("Evaluating answer: ${_answerController.text}");
    try {
      final result = await _evaluateAnswerWithGemini(_answerController.text);
      debugPrint("Evaluation result: $result");
      setState(() {
        _score = result["score"] ?? 0;
        _feedback = result["feedback"] ?? "No feedback provided.";
      });
      // Speak out the feedback.
      _speak(_feedback);
      // Save the answer evaluation to the Realtime Database.
      _saveInterviewRecord(
        question: _currentQuestion,
        answer: _answerController.text,
        score: _score,
        feedback: _feedback,
      );
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

    // Create payload for evaluation.
    final payload = jsonEncode({
      'system_instruction': {
        'parts': [
          {
            'text': 'Evaluate the answer thoroughly, providing a detailed feedback and score.'
          }
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': 'Answer: $answer'}
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
      final text = jsonResp['candidates'][0]['content']['parts'][0]['text'] as String?;
      debugPrint('Evaluation raw text: $text');
      if (text != null) {
        try {
          // Expecting a JSON string with score and feedback.
          final parsed = jsonDecode(text);
          debugPrint("Parsed evaluation JSON: $parsed");
          return {
            "score": parsed["score"] ?? 0,
            "feedback": parsed["feedback"] ??
                "No detailed feedback provided. Please review your answer."
          };
        } catch (e) {
          debugPrint("JSON parsing error: $e, returning plain text as feedback");
          // If not a valid JSON, return the entire text as feedback.
          return {
            "score": 0,
            "feedback": text,
          };
        }
      } else {
        throw Exception("No content returned from evaluation.");
      }
    } else {
      debugPrint('Evaluation error response: ${response.body}');
      throw Exception("Failed to evaluate answer from Gemini API: ${response.statusCode}");
    }
  }

  /// Save the current interview record to Firebase Realtime Database.
  /// If only a question is provided, it saves the question entry.
  /// If answer evaluation details are provided, it saves the complete record.
  Future<void> _saveInterviewRecord({
    String? question,
    String? answer,
    int? score,
    String? feedback,
  }) async {
    try {
      await _database.child('interviewResponses').push().set({
        'career': widget.career,
        'questionNumber': _questionCount,
        'question': question ?? _currentQuestion,
        'answer': answer ?? _answerController.text,
        'score': score ?? 0,
        'feedback': feedback ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      });
      debugPrint("Interview record saved to Firebase.");
    } catch (e) {
      debugPrint('Error saving interview record: $e');
    }
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
  /*Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        title: Text(
          _t('appTitle'),
          style: const TextStyle(color: Colors.white),
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
                    child: CircularProgressIndicator(
                      color: const Color(0xFF5BC0EB),
                    ),
                  )
                      : FutureBuilder(
                    future: _initializeCameraFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.done) {
                        return CameraPreview(_cameraController!);
                      } else {
                        return Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFF5BC0EB),
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
                  child: CircularProgressIndicator(
                    color: const Color(0xFF5BC0EB),
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
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isRecording ? _stopRecording : _startRecording,
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
                          child: (!_isRecording && _answerController.text.isNotEmpty)
                              ? ElevatedButton(
                            onPressed: _isProcessing ? null : _evaluateAnswer,
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
                      Text(
                        "${_t('scoreLabel')} $_score",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                  onPressed: _isProcessing ? null : _generateNextQuestion,
                  style: _buttonStyle(),
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
    );
  }*/
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        title: Text(
          _t('appTitle'),
          style: const TextStyle(
            fontSize: 20.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),

        ),
        centerTitle: true,
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
                    child: SpinKitPouringHourGlassRefined(
                      color: const Color(0xFF5BC0EB), // Accent color for spinner
                      size: 120,
                    ),
                  )
                      : FutureBuilder(
                    future: _initializeCameraFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.done) {
                        return CameraPreview(_cameraController!);
                      } else {
                        return Center(
                          child: SpinKitPouringHourGlassRefined(
                            color: const Color(0xFF5BC0EB), // Accent color for spinner
                            size: 120,
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
                    color: const Color(0xFF5BC0EB), // Accent color for spinner
                    size: 120,
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
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isRecording ? _stopRecording : _startRecording,
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
                          child: (!_isRecording && _answerController.text.isNotEmpty)
                              ? ElevatedButton(
                            onPressed: _isProcessing ? null : _evaluateAnswer,
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
                  onPressed: _isProcessing ? null : _generateNextQuestion,
                  style: _buttonStyle(),
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