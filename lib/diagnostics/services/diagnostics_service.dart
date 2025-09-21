import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_diagnostic_profile.dart';
import '../models/diagnostic_session.dart';

class DiagnosticsService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===========================================
  // USER CONSENT MANAGEMENT
  // ===========================================

  Future<bool> checkUserConsent(String userId) async {
    try {
      final ref = _database.ref('userDiagnosticProfiles').child(userId);
      final snapshot = await ref.get();

      if (!snapshot.exists) return false;

      final profile = UserDiagnosticProfile.fromMap(
          snapshot.value as Map<dynamic, dynamic>);
      return profile.privacyConsent && profile.dataSharingConsent;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateUserConsent(
      {required bool privacyConsent, required bool dataSharingConsent}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _database.ref('userDiagnosticProfiles').child(user.uid);

    final snapshot = await ref.get();
    if (!snapshot.exists) {
      // Create new profile
      final newProfile = UserDiagnosticProfile(
        userId: user.uid,
        traitScores: {},
        standardErrors: {},
        assessmentHistory: [],
        voiceFeatures: {},
        metadata: {},
        lastAssessment: DateTime.now(),
        privacyConsent: privacyConsent,
        dataSharingConsent: dataSharingConsent,
        consentDate: DateTime.now(),
      );

      await ref.set(newProfile.toMap());
    } else {
      // Update existing profile
      await ref.update({
        'privacyConsent': privacyConsent,
        'dataSharingConsent': dataSharingConsent,
        'consentDate': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // ===========================================
  // ASSESSMENT MANAGEMENT
  // ===========================================

  Future<Map<String, dynamic>> startAssessment(
      {required String userId,
      required String assessmentType,
      required Map<String, dynamic> metadata}) async {
    // Use Cloud Function to start assessment
    final sessionsRef = _database.ref('diagnosticSessions');
    final newSessionRef = sessionsRef.push();
    final sessionId = newSessionRef.key;

    if (sessionId != null) {
      final session = DiagnosticSession(
        sessionId: sessionId,
        userId: userId,
        assessmentType: assessmentType,
        startTime: DateTime.now(),
        metadata: metadata,
        status: SessionStatus.started,
        currentItemIndex: 0,
        itemIds: [], // Will be populated by Cloud Function
        endTime: null,
        results: null,
        thetaEstimate: null,
      );

      await newSessionRef.set(session.toMap());
    }

    return {'sessionId': sessionId};
  }

  Future<UserDiagnosticProfile?> getUserDiagnosticProfile(String userId) async {
    try {
      final ref = _database.ref('userDiagnosticProfiles').child(userId);
      final snapshot = await ref.get();

      if (!snapshot.exists) return null;

      final profile = UserDiagnosticProfile.fromMap(
          snapshot.value as Map<dynamic, dynamic>);
      return profile;
    } catch (e) {
      return null;
    }
  }

  Future<List<AssessmentResult>> getAssessmentHistory(String userId) async {
    try {
      final profile = await getUserDiagnosticProfile(userId);
      if (profile == null) return [];

      // Sort by completion date (most recent first)
      profile.assessmentHistory.sort((a, b) =>
          DateTime.parse(b.toMap()['completedAt'])
              .compareTo(DateTime.parse(a.toMap()['completedAt'])));

      return profile.assessmentHistory;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getAssessmentStats(String userId) async {
    try {
      final profile = await getUserDiagnosticProfile(userId);
      if (profile == null) return {};

      // Calculate statistics
      final recentAssessments = profile.assessmentHistory
          .where((assessment) => assessment.completedAt
              .isAfter(DateTime.now().subtract(const Duration(days: 30))))
          .toList();

      final catAssessments = recentAssessments
          .where((assessment) => assessment.assessmentType == 'cat')
          .length;

      final sjtAssessments = recentAssessments
          .where((assessment) => assessment.assessmentType == 'sjt')
          .length;

      final voiceAssessments = recentAssessments
          .where((assessment) => assessment.assessmentType == 'voice')
          .length;

      double avgScore = 0;
      if (recentAssessments.isNotEmpty) {
        avgScore =
            recentAssessments.map((a) => a.totalScore).reduce((a, b) => a + b) /
                recentAssessments.length;
      }

      return {
        'totalAssessments': profile.assessmentHistory.length,
        'recentAssessments': recentAssessments.length,
        'catAssessments': catAssessments,
        'sjtAssessments': sjtAssessments,
        'voiceAssessments': voiceAssessments,
        'averageScore': avgScore,
        'lastAssessment': profile.lastAssessment,
      };
    } catch (e) {
      return {};
    }
  }

  // ===========================================
  // SESSION DATA MANAGEMENT FOR PROFILE VIEW
  // ===========================================

  Future<List<Map<String, dynamic>>> getUserSessions(String userId) async {
    try {
      // Get all diagnostic sessions for the user
      final sessionsRef = _database.ref('diagnosticSessions');
      final snapshot = await sessionsRef.get();

      if (!snapshot.exists) return [];

      List<Map<String, dynamic>> userSessions = [];

      final sessions = snapshot.value as Map<dynamic, dynamic>;

      // Process each session synchronously
      for (var entry in sessions.entries) {
        final sessionId = entry.key;
        final session = entry.value as Map<dynamic, dynamic>;

        if (session['userId'] == userId && session['endTime'] != null) {
          // Only include completed sessions
          Map<String, dynamic> sessionInfo = {
            'sessionId': sessionId,
            'assessmentType': session['assessmentType'] ?? '',
            'completedAt':
                DateTime.fromMillisecondsSinceEpoch(session['endTime'] ?? 0),
            'metadata': session['metadata'] ?? {},
            'results': session['results'] ?? {},
            'generatedQuestions':
                Map<String, dynamic>.from(session['generatedQuestions'] ?? {}),
            'aiAnalysis':
                Map<String, dynamic>.from(session['aiAnalysis'] ?? {}),
          };

          // Add user responses
          await _addUserResponses(sessionId, sessionInfo);
          userSessions.add(sessionInfo);
        }
      }

      // Sort by completion date (most recent first)
      userSessions.sort((a, b) => (b['completedAt'] as DateTime)
          .compareTo(a['completedAt'] as DateTime));

      return userSessions;
    } catch (e) {
      print('Error fetching user sessions: $e');
      return [];
    }
  }

  Future<void> _addUserResponses(
      String sessionId, Map<String, dynamic> sessionInfo) async {
    try {
      // Try to get user responses if available
      final responsesRef =
          _database.ref('diagnosticResponses').child(sessionId);
      final responseSnapshot = await responsesRef.get();
      if (responseSnapshot.exists) {
        sessionInfo['userResponses'] = responseSnapshot.value;
      } else {
        sessionInfo['userResponses'] = {};
      }
    } catch (e) {
      print('Error fetching responses for session $sessionId: $e');
      sessionInfo['userResponses'] = {};
    }
  }

  Future<Map<String, dynamic>> _addUserResponsesToSession(
      String sessionId, Map<String, dynamic> sessionInfo) async {
    await _addUserResponses(sessionId, sessionInfo);
    return sessionInfo;
  }

  Future<Map<String, dynamic>> getSessionDetails(String sessionId) async {
    try {
      final sessionRef = _database.ref('diagnosticSessions').child(sessionId);
      final snapshot = await sessionRef.get();

      if (!snapshot.exists) return {};

      final sessionData = snapshot.value as Map<dynamic, dynamic>;

      // Get user responses
      Map<String, dynamic> responsesData = {};
      final responsesRef =
          _database.ref('diagnosticResponses').child(sessionId);
      final responseSnapshot = await responsesRef.get();
      if (responseSnapshot.exists) {
        responsesData =
            Map<String, dynamic>.from(responseSnapshot.value as Map);
      }

      return {
        'sessionId': sessionId,
        'assessmentType': sessionData['assessmentType'] ?? '',
        'startTime':
            DateTime.fromMillisecondsSinceEpoch(sessionData['startTime'] ?? 0),
        'endTime': sessionData['endTime'] != null
            ? DateTime.fromMillisecondsSinceEpoch(sessionData['endTime'])
            : null,
        'metadata': sessionData['metadata'] ?? {},
        'generatedQuestions':
            Map<String, dynamic>.from(sessionData['generatedQuestions'] ?? {}),
        'userResponses': responsesData,
        'aiAnalysis':
            Map<String, dynamic>.from(sessionData['aiAnalysis'] ?? {}),
        'results': sessionData['results'] ?? {},
      };
    } catch (e) {
      print('Error fetching session details: $e');
      return {};
    }
  }

  Future<void> storeUserResponses(String sessionId, String userId,
      List<Map<String, dynamic>> responses) async {
    try {
      final responsesRef =
          _database.ref('diagnosticResponses').child(sessionId);

      Map<String, dynamic> responsesData = {};
      for (var i = 0; i < responses.length; i++) {
        responsesData['response_$i'] = {
          'itemId': responses[i]['itemId'] ?? '',
          'userAnswer': responses[i]['userAnswer'] ?? '',
          'isCorrect': responses[i]['isCorrect'] ?? false,
          'responseTime': responses[i]['responseTime'] ?? 0,
          'question': responses[i]['question'] ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      await responsesRef.set(responsesData);
    } catch (e) {
      print('Error storing user responses: $e');
    }
  }

  // ===========================================
  // DYNAMIC QUESTION GENERATION WITH GEMINI
  // ===========================================

  Future<List<Map<String, dynamic>>> generateCATQuestions({
    required String userId,
    required String sessionId,
    int count = 20,
  }) async {
    try {
      // Check if questions already exist for this session
      final questionsRef = _database
          .ref('diagnosticSessions')
          .child(sessionId)
          .child('generatedQuestions')
          .child('cat');

      final snapshot = await questionsRef.get();
      if (snapshot.exists) {
        final questions = snapshot.value as List;
        return List<Map<String, dynamic>>.from(questions);
      }

      // Generate new questions using Gemini
      final apiKey = await rootBundle.loadString('assets/gemini.key');
      final endpoint =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?alt=json&key=$apiKey";

      final systemPrompt = """
You are an expert assessment question generator. Generate $count multiple-choice questions for a Cognitive Ability Test (CAT).

Each question must be:
- Challenging but fair
- Related to logical reasoning, problem-solving, or cognitive skills
- Have exactly 4 options (A, B, C, D)
- Have only one clearly correct answer
- Be original and not copied from standard tests

Return the response as a valid JSON array where each question has this exact structure:
{
  "question": "Question text here?",
  "options": ["Option A", "Option B", "Option C", "Option D"],
  "correctAnswer": 0,
  "category": "Logical Reasoning",
  "difficulty": "Medium"
}

Make sure the questions are diverse and cover different cognitive skills.
""";

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': 'Generate $count CAT questions for assessment'}
              ],
            },
          ],
          'system_instruction': {
            'parts': [
              {'text': systemPrompt}
            ],
          },
          'generationConfig': {
            'candidateCount': 1,
            'temperature': 0.7,
            'topP': 0.8,
            'maxOutputTokens': 4096
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        final text = jsonResp['candidates'][0]['content']['parts'][0]['text'];

        // Clean the response
        String cleanText = text.trim();
        if (cleanText.startsWith('```json')) {
          cleanText = cleanText.substring(7);
        }
        if (cleanText.endsWith('```')) {
          cleanText = cleanText.substring(0, cleanText.lastIndexOf('```'));
        }

        final questions = jsonDecode(cleanText) as List;
        final formattedQuestions = questions
            .map((q) => {
                  'question': q['question'],
                  'options': q['options'],
                  'correctAnswer': q['correctAnswer'],
                  'category': q['category'],
                  'difficulty': q['difficulty'],
                })
            .toList();

        // Store in Firebase
        await questionsRef.set(formattedQuestions);

        return formattedQuestions;
      } else {
        throw Exception('Failed to generate CAT questions: ${response.body}');
      }
    } catch (e) {
      print('Error generating CAT questions: $e');
      // Return fallback questions
      return _getFallbackCATQuestions(count);
    }
  }

  Future<List<Map<String, dynamic>>> generateSJTQuestions({
    required String userId,
    required String sessionId,
    int count = 20,
  }) async {
    try {
      // Check if questions already exist for this session
      final questionsRef = _database
          .ref('diagnosticSessions')
          .child(sessionId)
          .child('generatedQuestions')
          .child('sjt');

      final snapshot = await questionsRef.get();
      if (snapshot.exists) {
        final questions = snapshot.value as List;
        return List<Map<String, dynamic>>.from(questions);
      }

      // Generate new questions using Gemini
      final apiKey = await rootBundle.loadString('assets/gemini.key');
      final endpoint =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?alt=json&key=$apiKey";

      final systemPrompt = """
You are an expert in Situational Judgment Test (SJT) question generation. Generate $count realistic workplace scenarios for SJT assessment.

Each scenario must include:
1. A realistic workplace situation
2. A question asking to select BEST and WORST responses
3. Exactly 4 response options
4. A scoring matrix for evaluation

Return the response as a valid JSON array where each scenario has this exact structure:
{
  "scenario": "Detailed workplace scenario description...",
  "bestWorstQuestion": "Which response is the BEST and which is the WORST approach?",
  "responseOptions": ["Response A", "Response B", "Response C", "Response D"],
  "scoringMatrix": {"A_B": 3, "A_C": 1, "A_D": 0, "B_C": 2, "B_D": 1, "C_D": 2},
  "category": "Leadership",
  "difficulty": "Medium"
}

Make scenarios diverse and cover different workplace competencies like leadership, teamwork, communication, problem-solving, etc.
""";

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': 'Generate $count SJT scenarios for assessment'}
              ],
            },
          ],
          'system_instruction': {
            'parts': [
              {'text': systemPrompt}
            ],
          },
          'generationConfig': {
            'candidateCount': 1,
            'temperature': 0.7,
            'topP': 0.8,
            'maxOutputTokens': 4096
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        final text = jsonResp['candidates'][0]['content']['parts'][0]['text'];

        // Clean the response
        String cleanText = text.trim();
        if (cleanText.startsWith('```json')) {
          cleanText = cleanText.substring(7);
        }
        if (cleanText.endsWith('```')) {
          cleanText = cleanText.substring(0, cleanText.lastIndexOf('```'));
        }

        final questions = jsonDecode(cleanText) as List;
        final formattedQuestions = questions
            .map((q) => {
                  'scenario': q['scenario'],
                  'bestWorstQuestion': q['bestWorstQuestion'],
                  'responseOptions': q['responseOptions'],
                  'scoringMatrix': q['scoringMatrix'],
                  'category': q['category'],
                  'difficulty': q['difficulty'],
                })
            .toList();

        // Store in Firebase
        await questionsRef.set(formattedQuestions);

        return formattedQuestions;
      } else {
        throw Exception('Failed to generate SJT questions: ${response.body}');
      }
    } catch (e) {
      print('Error generating SJT questions: $e');
      // Return fallback questions
      return _getFallbackSJTQuestions(count);
    }
  }

  Future<List<Map<String, dynamic>>> generateVoicePrompts({
    required String userId,
    required String sessionId,
    int count = 5,
  }) async {
    try {
      // Check if prompts already exist for this session
      final promptsRef = _database
          .ref('diagnosticSessions')
          .child(sessionId)
          .child('generatedQuestions')
          .child('voice');

      final snapshot = await promptsRef.get();
      if (snapshot.exists) {
        final prompts = snapshot.value as List;
        return List<Map<String, dynamic>>.from(prompts);
      }

      // Generate new prompts using Gemini
      final apiKey = await rootBundle.loadString('assets/gemini.key');
      final endpoint =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?alt=json&key=$apiKey";

      final systemPrompt = """
You are an expert in voice assessment prompt generation. Generate $count reading prompts for voice analysis.

Each prompt must be:
- Appropriate for professional voice assessment
- 30-60 seconds reading time
- Cover different speaking styles and emotions
- Include various linguistic elements (questions, statements, complex sentences)

Return the response as a valid JSON array where each prompt has this exact structure:
{
  "prompt": "Text to be read aloud for voice assessment...",
  "category": "Professional Presentation",
  "difficulty": "Medium",
  "minDurationSeconds": 30,
  "maxDurationSeconds": 60,
  "targetFeatures": ["clarity", "pace", "pronunciation"]
}

Make prompts diverse and cover different communication scenarios.
""";

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': 'Generate $count voice assessment prompts'}
              ],
            },
          ],
          'system_instruction': {
            'parts': [
              {'text': systemPrompt}
            ],
          },
          'generationConfig': {
            'candidateCount': 1,
            'temperature': 0.7,
            'topP': 0.8,
            'maxOutputTokens': 2048
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        final text = jsonResp['candidates'][0]['content']['parts'][0]['text'];

        // Clean the response
        String cleanText = text.trim();
        if (cleanText.startsWith('```json')) {
          cleanText = cleanText.substring(7);
        }
        if (cleanText.endsWith('```')) {
          cleanText = cleanText.substring(0, cleanText.lastIndexOf('```'));
        }

        final prompts = jsonDecode(cleanText) as List;
        final formattedPrompts = prompts
            .map((p) => {
                  'prompt': p['prompt'],
                  'category': p['category'],
                  'difficulty': p['difficulty'],
                  'minDurationSeconds': p['minDurationSeconds'],
                  'maxDurationSeconds': p['maxDurationSeconds'],
                  'targetFeatures': p['targetFeatures'],
                })
            .toList();

        // Store in Firebase
        await promptsRef.set(formattedPrompts);

        return formattedPrompts;
      } else {
        throw Exception('Failed to generate voice prompts: ${response.body}');
      }
    } catch (e) {
      print('Error generating voice prompts: $e');
      // Return fallback prompts
      return _getFallbackVoicePrompts(count);
    }
  }

  // ===========================================
  // FALLBACK QUESTION GENERATORS
  // ===========================================

  List<Map<String, dynamic>> _getFallbackCATQuestions(int count) {
    return List.generate(count, (index) {
      return {
        'question':
            'What is the next number in the sequence: 2, 4, 8, 16, ...?',
        'options': ['24', '32', '30', '28'],
        'correctAnswer': 1,
        'category': 'Logical Reasoning',
        'difficulty': 'Medium',
      };
    });
  }

  List<Map<String, dynamic>> _getFallbackSJTQuestions(int count) {
    return List.generate(count, (index) {
      return {
        'scenario':
            'You are leading a team meeting and one team member keeps interrupting others...',
        'bestWorstQuestion':
            'Which response is the BEST and which is the WORST approach?',
        'responseOptions': [
          'Politely ask them to let others speak',
          'Ignore the interruption and continue',
          'Publicly criticize their behavior',
          'End the meeting early'
        ],
        'scoringMatrix': {
          'A_B': 3,
          'A_C': 0,
          'A_D': 1,
          'B_C': 1,
          'B_D': 2,
          'C_D': 0
        },
        'category': 'Leadership',
        'difficulty': 'Medium',
      };
    });
  }

  List<Map<String, dynamic>> _getFallbackVoicePrompts(int count) {
    return List.generate(count, (index) {
      return {
        'prompt':
            'Please read the following passage clearly and at a natural pace...',
        'category': 'Professional Reading',
        'difficulty': 'Medium',
        'minDurationSeconds': 30,
        'maxDurationSeconds': 60,
        'targetFeatures': ['clarity', 'pace', 'pronunciation'],
      };
    });
  }

  // ===========================================
  // AI-POWERED ASSESSMENT ANALYSIS
  // ===========================================

  Future<Map<String, dynamic>> analyzeCATResults({
    required String userId,
    required String sessionId,
    required List<Map<String, dynamic>> responses,
    required double thetaEstimate,
    required double reliability,
  }) async {
    try {
      String apiKey;
      try {
        apiKey = await rootBundle.loadString('assets/gemini.key');
      } catch (e) {
        print('Gemini API key not found, using mock analysis: $e');
        return _getFallbackCATAnalysis(responses, thetaEstimate, reliability);
      }
      final endpoint =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?alt=json&key=$apiKey";

      final systemPrompt = """
You are an expert career counselor and psychometric analyst. Analyze the following CAT (Cognitive Ability Test) results and provide comprehensive insights.

Assessment Data:
- Theta Estimate: ${thetaEstimate.toStringAsFixed(3)}
- Reliability: ${(reliability * 100).toStringAsFixed(1)}%
- Total Questions: ${responses.length}
- Correct Answers: ${responses.where((r) => r['isCorrect'] == true).length}
- Accuracy Rate: ${((responses.where((r) => r['isCorrect'] == true).length / responses.length) * 100).toStringAsFixed(1)}%

Provide a detailed analysis in the following JSON structure:
{
  "overallScore": 85,
  "scoreInterpretation": "Excellent cognitive ability with strong problem-solving skills",
  "cognitiveProfile": {
    "logicalReasoning": 88,
    "patternRecognition": 82,
    "quantitativeReasoning": 90,
    "verbalReasoning": 85
  },
  "strengths": ["Strong analytical thinking", "Excellent pattern recognition", "Quick problem solving"],
  "areasForImprovement": ["May benefit from more practice in abstract reasoning"],
  "careerImplications": ["Well-suited for technical roles", "Strong potential in data analysis", "Good fit for research positions"],
  "learningStyle": "Visual-logical learner with strong deductive reasoning",
  "recommendations": ["Consider advanced logic puzzles", "Practice with complex problem sets", "Explore data science fundamentals"],
  "detailedAnalysis": "Your performance indicates superior cognitive ability..."
}

Make the analysis personalized, actionable, and professional.
""";

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                      'Analyze CAT assessment results and provide detailed insights'
                }
              ],
            },
          ],
          'system_instruction': {
            'parts': [
              {'text': systemPrompt}
            ],
          },
          'generationConfig': {
            'candidateCount': 1,
            'temperature': 0.7,
            'topP': 0.8,
            'maxOutputTokens': 2048
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        final text = jsonResp['candidates'][0]['content']['parts'][0]['text'];

        // Clean the response
        String cleanText = text.trim();
        if (cleanText.startsWith('```json')) {
          cleanText = cleanText.substring(7);
        }
        if (cleanText.endsWith('```')) {
          cleanText = cleanText.substring(0, cleanText.lastIndexOf('```'));
        }

        final analysis = jsonDecode(cleanText) as Map<String, dynamic>;

        // Store analysis in Firebase
        await _database
            .ref('diagnosticSessions')
            .child(sessionId)
            .child('aiAnalysis')
            .child('cat')
            .set(analysis);

        return analysis;
      } else {
        throw Exception('Failed to analyze CAT results: ${response.body}');
      }
    } catch (e) {
      print('Error analyzing CAT results: $e');
      return _getFallbackCATAnalysis(responses, thetaEstimate, reliability);
    }
  }

  Future<Map<String, dynamic>> analyzeSJTResults({
    required String userId,
    required String sessionId,
    required List<Map<String, dynamic>> responses,
    required double thetaEstimate,
    required double reliability,
  }) async {
    try {
      String apiKey;
      try {
        apiKey = await rootBundle.loadString('assets/gemini.key');
      } catch (e) {
        print('Gemini API key not found, using mock analysis: $e');
        return _getFallbackSJTAnalysis(responses, thetaEstimate, reliability);
      }
      final endpoint =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?alt=json&key=$apiKey";

      final systemPrompt = """
You are an expert organizational psychologist and behavioral analyst. Analyze the following SJT (Situational Judgment Test) results and provide comprehensive behavioral insights.

Assessment Data:
- Theta Estimate: ${thetaEstimate.toStringAsFixed(3)}
- Reliability: ${(reliability * 100).toStringAsFixed(1)}%
- Total Scenarios: ${responses.length}
- Average Score: ${(responses.fold<double>(0, (sum, r) => sum + (r['score'] ?? 0)) / responses.length).toStringAsFixed(1)}

Provide a detailed behavioral analysis in the following JSON structure:
{
  "overallScore": 78,
  "scoreInterpretation": "Strong situational judgment with good decision-making skills",
  "behavioralProfile": {
    "leadership": 85,
    "teamwork": 82,
    "communication": 88,
    "problemSolving": 75,
    "emotionalIntelligence": 90
  },
  "strengths": ["Excellent communication skills", "Strong leadership potential", "High emotional intelligence"],
  "areasForImprovement": ["Could improve in complex problem-solving scenarios"],
  "behavioralPatterns": ["Collaborative approach", "Empathetic leadership style", "Strategic thinking"],
  "workplaceImplications": ["Natural leader", "Team player", "Conflict resolution skills"],
  "leadershipStyle": "Transformational leader with strong interpersonal skills",
  "recommendations": ["Take on more leadership responsibilities", "Practice complex scenario analysis", "Develop strategic thinking skills"],
  "detailedAnalysis": "Your SJT performance reveals strong behavioral competencies..."
}

Make the analysis insightful, professional, and focused on behavioral patterns.
""";

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                      'Analyze SJT assessment results and provide behavioral insights'
                }
              ],
            },
          ],
          'system_instruction': {
            'parts': [
              {'text': systemPrompt}
            ],
          },
          'generationConfig': {
            'candidateCount': 1,
            'temperature': 0.7,
            'topP': 0.8,
            'maxOutputTokens': 2048
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        final text = jsonResp['candidates'][0]['content']['parts'][0]['text'];

        // Clean the response
        String cleanText = text.trim();
        if (cleanText.startsWith('```json')) {
          cleanText = cleanText.substring(7);
        }
        if (cleanText.endsWith('```')) {
          cleanText = cleanText.substring(0, cleanText.lastIndexOf('```'));
        }

        final analysis = jsonDecode(cleanText) as Map<String, dynamic>;

        // Store analysis in Firebase
        await _database
            .ref('diagnosticSessions')
            .child(sessionId)
            .child('aiAnalysis')
            .child('sjt')
            .set(analysis);

        return analysis;
      } else {
        throw Exception('Failed to analyze SJT results: ${response.body}');
      }
    } catch (e) {
      print('Error analyzing SJT results: $e');
      return _getFallbackSJTAnalysis(responses, thetaEstimate, reliability);
    }
  }

  Future<Map<String, dynamic>> analyzeVoiceResults({
    required String userId,
    required String sessionId,
    required List<Map<String, dynamic>> responses,
    required double thetaEstimate,
    required double reliability,
  }) async {
    try {
      String apiKey;
      try {
        apiKey = await rootBundle.loadString('assets/gemini.key');
      } catch (e) {
        print('Gemini API key not found, using mock analysis: $e');
        return _getFallbackVoiceAnalysis(responses, thetaEstimate, reliability);
      }
      final endpoint =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?alt=json&key=$apiKey";

      final systemPrompt = """
You are an expert communication analyst and voice assessment specialist. Analyze the following voice assessment results and provide comprehensive communication insights.

Assessment Data:
- Theta Estimate: ${thetaEstimate.toStringAsFixed(3)}
- Reliability: ${(reliability * 100).toStringAsFixed(1)}%
- Total Tasks: ${responses.length}
- Average Quality: ${(responses.fold<double>(0, (sum, r) => sum + (r['quality'] ?? 0)) / responses.length).toStringAsFixed(1)}%
- Average Duration: ${(responses.fold<double>(0, (sum, r) => sum + (r['duration'] ?? 0)) / responses.length).toStringAsFixed(1)} seconds

Provide a detailed communication analysis in the following JSON structure:
{
  "overallScore": 82,
  "scoreInterpretation": "Strong communication skills with clear articulation",
  "communicationProfile": {
    "clarity": 88,
    "pace": 85,
    "pronunciation": 90,
    "confidence": 82,
    "emotionalExpression": 78
  },
  "strengths": ["Excellent pronunciation", "Clear articulation", "Good pacing"],
  "areasForImprovement": ["Could work on emotional expression variety"],
  "communicationStyle": "Clear and confident speaker with professional tone",
  "voiceCharacteristics": ["Warm tone", "Steady pace", "Good enunciation"],
  "presentationSkills": ["Strong verbal communication", "Good audience engagement potential"],
  "recommendations": ["Practice varied emotional expression", "Work on vocal dynamics", "Consider public speaking training"],
  "detailedAnalysis": "Your voice assessment reveals strong communication fundamentals..."
}

Focus on communication skills, presentation abilities, and professional speaking characteristics.
""";

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                      'Analyze voice assessment results and provide communication insights'
                }
              ],
            },
          ],
          'system_instruction': {
            'parts': [
              {'text': systemPrompt}
            ],
          },
          'generationConfig': {
            'candidateCount': 1,
            'temperature': 0.7,
            'topP': 0.8,
            'maxOutputTokens': 2048
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        final text = jsonResp['candidates'][0]['content']['parts'][0]['text'];

        // Clean the response
        String cleanText = text.trim();
        if (cleanText.startsWith('```json')) {
          cleanText = cleanText.substring(7);
        }
        if (cleanText.endsWith('```')) {
          cleanText = cleanText.substring(0, cleanText.lastIndexOf('```'));
        }

        final analysis = jsonDecode(cleanText) as Map<String, dynamic>;

        // Store analysis in Firebase
        await _database
            .ref('diagnosticSessions')
            .child(sessionId)
            .child('aiAnalysis')
            .child('voice')
            .set(analysis);

        return analysis;
      } else {
        throw Exception('Failed to analyze voice results: ${response.body}');
      }
    } catch (e) {
      print('Error analyzing voice results: $e');
      return _getFallbackVoiceAnalysis(responses, thetaEstimate, reliability);
    }
  }

  // ===========================================
  // FALLBACK ANALYSIS GENERATORS
  // ===========================================

  Map<String, dynamic> _getFallbackCATAnalysis(
      List<Map<String, dynamic>> responses, double theta, double reliability) {
    final correctCount = responses.where((r) => r['isCorrect'] == true).length;
    final accuracy = (correctCount / responses.length) * 100;

    return {
      'overallScore': (accuracy * 0.8 + (theta + 3) * 10).round(),
      'scoreInterpretation':
          'Strong cognitive performance with good problem-solving abilities',
      'cognitiveProfile': {
        'logicalReasoning': 85,
        'patternRecognition': 82,
        'quantitativeReasoning': 88,
        'verbalReasoning': 80
      },
      'strengths': [
        'Good analytical thinking',
        'Strong problem-solving skills'
      ],
      'areasForImprovement': [
        'Could benefit from more practice in complex scenarios'
      ],
      'careerImplications': ['Well-suited for technical and analytical roles'],
      'learningStyle': 'Logical-analytical learner',
      'recommendations': [
        'Continue practicing with challenging problems',
        'Consider advanced courses'
      ],
      'detailedAnalysis':
          'Your performance shows solid cognitive abilities with room for growth.'
    };
  }

  Map<String, dynamic> _getFallbackSJTAnalysis(
      List<Map<String, dynamic>> responses, double theta, double reliability) {
    final avgScore =
        responses.fold<double>(0, (sum, r) => sum + (r['score'] ?? 0)) /
            responses.length;

    return {
      'overallScore': (avgScore * 20 + (theta + 3) * 8).round(),
      'scoreInterpretation':
          'Good situational judgment with strong decision-making skills',
      'behavioralProfile': {
        'leadership': 85,
        'teamwork': 82,
        'communication': 88,
        'problemSolving': 78,
        'emotionalIntelligence': 85
      },
      'strengths': ['Strong communication skills', 'Good leadership potential'],
      'areasForImprovement': ['Could improve in complex problem-solving'],
      'behavioralPatterns': ['Collaborative approach', 'Strategic thinking'],
      'workplaceImplications': [
        'Natural team player',
        'Good leadership potential'
      ],
      'leadershipStyle': 'Collaborative leader',
      'recommendations': [
        'Take on more leadership roles',
        'Practice complex scenarios'
      ],
      'detailedAnalysis':
          'Your SJT performance indicates strong behavioral competencies.'
    };
  }

  Map<String, dynamic> _getFallbackVoiceAnalysis(
      List<Map<String, dynamic>> responses, double theta, double reliability) {
    final avgQuality =
        responses.fold<double>(0, (sum, r) => sum + (r['quality'] ?? 0)) /
            responses.length;

    return {
      'overallScore': (avgQuality * 0.9 + (theta + 3) * 8).round(),
      'scoreInterpretation':
          'Good communication skills with clear articulation',
      'communicationProfile': {
        'clarity': 85,
        'pace': 82,
        'pronunciation': 88,
        'confidence': 80,
        'emotionalExpression': 78
      },
      'strengths': ['Clear pronunciation', 'Good pacing', 'Professional tone'],
      'areasForImprovement': ['Could work on emotional expression variety'],
      'communicationStyle': 'Clear and professional speaker',
      'voiceCharacteristics': [
        'Steady pace',
        'Good enunciation',
        'Professional tone'
      ],
      'presentationSkills': [
        'Strong verbal communication',
        'Good presentation potential'
      ],
      'recommendations': [
        'Practice varied emotional expression',
        'Work on vocal dynamics'
      ],
      'detailedAnalysis':
          'Your voice assessment shows strong communication fundamentals.'
    };
  }
}
