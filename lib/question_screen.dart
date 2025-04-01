import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'result_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'question_data.dart';
import 'user_controller.dart';
import 'package:firebase_database/firebase_database.dart';

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
  Future<void> _initialize() async {
    if (UserController.user != null) {
      final dbRef = FirebaseDatabase.instance
          .ref()
          .child('surveyResponses')
          .child(UserController.user!.uid);
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
          ),
        ),
      );
    }

    // Build the survey UI.
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.all(2),
        child: Column(
          children: [
            const SizedBox(height: 14.5),
            LinearPercentIndicator(
              lineHeight: 37.0,
              percent: _step / _totSteps,
              center: Text(
                getProgressText(),
                style: const TextStyle(
                  fontSize: 17.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                onPressed: () => gotoStep(--_step),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                ),
                onPressed: () => gotoStep(++_step),
              ),
              barRadius: const Radius.circular(17.5),
              backgroundColor: const Color(0xFF5BC0EB).withOpacity(0.3),
              progressColor: const Color(0xFF5BC0EB),
              curve: Curves.easeInCirc,
              animateFromLastPercent: true,
            ),
            const Padding(padding: EdgeInsets.only(top: 20)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: min(560, screenSize.width * 0.9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
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
                                qns.titles[_index],
                                style: const TextStyle(
                                    fontSize: 24, color: Colors.white),
                                key: ValueKey(_index),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Image.asset('assets/images/andy.gif', width: 60)
                    ],
                  ),
                ),
                const Padding(padding: EdgeInsets.only(top: 30)),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, -0.5),
                            end: const Offset(0.0, 0.0),
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    key: ValueKey<int>(_step),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      width: min(560, screenSize.width * 0.9),
                      height: (kIsWeb ||
                              defaultTargetPlatform == TargetPlatform.macOS ||
                              defaultTargetPlatform == TargetPlatform.windows ||
                              defaultTargetPlatform == TargetPlatform.linux)
                          ? max(60, 0.9582 * screenSize.height - 410)
                          : screenSize.height * 0.4,
                      padding: const EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: screenSize.width < 560 ? 8.0 : 26.0,
                          runSpacing: screenSize.width < 560 ? 8.0 : 26.0,
                          children: List<Widget>.generate(
                            qns.options[_index].length,
                            (i) {
                              return Container(
                                decoration: ans.options[_index][i] == ''
                                    ? null
                                    : BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0xFF5BC0EB),
                                            spreadRadius: 2,
                                            blurRadius: 2,
                                          )
                                        ],
                                      ),
                                child: qns.options[_index][i] != "Other1"
                                    ? FilterChip(
                                        label: Text(
                                          qns.options[_index][i],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        selected: ans.options[_index][i] != '',
                                        onSelected: (s) => setState(() =>
                                            ans.options[_index][i] =
                                                ans.options[_index][i] == ''
                                                    ? qns.options[_index][i]
                                                    : ''),
                                        selectedColor: const Color(0xFF5BC0EB),
                                        backgroundColor: const Color(0xFF5BC0EB)
                                            .withOpacity(0.3),
                                      )
                                    : InputChip(
                                        label: const Text(
                                          'Other',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor:
                                            const Color(0xFF5BC0EB),
                                        onPressed: () async {
                                          String? newOption =
                                              await showDialog<String>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                title: const Text(
                                                  'Add a new option',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                content: TextFormField(
                                                  autofocus: true,
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                  onFieldSubmitted: (value) =>
                                                      Navigator.pop(
                                                          context, value),
                                                ),
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
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(vertical: 46, horizontal: 16),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (ans.options[_index].where((o) => o.isNotEmpty).toList().isEmpty)
              return;
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
              if (UserController.user != null) {
                final dbRef = FirebaseDatabase.instance
                    .ref()
                    .child('surveyResponses')
                    .child(UserController.user!.uid);
                dbRef.set({
                  'questions': qns.toJson(),
                  'answers': ans.toJson(),
                  'timestamp': DateTime.now().toIso8601String(),
                }).catchError((error) {
                  debugPrint("Error saving survey data: $error");
                });
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
            backgroundColor: const Color(0xFF5BC0EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            getSubmitText(),
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
