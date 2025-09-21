import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'ide_screen.dart';
import 'coding_question.dart' show CodingQuestion, TestCase;
import 'coding_chatbot.dart';

class LecturePracticePage extends StatefulWidget {
  final String lectureTitle;
  final String courseName;

  const LecturePracticePage({
    Key? key,
    required this.lectureTitle,
    required this.courseName,
  }) : super(key: key);

  @override
  _LecturePracticePageState createState() => _LecturePracticePageState();
}

class _LecturePracticePageState extends State<LecturePracticePage> {
  List<Question> questions = [];
  List<CodingQuestion> codingQuestions = [];
  bool _isQuestionsLoading = false;
  String _selectedCategory = "Technical";
  TextEditingController _customQueryController = TextEditingController();
  int _selectedQuestionIndex = -1;

  // Define software-related courses that should show DSA and Dev categories
  // Using exact course titles from the course data
  final List<String> softwareCourses = [
    'Programming',
    'Python Programming',
    'JavaScript Basics',
    'Mobile App Development',
    'Data Structures',
    'Web Design',
    'Video Editing',
    'Advanced Photoshoop',
    'UI/UX Design',
    'Mathematics', // Data structures and algorithms covered
    'Physics Fundamentals', // Technical fundamentals
    'Mobile Graphic Design' // Digital tools/software
  ];

  @override
  void initState() {
    super.initState();
    _loadQuestionsForCategory(_selectedCategory);
  }

  bool _isSoftwareRelated() {
    final courseName = widget.courseName.toLowerCase();
    final lectureTitle = widget.lectureTitle.toLowerCase();
    return softwareCourses.any((keyword) =>
        courseName.contains(keyword) || lectureTitle.contains(keyword));
  }

  Future<void> _loadQuestionsForCategory(String category) async {
    setState(() {
      _isQuestionsLoading = true;
    });

    try {
      if (category == "DSA") {
        await _loadStaticDSAQuestions();
      } else if (category == "Dev") {
        await _loadStaticDevQuestions();
      } else if (category == "English") {
        await _loadEnglishQuestions();
      } else {
        // Load Technical, Aptitude questions
        await _generateDynamicQuestions(category);
      }
    } catch (e) {
      debugPrint("Error loading questions: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to load questions. Please try again. Error: $e')),
      );
    }

    setState(() {
      _isQuestionsLoading = false;
    });
  }

  Future<void> _loadStaticDSAQuestions() async {
    try {
      String jsonString =
          await rootBundle.loadString('assets/data/dsa_questions.json');
      final List<dynamic> questionsJson = jsonDecode(jsonString);
      final List<CodingQuestion> loadedQuestions =
          questionsJson.map((jsonItem) {
        return CodingQuestion(
          questionText: jsonItem['questionText'],
          initialCode: jsonItem['initialCode'] ?? {},
          solution: jsonItem['solution'] ??
              'Solution approach will be provided here.',
          category: 'DSA',
          testCases: jsonItem['testCases'] != null
              ? (jsonItem['testCases'] as List).map((tc) {
                  return TestCase(
                    input: tc['input'] ?? '',
                    output: tc['output'] ?? '',
                    hidden: tc['hidden'] ?? false,
                  );
                }).toList()
              : [],
        );
      }).toList();

      setState(() {
        codingQuestions = loadedQuestions;
        questions = []; // Clear multiple choice questions
        _isQuestionsLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading DSA questions: $e");
      // Fallback coding question
      setState(() {
        codingQuestions = [
          CodingQuestion(
            questionText: "Implement binary search algorithm for DSA practice.",
            initialCode: {
              "python":
                  "def binary_search(arr, target):\n    # Implement binary search\n    # Return the index of target or -1 if not found\n    pass",
              "java":
                  "public int binarySearch(int[] arr, int target) {\n    // Implement binary search\n    // Return the index of target or -1 if not found\n    return -1;\n}",
              "cpp":
                  "int binarySearch(vector<int>& arr, int target) {\n    // Implement binary search\n    // Return the index of target or -1 if not found\n    return -1;\n}",
            },
            solution:
                "Binary search implementation with logarithmic time complexity.",
            category: 'DSA',
            testCases: [
              TestCase(input: "[1,2,3,4,5,6] 4", output: "3", hidden: false),
              TestCase(input: "[1,2,3,4,5] 6", output: "-1", hidden: false),
            ],
          ),
        ];
        questions = []; // Clear multiple choice questions
        _isQuestionsLoading = false;
      });
    }
  }

  Future<void> _loadStaticDevQuestions() async {
    try {
      String jsonString =
          await rootBundle.loadString('assets/data/dev_questions.json');
      final List<dynamic> questionsJson = jsonDecode(jsonString);
      final List<CodingQuestion> loadedQuestions =
          questionsJson.map((jsonItem) {
        return CodingQuestion(
          questionText: jsonItem['questionText'],
          initialCode: jsonItem['initialCode'] ?? {},
          solution: jsonItem['solution'] ??
              'Solution approach will be provided here.',
          category: 'Dev',
          testCases: jsonItem['testCases'] != null
              ? (jsonItem['testCases'] as List).map((tc) {
                  return TestCase(
                    input: tc['input'] ?? '',
                    output: tc['output'] ?? '',
                    hidden: tc['hidden'] ?? false,
                  );
                }).toList()
              : [],
        );
      }).toList();

      setState(() {
        codingQuestions = loadedQuestions;
        questions = []; // Clear multiple choice questions
        _isQuestionsLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading Dev questions: $e");
      // Fallback coding question
      setState(() {
        codingQuestions = [
          CodingQuestion(
            questionText:
                "Create a simple function to validate an email address in Dev practice.",
            initialCode: {
              "python":
                  "import re\n\ndef is_valid_email(email):\n    # Implement email validation\n    # Return True if valid, False otherwise\n    pass",
              "java":
                  "public boolean isValidEmail(String email) {\n    // Implement email validation\n    // Return true if valid, false otherwise\n    return false;\n}",
              "cpp":
                  "#include <string>\n#include <regex>\n\nbool isValidEmail(const std::string& email) {\n    // Implement email validation\n    // Return true if valid, false otherwise\n    return false;\n}",
            },
            solution: "Use regex pattern to validate email format.",
            category: 'Dev',
            testCases: [
              TestCase(
                  input: "test@example.com", output: "true", hidden: false),
              TestCase(input: "invalid-email", output: "false", hidden: false),
            ],
          ),
        ];
        questions = []; // Clear multiple choice questions
        _isQuestionsLoading = false;
      });
    }
  }

  Future<void> _loadEnglishQuestions() async {
    try {
      String jsonString =
          await rootBundle.loadString('assets/data/english_questions.json');
      final List<dynamic> questionsJson = jsonDecode(jsonString);
      final List<Question> loadedQuestions = questionsJson.map((jsonItem) {
        return Question(
          questionText: jsonItem['questionText'],
          options: List<String>.from(jsonItem['options']),
          correctOptionIndex: jsonItem['correctAnswer'],
        );
      }).toList();

      setState(() {
        questions = loadedQuestions;
      });
    } catch (e) {
      debugPrint("Error loading English questions: $e");
      setState(() {
        questions = [
          Question(
            questionText: "Choose the correct spelling:",
            options: ["Recieve", "Receive", "Recive", "Receeve"],
            correctOptionIndex: 1,
          ),
        ];
      });
    }
  }

  Future<void> _generateDynamicQuestions(String category,
      {String? customQuery}) async {
    setState(() {
      _isQuestionsLoading = true;
    });

    try {
      // Try to load from Firebase first for caching
      final questionsFromDB =
          await _tryLoadQuestionsFromDB(category, customQuery);
      if (questionsFromDB != null) {
        setState(() {
          questions = questionsFromDB;
          _isQuestionsLoading = false;
        });
        return;
      }

      // Generate fresh questions using Gemini API
      final questionsFromGemini =
          await _fetchQuestionsFromGemini(category, customQuery);
      await _saveQuestionsToDB(category, questionsFromGemini, customQuery);

      setState(() {
        questions = questionsFromGemini;
        _isQuestionsLoading = false;
      });
    } catch (e) {
      debugPrint("Error generating dynamic questions: $e");

      // Fallback questions
      List<Question> fallbackQuestions = [];
      if (category == "Technical") {
        fallbackQuestions = [
          Question(
            questionText:
                "What is the primary purpose of a function in programming?",
            options: [
              "To store data",
              "To perform specific tasks",
              "To display text",
              "To connect to databases"
            ],
            correctOptionIndex: 1,
          ),
          Question(
            questionText: "Which of these is a programming paradigm?",
            options: ["Object-Oriented", "Waterfall", "Agile", "Scrum"],
            correctOptionIndex: 0,
          ),
        ];
      } else if (category == "Aptitude") {
        fallbackQuestions = [
          Question(
            questionText: "If 2x + 3 = 7, what is x?",
            options: ["1", "2", "3", "4"],
            correctOptionIndex: 1,
          ),
          Question(
            questionText: "What comes next: 2, 4, 8, 16, __?",
            options: ["20", "24", "32", "18"],
            correctOptionIndex: 2,
          ),
        ];
      }

      setState(() {
        questions = fallbackQuestions;
        _isQuestionsLoading = false;
      });
    }
  }

  Future<List<Question>?> _tryLoadQuestionsFromDB(
      String category, String? customQuery) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final String queryKey = customQuery ?? 'default';
      final dbRef = FirebaseDatabase.instance
          .ref()
          .child('lecture_practice')
          .child(userId)
          .child('${widget.courseName}_${widget.lectureTitle}')
          .child(category)
          .child(queryKey);

      final snapshot = await dbRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        final questionsData = data['questions'] as List?;
        if (questionsData != null) {
          return questionsData.map((item) {
            return Question(
              questionText: item['questionText'] as String,
              options: List<String>.from(item['options'] as List),
              correctOptionIndex: item['correctOptionIndex'] as int,
            );
          }).toList();
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error loading questions from DB: $e");
      return null;
    }
  }

  Future<void> _saveQuestionsToDB(
      String category, List<Question> questions, String? customQuery) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final String queryKey = customQuery ?? 'default';
      final dbRef = FirebaseDatabase.instance
          .ref()
          .child('lecture_practice')
          .child(userId)
          .child('${widget.courseName}_${widget.lectureTitle}')
          .child(category)
          .child(queryKey);

      await dbRef.set({
        'questions': questions
            .map((q) => {
                  'questionText': q.questionText,
                  'options': q.options,
                  'correctOptionIndex': q.correctOptionIndex,
                })
            .toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint("Error saving questions to DB: $e");
    }
  }

  Future<List<Question>> _fetchQuestionsFromGemini(
      String category, String? customQuery) async {
    try {
      String systemPrompt = _getSystemPromptForCategory(category);
      String userPrompt = _getUserPromptForCategory(category, customQuery);

      String response = await _fetchResultFromGemini(
        systemString: systemPrompt,
        userString: userPrompt,
      );

      final questionsJson = _parseGeminiResponse(response);
      return questionsJson.map((item) {
        return Question(
          questionText: item['questionText'] as String,
          options: List<String>.from(item['options'] as List),
          correctOptionIndex: item['correctOptionIndex'] as int,
        );
      }).toList();
    } catch (e) {
      debugPrint("Error fetching from Gemini: $e");
      throw e;
    }
  }

  String _getSystemPromptForCategory(String category) {
    final lectureContext =
        "Course: ${widget.courseName}, Lecture: ${widget.lectureTitle}";

    switch (category) {
      case "Technical":
        return "Generate multiple choice technical questions related to $lectureContext. Each question must be returned as a valid JSON object with keys: 'questionText', 'options' (an array of four strings), and 'correctOptionIndex' (an integer between 0 and 3). Focus on technical concepts, programming, software development, and related topics.";

      case "Aptitude":
        return "Generate multiple choice aptitude questions related to $lectureContext. Each question must be returned as a valid JSON object with keys: 'questionText', 'options' (an array of four strings), and 'correctOptionIndex' (an integer between 0 and 3). Focus on logical reasoning, mathematics, problem-solving, and analytical skills.";

      case "English":
        return "Generate multiple choice English language questions related to $lectureContext. Each question must be returned as a valid JSON object with keys: 'questionText', 'options' (an array of four strings), and 'correctOptionIndex' (an integer between 0 and 3). Focus on grammar, vocabulary, reading comprehension, and language skills.";

      default:
        return "Generate multiple choice questions related to $lectureContext. Each question must be returned as a valid JSON object with keys: 'questionText', 'options' (an array of four strings), and 'correctOptionIndex' (an integer between 0 and 3).";
    }
  }

  String _getUserPromptForCategory(String category, String? customQuery) {
    if (customQuery != null && customQuery.isNotEmpty) {
      return "Generate 5 multiple choice questions specifically about '$customQuery' for the course '${widget.courseName}' and lecture '${widget.lectureTitle}'. Make questions challenging and relevant.";
    }

    final defaultCounts = {
      "Technical": 5,
      "Aptitude": 5,
      "English": 5,
    };

    final count = defaultCounts[category] ?? 5;
    return "Generate $count multiple choice $category questions related to course '${widget.courseName}' and lecture '${widget.lectureTitle}'. Make questions educational and relevant to the topic.";
  }

  List<dynamic> _parseGeminiResponse(String response) {
    try {
      // Clean the response
      String cleanResponse = response.trim();

      // Remove markdown code blocks if present
      if (cleanResponse.startsWith('```')) {
        final lines = cleanResponse.split('\n');
        if (lines.first.contains('json')) {
          lines.removeAt(0); // Remove opening ```
          if (lines.last.trim() == '```') {
            lines.removeLast(); // Remove closing ```
          }
        }
        cleanResponse = lines.join('\n').trim();
      }

      // Extract JSON array
      final startIndex = cleanResponse.indexOf('[');
      final endIndex = cleanResponse.lastIndexOf(']');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleanResponse = cleanResponse.substring(startIndex, endIndex + 1);
      }

      final parsed = jsonDecode(cleanResponse);

      if (parsed is List) {
        return parsed;
      } else {
        throw Exception("Expected JSON array, got: $parsed");
      }
    } catch (e) {
      debugPrint("Error parsing Gemini response: $e");
      // Return fallback question structure
      return [_getFallbackQuestion()];
    }
  }

  Map<String, dynamic> _getFallbackQuestion() {
    return {
      "questionText": "What is the capital of France?",
      "options": ["London", "Berlin", "Paris", "Madrid"],
      "correctOptionIndex": 2,
    };
  }

  Future<String> _fetchResultFromGemini({
    required String systemString,
    required String userString,
  }) async {
    try {
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
            'temperature': 0.7,
            'topP': 0.8,
            'maxOutputTokens': 2048,
          },
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String text = jsonResponse['candidates'][0]['content']['parts'][0]
            ['text'] as String;
        return text;
      } else {
        throw Exception(
            'Failed to fetch Gemini result: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Gemini API error: $e');
      throw e;
    }
  }

  @override
  void dispose() {
    _customQueryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              "Practice Quiz",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.lectureTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Category selector
          _buildCategorySelector(),

          // Questions list
          Expanded(
            child: _isQuestionsLoading
                ? const Center(
                    child: SpinKitPouringHourGlassRefined(
                      color: Color(0xFF5BC0EB),
                      size: 120,
                    ),
                  )
                : questions.isNotEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          return _buildQuestionCard(questions[index], index);
                        },
                      )
                    : codingQuestions.isNotEmpty
                        ? ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: codingQuestions.length,
                            itemBuilder: (context, index) {
                              return _buildCodingQuestionCard(
                                  codingQuestions[index], index);
                            },
                          )
                        : const Center(
                            child: Text(
                              "No questions available for this category",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
          ),

          // Generate More Questions button
          if (questions.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _generateMoreQuestions(),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Generate More Questions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5BC0EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          // Custom query input section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (questions.isNotEmpty) const Divider(color: Colors.grey),
                TextField(
                  controller: _customQueryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter specific topic or query...',
                    hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                    filled: true,
                    fillColor: const Color(0xFF1F1F1F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF5BC0EB)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide:
                          BorderSide(color: Color(0xFF5BC0EB), width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF5BC0EB)),
                      onPressed: () => _generateCustomQuestions(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: (questions.isNotEmpty || codingQuestions.isNotEmpty)
          ? FloatingActionButton(
              onPressed: () => _openAIChat(),
              backgroundColor: const Color(0xFF5BC0EB),
              child: const Icon(
                Icons.chat,
                color: Colors.white,
              ),
              tooltip: 'Ask AI Assistant',
            )
          : null,
    );
  }

  void _generateMoreQuestions() async {
    // Force generate fresh questions by bypassing DB cache
    setState(() {
      _isQuestionsLoading = true;
    });

    try {
      // Generate fresh questions using Gemini API, skipping DB check
      final questionsFromGemini =
          await _fetchQuestionsFromGemini(_selectedCategory, null);
      await _saveQuestionsToDB(_selectedCategory, questionsFromGemini, null);

      setState(() {
        questions = questionsFromGemini;
        _isQuestionsLoading = false;
      });
    } catch (e) {
      debugPrint("Error generating fresh questions: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate questions. Error: $e')),
      );
      setState(() {
        _isQuestionsLoading = false;
      });
    }
  }

  void _generateCustomQuestions() async {
    final customQuery = _customQueryController.text.trim();
    if (customQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a custom query'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Force generate fresh custom questions by bypassing DB cache
    setState(() {
      _isQuestionsLoading = true;
    });

    try {
      // Generate fresh questions using Gemini API for the custom query, skipping DB check
      final questionsFromGemini =
          await _fetchQuestionsFromGemini(_selectedCategory, customQuery);
      await _saveQuestionsToDB(
          _selectedCategory, questionsFromGemini, customQuery);

      setState(() {
        questions = questionsFromGemini;
        _isQuestionsLoading = false;
      });
    } catch (e) {
      debugPrint("Error generating custom questions: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to generate custom questions. Error: $e')),
      );
      setState(() {
        _isQuestionsLoading = false;
      });
    }

    // Clear the text field after generation
    _customQueryController.clear();
  }

  Widget _buildCategorySelector() {
    List<String> categories = ['Technical', 'Aptitude', 'English'];

    if (_isSoftwareRelated()) {
      categories.addAll(['DSA', 'Dev']);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            final isSelected = _selectedCategory == category;
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                  _loadQuestionsForCategory(category);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? const Color(0xFF5BC0EB)
                      : const Color(0xFF323232),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCodingQuestionCard(CodingQuestion question, int questionIndex) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToIDE(question),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5BC0EB).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Q${questionIndex + 1}",
                  style: const TextStyle(
                    color: Color(0xFF5BC0EB),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  question.questionText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
              const Icon(
                Icons.code,
                color: Color(0xFF5BC0EB),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Question question, int questionIndex) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number and text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5BC0EB).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Q${questionIndex + 1}",
                    style: const TextStyle(
                      color: Color(0xFF5BC0EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.questionText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Options
            Column(
              children: List.generate(question.options.length, (optionIndex) {
                bool isSelected = question.selectedOptionIndex == optionIndex;
                bool isAnswered = question.answered;
                bool isCorrect =
                    isAnswered && question.correctOptionIndex == optionIndex;
                bool isWrongChoice = isAnswered && isSelected && !isCorrect;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: isAnswered
                        ? null
                        : () {
                            setState(() {
                              question.selectedOptionIndex = optionIndex;
                            });
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF5BC0EB).withOpacity(0.15)
                            : const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCorrect
                              ? Colors.green.withOpacity(0.6)
                              : isWrongChoice
                                  ? Colors.red.withOpacity(0.6)
                                  : isSelected
                                      ? const Color(0xFF5BC0EB).withOpacity(0.4)
                                      : Colors.transparent,
                          width: isCorrect || isWrongChoice ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? Colors.green.withOpacity(0.2)
                                  : isWrongChoice
                                      ? Colors.red.withOpacity(0.2)
                                      : isSelected
                                          ? const Color(0xFF5BC0EB)
                                              .withOpacity(0.2)
                                          : const Color(0xFF404040),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(
                                    65 + optionIndex), // A, B, C, D
                                style: TextStyle(
                                  color: isCorrect
                                      ? Colors.greenAccent
                                      : isWrongChoice
                                          ? Colors.redAccent
                                          : isSelected
                                              ? const Color(0xFF5BC0EB)
                                              : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              question.options[optionIndex],
                              style: TextStyle(
                                color: isCorrect
                                    ? Colors.greenAccent
                                    : isWrongChoice
                                        ? Colors.redAccent
                                        : isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                fontSize: 15,
                                fontWeight:
                                    isSelected || isCorrect || isWrongChoice
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isAnswered && isSelected)
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),

            // Action button
            if (question.answered || question.selectedOptionIndex != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: question.answered
                        ? Colors.green
                        : const Color(0xFF5BC0EB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (!question.answered) {
                      _checkAnswer(questionIndex);
                    } else {
                      _showCorrectAnswer(question);
                    }
                  },
                  child: Text(
                    question.answered ? 'Show Answer' : 'Check Answer',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _checkAnswer(int questionIndex) {
    final question = questions[questionIndex];
    if (question.selectedOptionIndex == null) return;

    bool isCorrect =
        question.selectedOptionIndex == question.correctOptionIndex;
    setState(() {
      question.answered = true;
    });

    if (isCorrect) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correct! Well done!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Incorrect. The correct answer is: ${question.options[question.correctOptionIndex]}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // You can integrate gamification here
    // _awardCoinsForCorrectAnswer();
  }

  void _openAIChat() {
    if (codingQuestions.isNotEmpty &&
        _selectedQuestionIndex >= 0 &&
        _selectedQuestionIndex < codingQuestions.length) {
      // For coding questions, use the existing CodingChatbot
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CodingChatbot(
            question: codingQuestions[_selectedQuestionIndex],
            userCode:
                '{"python": "", "java": "", "cpp": ""}', // Default empty code
            selectedLanguage: 'python', // Default language
            testResults: [],
          ),
        ),
      );
    } else if (questions.isNotEmpty &&
        _selectedQuestionIndex >= 0 &&
        _selectedQuestionIndex < questions.length) {
      // For multiple choice questions, create a general AI chat context
      final currentQuestion = questions[_selectedQuestionIndex];
      final questionContext = {
        'questionText': currentQuestion.questionText,
        'options': currentQuestion.options,
        'selectedOption': currentQuestion.selectedOptionIndex,
        'isAnswered': currentQuestion.answered,
        'correctAnswerIndex': currentQuestion.correctOptionIndex,
        'category': _selectedCategory,
        'courseName': widget.courseName,
        'lectureTitle': widget.lectureTitle,
      };

      // Create a dialogue screen for AI help with multiple choice questions
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: const Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: AIHelpDialog(
            questionContext: questionContext,
            category: _selectedCategory,
          ),
        ),
      );
    }
  }

  void _navigateToIDE(CodingQuestion question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IDEScreen(question: question),
      ),
    );
  }

  void _showCorrectAnswer(Question question) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F1F1F),
          title: const Text(
            'Correct Answer',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            question.options[question.correctOptionIndex],
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF5BC0EB)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class Question {
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  bool answered = false;
  int? selectedOptionIndex;

  Question({
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
  });
}

class AIHelpDialog extends StatefulWidget {
  final Map<String, dynamic> questionContext;
  final String category;

  const AIHelpDialog({
    Key? key,
    required this.questionContext,
    required this.category,
  }) : super(key: key);

  @override
  _AIHelpDialogState createState() => _AIHelpDialogState();
}

class _AIHelpDialogState extends State<AIHelpDialog> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add initial greeting
    _addInitialMessage();
  }

  void _addInitialMessage() {
    setState(() {
      _messages.add({
        'role': 'assistant',
        'content':
            'Hi! I\'m here to help you understand this ${widget.category} question better. Ask me anything about the question, the concepts involved, or why certain answers are correct/incorrect!',
        'timestamp': DateTime.now(),
      });
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add({
        'role': 'user',
        'content': userMessage,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
    });

    try {
      final response = await _getAIResponse(userMessage);
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response,
          'timestamp': DateTime.now(),
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              'Sorry, I couldn\'t generate a response right now. Please try again later.',
          'timestamp': DateTime.now(),
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getAIResponse(String userMessage) async {
    try {
      // Prepare context for AI
      String context = '''
Question Category: ${widget.category}
Question: ${widget.questionContext['questionText']}
Options: ${widget.questionContext['options'].join(', ')}
Selected Option: ${widget.questionContext['selectedOption'] != null ? 'Option ${String.fromCharCode(65 + (widget.questionContext['selectedOption'] as int))}' : 'None'}
Has Answered: ${widget.questionContext['isAnswered'] ? 'Yes' : 'No'}
Correct Answer: ${String.fromCharCode(65 + (widget.questionContext['correctAnswerIndex'] as int))}

User Question: $userMessage

Please provide a helpful response that helps the user understand the concept better. If the user has selected an answer, explain why it's correct or incorrect.
''';

      final apiKey = await rootBundle.loadString('assets/gemini.key');
      final endpoint =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?alt=json&key=$apiKey";

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': context}
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topP': 0.8,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['candidates'][0]['content']['parts'][0]['text'] ??
            'I couldn\'t generate a response. Please try again.';
      } else {
        return 'Sorry, I couldn\'t process your question right now.';
      }
    } catch (e) {
      debugPrint('AI Chat error: $e');
      return 'Sorry, I encountered an error. Please try again later.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
        maxWidth: MediaQuery.of(context).size.width * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF323232),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.smart_toy,
                  color: Color(0xFF5BC0EB),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI Study Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Messages
          Flexible(
            child: Container(
              color: const Color(0xFF1F1F1F),
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message['role'] == 'user';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser
                                ? const Color(0xFF5BC0EB)
                                : const Color(0xFF323232),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message['content'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF5BC0EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Thinking...',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1F1F1F),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ask me anything about this question...',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: const Color(0xFF323232),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF5BC0EB)),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
