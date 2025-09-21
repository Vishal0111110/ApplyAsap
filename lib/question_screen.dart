import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'result_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'question_data.dart';

import 'package:firebase_database/firebase_database.dart';
import 'gamification_service.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  // Initialize variables
  int _index = 0, _step = 1;
  late int _totSteps = 10;
  late QuestionData qns, ans;
  bool _dataLoaded = false; // Flag to track if data is loaded
  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Function to load JSON data from a given path
  Future<QuestionData> loadJsonData(String path) async {
    String jsonString = await rootBundle.loadString(path);
    Map<String, dynamic> jsonData = jsonDecode(jsonString);
    return QuestionData.fromJson(jsonData);
  }

  // Helper function to return file path based on selected language
  String getLanguageFile(String lang) {
    switch (lang) {
      case "कश्मीरी":
        return "assets/data/questions_kashmiri.json";
      case "ਪੰਜਾਬੀ":
        return "assets/data/questions_punjabi.json";
      case "हरियाणवी":
        return "assets/data/questions_haryanvi.json";
      case "हिन्दी":
        return "assets/data/questions_hindi.json";
      case "राजस्थानी":
        return "assets/data/questions_rajasthani.json";
      case "भोजपुरी":
        return "assets/data/questions_bhojpuri.json";
      case "বাংলা":
        return "assets/data/questions_bengali.json";
      case "ગુજરાતી":
        return "assets/data/questions_gujarati.json";
      case "অসমীয়া":
        return "assets/data/questions_assamese.json";
      case "ଓଡ଼ିଆ":
        return "assets/data/questions_odia.json";
      case "मराठी":
        return "assets/data/questions_marathi.json";
      case "தமிழ்":
        return "assets/data/questions_tamil.json";
      case "తెలుగు":
        return "assets/data/questions_telugu.json";
      case "ಕನ್ನಡ":
        return "assets/data/questions_kannada.json";
      case "മലയാളം":
        return "assets/data/questions_malayalam.json";
      case "English":
      default:
        return "assets/data/questions_english.json";
    }
  }

  String getSubmitText() {
    if (_step == 1) return "Submit";
    String selectedLang = ans.options[0].firstWhere(
      (element) => element.isNotEmpty,
      orElse: () => "English",
    );
    switch (selectedLang) {
      case "कश्मीरी":
        return "جمع کرو";
      case "ਪੰਜਾਬੀ":
        return "ਸਬਮਿਟ ਕਰੋ";
      case "हरियाणवी":
        return "जमा करो";
      case "हिन्दी":
        return "जमा करें";
      case "राजस्थानी":
        return "जमा करो";
      case "भोजपुरी":
        return "जमा करीं";
      case "বাংলা":
        return "জমা দিন";
      case "ગુજરાતી":
        return "સબમિટ કરો";
      case "অসমীয়া":
        return "জমা কৰক";
      case "ଓଡ଼ିଆ":
        return "ଦାଖଲ କରନ୍ତୁ";
      case "मराठी":
        return "सबमिट करा";
      case "தமிழ்":
        return "சமர்ப்பிக்கவும்";
      case "తెలుగు":
        return "సమర్పించు";
      case "ಕನ್ನಡ":
        return "ಸಲ್ಲಿಸು";
      case "മലയാളം":
        return "സമർപ്പിക്കുക";
      case "English":
      default:
        return "Submit";
    }
  }

  String getProgressText() {
    if (_step == 1) {
      return "Step $_step out of $_totSteps";
    }
    String selectedLang = ans.options[0].firstWhere(
      (element) => element.isNotEmpty,
      orElse: () => "English",
    );
    switch (selectedLang) {
      case "कश्मीरी":
        return "مرحلو $_step مان $_totSteps";
      case "ਪੰਜਾਬੀ":
        return "ਕਦਮ $_step ਵਿੱਚੋਂ $_totSteps";
      case "हरियाणवी":
        return "चरण $_step में से $_totSteps";
      case "हिन्दी":
        return "चरण $_step में से $_totSteps";
      case "राजस्थानी":
        return "चरण $_step में से $_totSteps";
      case "भोजपुरी":
        return "चरण $_step में से $_totSteps";
      case "বাংলা":
        return "ধাপ $_step এর মধ্যে $_totSteps";
      case "ગુજરાતી":
        return "પગ $_step માંથી $_totSteps";
      case "অসমীয়া":
        return "পদক্ষেপ $_stepৰ ভিতৰত $_totSteps";
      case "ଓଡ଼ିଆ":
        return "ପଦକ୍ଷେପ $_step ମଧ୍ୟରୁ $_totSteps";
      case "मराठी":
        return "पाऊल $_step पैकी $_totSteps";
      case "தமிழ்":
        return "படி $_step இலிருந்து $_totSteps";
      case "తెలుగు":
        return "దశ $_step లోనుండి $_totSteps";
      case "ಕನ್ನಡ":
        return "ಪದক্ষেপ $_stepರಿಂದ $_totSteps";
      case "മലയാളം":
        return "പടി $_step ൽ നിന്ന് $_totSteps";
      case "English":
      default:
        return "Step $_step out of $_totSteps";
    }
  }

  void gotoStep(int i) {
    i = i <= 0 ? 1 : i;
    i = i > _totSteps ? _totSteps : i;
    setState(() {
      _step = i;
      _index = i - 1;
      // Reset the answer options display for the new question
      ans.titles[_index] = qns.titles[_index];
      ans.options[_index] = qns.options[_index].map((e) => '').toList();
    });
  }

  // New initialization function that checks Firebase first, then loads questions if no survey exists.
  /*
  Future<void> _initialize() async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId != null) {
      final dbRef = FirebaseDatabase.instance
          .ref()
          .child('surveyResponses')
          .child(currentUserId);
      final snapshot = await dbRef.get();
      if (snapshot.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ResultScreen(answers: QuestionData(titles: [], options: [])),
          ),
        );
        return;
      }
    }


    // Load questions from asset if no survey responses exist.
    qns = await loadJsonData('assets/data/questions.json');
    _totSteps = qns.titles.length;
    ans = QuestionData(
      titles: List.from(qns.titles),
      options: qns.options.map((o) => o.map((e) => '').toList()).toList(),
    );
    // Initialize the current question's answer options.
    ans.options[_index] = qns.options[_index].map((e) => '').toList();

    setState(() {
      _dataLoaded = true;
    });
  }s
*/
  Future<void> _initialize() async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      final dbRef = FirebaseDatabase.instance
          .ref()
          .child('surveyResponses')
          .child(currentUserId);
      final snapshot = await dbRef.get();
      if (snapshot.exists) {
        // The snapshot data is expected to be in the following format:
        // {
        //   "answers": "{\"Language Preference\":[\"తెలుగు\"], ... }",
        //   "questions": "{\"Language Preference\":[\"English\",\"హిందీ\",...]}",
        //   "timestamp": "2025-04-04T22:29:39.290792"
        // }
        Map data = snapshot.value as Map;

        // Decode the JSON strings stored for answers and questions.
        Map<String, dynamic> answersJson = jsonDecode(data['answers']);
        Map<String, dynamic> questionsJson = jsonDecode(data['questions']);

        // Create a QuestionData instance for the answers.
        // This example assumes that the keys of answersJson are the question titles,
        // and the values are lists (of responses). Adjust this mapping if needed.
        final surveyAnswers = QuestionData(
          titles: answersJson.keys.toList(),
          options: answersJson.values.map((value) {
            return value is List ? List<String>.from(value) : <String>[];
          }).toList(),
        );

        // Navigate directly to the result screen using the newly parsed data.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(answers: surveyAnswers),
          ),
        );
        return;
      }
    }

    // If no survey response exists, load questions from asset.
    qns = await loadJsonData('assets/data/questions.json');
    _totSteps = qns.titles.length;
    ans = QuestionData(
      titles: List.from(qns.titles),
      options: qns.options.map((o) => o.map((e) => '').toList()).toList(),
    );
    // Initialize the current question's answer options.
    ans.options[_index] = qns.options[_index].map((e) => '').toList();

    setState(() {
      _dataLoaded = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _initialize().catchError((error) {
      debugPrint("Error during initialization: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Show a loading screen until Firebase check and JSON loading are complete.
    if (!_dataLoaded) {
      return Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: Center(
          child: SpinKitPouringHourGlassRefined(
            color: const Color(0xFF5BC0EB),
            size: 120,
          ),
        ),
      );
    }

    // Build the survey UI with dark theme matching result screen
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Progress indicator with navigation buttons
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: _step > 1
                              ? const Color(0xFF5BC0EB)
                              : Colors.grey.shade600,
                          size: 20,
                        ),
                        onPressed: _step > 1 ? () => gotoStep(--_step) : null,
                      ),
                      Expanded(
                        child: LinearPercentIndicator(
                          lineHeight: 12.0,
                          percent: _step / _totSteps,
                          backgroundColor: Colors.grey.shade800,
                          progressColor: const Color(0xFF5BC0EB),
                          barRadius: const Radius.circular(6),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_forward,
                          color: _step < _totSteps
                              ? const Color(0xFF5BC0EB)
                              : Colors.grey.shade600,
                          size: 20,
                        ),
                        onPressed:
                            _step < _totSteps ? () => gotoStep(++_step) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    getProgressText(),
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Question display with dark theme
              Row(
                children: [
                  Expanded(
                    child: Text(
                      qns.titles[_index],
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset('assets/images/andy.gif', width: 80, height: 80),
                ],
              ),
              const SizedBox(height: 20),
              // Options container with dark theme card styling
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1F1F1F),
                        const Color(0xFF252525),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: const Color(0xFF5BC0EB).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List<Widget>.generate(
                        qns.options[_index].length,
                        (i) {
                          final isSelected = ans.options[_index][i] != '';
                          return qns.options[_index][i] != "Other1"
                              ? InkWell(
                                  onTap: () => setState(() =>
                                      ans.options[_index][i] =
                                          ans.options[_index][i] == ''
                                              ? qns.options[_index][i]
                                              : ''),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF5BC0EB)
                                          : const Color(0xFF323232),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF5BC0EB)
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                    child: Text(
                                      qns.options[_index][i],
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                              : InkWell(
                                  onTap: () async {
                                    String? newOption =
                                        await showDialog<String>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        String inputText = '';
                                        return AlertDialog(
                                          backgroundColor:
                                              const Color(0xFF1A1A1A),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          title: const Text(
                                            'Add Option',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          content: TextField(
                                            autofocus: true,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            onChanged: (value) =>
                                                inputText = value,
                                            decoration: const InputDecoration(
                                              hintText: 'Enter your option',
                                              hintStyle:
                                                  TextStyle(color: Colors.grey),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                    color: Colors.grey),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                  context, inputText),
                                              child: const Text(
                                                'Add',
                                                style: TextStyle(
                                                    color: Color(0xFF5BC0EB)),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (newOption != null &&
                                        newOption.isNotEmpty) {
                                      setState(() {
                                        qns.options[_index]
                                            .insert(i, newOption);
                                        ans.options[_index]
                                            .insert(i, newOption);
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF323232),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.grey.shade700),
                                    ),
                                    child: const Text(
                                      'Other',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Submit button with enhanced styling matching result screen
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF5BC0EB),
                      Color(0xFF4FC3F7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5BC0EB).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    if (ans.options[_index]
                        .where((o) => o.isNotEmpty)
                        .toList()
                        .isEmpty) return;
                    if (_step == 1) {
                      String selectedLang = ans.options[0].firstWhere(
                          (element) => element.isNotEmpty,
                          orElse: () => "English");
                      String filePath = getLanguageFile(selectedLang);
                      loadJsonData(filePath).then((translatedData) {
                        for (int i = 1; i < _totSteps; i++) {
                          qns.titles[i] = translatedData.titles[i - 1];
                          qns.options[i] = translatedData.options[i - 1];
                        }
                        gotoStep(++_step);
                      });
                    } else if (_step == _totSteps) {
                      if (currentUserId != null) {
                        final dbRef = FirebaseDatabase.instance
                            .ref()
                            .child('surveyResponses')
                            .child(currentUserId!);
                        dbRef.set({
                          'questions': qns.toJson(),
                          'answers': ans.toJson(),
                          'timestamp': DateTime.now().toIso8601String(),
                        }).catchError((error) {
                          debugPrint("Error saving survey data: $error");
                        });

                        // Check if this is the user's first survey by checking if they have survey responses
                        final surveyDbRef = FirebaseDatabase.instance
                            .ref()
                            .child('surveyResponses')
                            .child(currentUserId!);
                        final surveySnapshot = await surveyDbRef.get();
                        final isFirstSurvey = !surveySnapshot.exists;

                        // Award points based on whether it's first survey or not
                        final pointsToAward = isFirstSurvey
                            ? GamificationService.POINTS_FIRST_SURVEY
                            : GamificationService.POINTS_SURVEY_COMPLETION;

                        final reason = 'Completed career survey';

                        await GamificationService().awardPoints(
                          currentUserId!,
                          pointsToAward,
                          reason,
                          context: context,
                          showPopup: true,
                        );

                        // Update activity stats
                        await GamificationService()
                            .updateActivityStats(currentUserId!, 'survey');
                      }
                      debugPrint("Answers: ${ans.toJson()}");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultScreen(answers: ans),
                        ),
                      );
                    } else {
                      gotoStep(++_step);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    getSubmitText(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
