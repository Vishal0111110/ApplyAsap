import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_diagnostic_profile.dart';
import '../services/diagnostics_service.dart';

class DiagnosticsProfileScreen extends StatefulWidget {
  const DiagnosticsProfileScreen({super.key});

  @override
  State<DiagnosticsProfileScreen> createState() =>
      _DiagnosticsProfileScreenState();
}

class _DiagnosticsProfileScreenState extends State<DiagnosticsProfileScreen> {
  UserDiagnosticProfile? _userProfile;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _userSessions = [];
  bool _isLoading = true;
  final DiagnosticsService _diagnosticsService = DiagnosticsService();

  @override
  void initState() {
    super.initState();
    _loadUserProfileAndSessions();
  }

  Future<void> _loadUserProfileAndSessions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      _userProfile =
          await _diagnosticsService.getUserDiagnosticProfile(user.uid);
      _stats = await _diagnosticsService.getAssessmentStats(user.uid);
      _userSessions = await _diagnosticsService.getUserSessions(user.uid);
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF5BC0EB),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: _userProfile == null ? _buildEmptyState() : _buildProfileContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF5BC0EB).withOpacity(0.3),
              ),
            ),
            child: const Icon(
              Icons.psychology_outlined,
              color: Color(0xFF5BC0EB),
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Assessments Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take your first diagnostic assessment to see your results here.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Switch to assessments tab
              DefaultTabController.of(context)?.animateTo(0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5BC0EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Take Assessment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final traitScores = _userProfile!.traitScores;
    final assessmentHistory = _userProfile!.assessmentHistory;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Overview
          _buildStatisticsSection(),

          const SizedBox(height: 20),

          // Trait Scores
          if (traitScores.isNotEmpty) ...[
            _buildTraitScoresSection(traitScores),
            const SizedBox(height: 20),
          ],

          // Session History - Session Cards
          if (_userSessions.isNotEmpty) ...[
            _buildSessionCards(),
            const SizedBox(height: 20),
          ],

          // Privacy & Consent Information
          _buildPrivacySettings(),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F1F1F), Color(0xFF252525)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF5BC0EB).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assessment Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              Row(
                children: [
                  _buildStatItem(
                    Icons.assignment_turned_in,
                    _stats['totalAssessments']?.toInt() ?? 1,
                    'Total Assessments',
                  ),
                  _buildStatItem(
                    Icons.science,
                    _stats['catAssessments']?.toInt() ?? 1,
                    'CAT Tests',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatItem(
                    Icons.people,
                    _stats['sjtAssessments']?.toInt() ?? 0,
                    'SJT Tests',
                  ),
                  _buildStatItem(
                    Icons.mic,
                    _stats['voiceAssessments']?.toInt() ?? 0,
                    'Voice Tests',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Last Assessment: ${_formatDate(_userProfile!.lastAssessment)}',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraitScoresSection(Map<String, double> traitScores) {
    final traits = [
      {
        'key': 'cognitive_ability',
        'name': 'Cognitive Ability',
        'icon': Icons.psychology,
        'color': const Color(0xFF5BC0EB)
      },
      {
        'key': 'emotional_intelligence',
        'name': 'Emotional Intelligence',
        'icon': Icons.heart_broken,
        'color': const Color(0xFFFF6B35)
      },
      {
        'key': 'communication_skill',
        'name': 'Communication Skills',
        'icon': Icons.voice_over_off,
        'color': const Color(0xFF4CAF50)
      },
      {
        'key': 'leadership_potential',
        'name': 'Leadership Potential',
        'icon': Icons.group,
        'color': const Color(0xFF9C27B0)
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Career Strengths',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...traits.map((trait) {
          final score = traitScores[trait['key']];
          if (score == null) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (trait['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (trait['color'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    trait['icon'] as IconData,
                    color: trait['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trait['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: score / 100,
                        backgroundColor: Colors.grey.shade700,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          trait['color'] as Color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Score: ${score.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).where((element) => element != const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildSessionCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Session History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._userSessions.map((session) {
          final typeIcon = _getAssessmentTypeIcon(session['assessmentType']);
          final typeColor = _getAssessmentTypeColor(session['assessmentType']);
          final aiAnalysis = session['aiAnalysis'] as Map<String, dynamic>?;
          final overallScore = aiAnalysis?['overallScore'] ?? 0;

          return GestureDetector(
            onTap: () => _showSessionDetails(session),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: typeColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      typeIcon,
                      color: typeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getAssessmentTypeName(session['assessmentType']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatDate(session['completedAt']),
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        overallScore.toStringAsFixed(1),
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Score',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade600,
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showSessionDetails(Map<String, dynamic> session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) =>
            _buildSessionDetailsContent(session, scrollController),
      ),
    );
  }

  Widget _buildSessionDetailsContent(
      Map<String, dynamic> session, ScrollController scrollController) {
    final typeColor = _getAssessmentTypeColor(session['assessmentType']);
    final typeIcon = _getAssessmentTypeIcon(session['assessmentType']);
    final aiAnalysis = session['aiAnalysis'] as Map<String, dynamic>?;
    final generatedQuestions =
        session['generatedQuestions'] as Map<String, dynamic>?;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getAssessmentTypeName(session['assessmentType']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(session['completedAt']),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (aiAnalysis?['overallScore'] != null)
                  Text(
                    '${aiAnalysis!['overallScore']}%',
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Questions & Answers Section
            if (generatedQuestions != null && generatedQuestions.isNotEmpty)
              _buildQuestionsSection(session, typeColor),

            // AI Analysis Section
            if (aiAnalysis != null && aiAnalysis.isNotEmpty)
              _buildAIAnalysisSection(aiAnalysis, typeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsSection(Map<String, dynamic> session, Color typeColor) {
    final generatedQuestions =
        session['generatedQuestions'] as Map<String, dynamic>;
    final userResponses = session['userResponses'] as Map<String, dynamic>?;

    final questions = <Map<String, dynamic>>[];

    // For CAT assessment
    if (generatedQuestions.containsKey('cat')) {
      questions.addAll(generatedQuestions['cat']);
    }
    // For SJT assessment
    if (generatedQuestions.containsKey('sjt')) {
      questions.addAll(generatedQuestions['sjt']);
    }
    // For Voice assessment
    if (generatedQuestions.containsKey('voice')) {
      questions.addAll(generatedQuestions['voice']);
    }

    if (questions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Questions & Answers',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...questions.asMap().entries.map((entry) {
          final questionIndex = entry.key;
          final question = entry.value as Map<String, dynamic>;
          final userAnswer =
              userResponses?['response_$questionIndex']?['userAnswer'];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade700,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question
                Text(
                  question['question'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (question['options'] != null) ...[
                  const SizedBox(height: 12),
                  // Options (for CAT/SJT)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        List<String>.from(question['options']).map((option) {
                      final isUserAnswer =
                          userAnswer != null && option.contains(userAnswer);
                      final isCorrectAnswer =
                          question['correctAnswer'] != null &&
                              question['correctAnswer'] is int &&
                              List<String>.from(question['options'])
                                      .indexOf(option) ==
                                  question['correctAnswer'];

                      return Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isUserAnswer
                              ? const Color(0xFF5BC0EB).withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isCorrectAnswer
                                ? Colors.green
                                : isUserAnswer
                                    ? const Color(0xFF5BC0EB)
                                    : Colors.grey.shade600,
                            width: isCorrectAnswer || isUserAnswer ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  color: isUserAnswer
                                      ? Colors.white
                                      : Colors.grey.shade300,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (isCorrectAnswer)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              )
                            else if (isUserAnswer)
                              Icon(
                                Icons.circle,
                                color: const Color(0xFF5BC0EB),
                                size: 16,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Voice prompts (for voice assessment)
                if (question['prompt'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: typeColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      question['prompt'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAIAnalysisSection(
      Map<String, dynamic> aiAnalysis, Color typeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Analysis',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Overall Score
        if (aiAnalysis['overallScore'] != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: typeColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${aiAnalysis['overallScore']}%',
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aiAnalysis['scoreInterpretation'] ??
                            'Performance Analysis',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (aiAnalysis['overallScore'] as int).toDouble() /
                            100,
                        backgroundColor: Colors.grey.shade700,
                        valueColor: AlwaysStoppedAnimation<Color>(typeColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Detailed Analysis
        if (aiAnalysis['detailedAnalysis'] != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade700,
              ),
            ),
            child: Text(
              aiAnalysis['detailedAnalysis'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Strengths
        if (aiAnalysis['strengths'] != null &&
            (aiAnalysis['strengths'] as List).isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.thumb_up, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Strengths',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List<String>.from(aiAnalysis['strengths']).map((strength) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $strength',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Areas for Improvement
        if (aiAnalysis['areasForImprovement'] != null &&
            (aiAnalysis['areasForImprovement'] as List).isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF6B35).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up,
                        color: const Color(0xFFFF6B35), size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Areas for Improvement',
                      style: TextStyle(
                        color: Color(0xFFFF6B35),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List<String>.from(aiAnalysis['areasForImprovement'])
                    .map((area) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $area',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade700,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Privacy & Consent',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPrivacyItem(
            'Data Collection',
            'Assessment responses and results',
            _userProfile!.privacyConsent,
          ),
          const SizedBox(height: 8),
          _buildPrivacyItem(
            'Research Participation',
            'Anonymous data for research',
            _userProfile!.dataSharingConsent,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _showPrivacyDialog,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF5BC0EB)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Update Privacy Settings',
              style: TextStyle(
                color: Color(0xFF5BC0EB),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem(String title, String description, bool enabled) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: enabled
                ? const Color(0xFF4CAF50).withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? const Color(0xFF4CAF50) : Colors.grey,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, int count, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF5BC0EB).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF5BC0EB),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog() {
    // Navigate to consent screen for updates
    // (Implementation would require similar consent screen functionality)
  }

  IconData _getAssessmentTypeIcon(String type) {
    switch (type) {
      case 'cat':
        return Icons.psychology;
      case 'sjt':
        return Icons.people;
      case 'voice':
        return Icons.mic;
      default:
        return Icons.assessment;
    }
  }

  Color _getAssessmentTypeColor(String type) {
    switch (type) {
      case 'cat':
        return const Color(0xFF5BC0EB);
      case 'sjt':
        return const Color(0xFFFF6B35);
      case 'voice':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  String _getAssessmentTypeName(String type) {
    switch (type) {
      case 'cat':
        return 'Cognitive Ability Test';
      case 'sjt':
        return 'Situational Judgment Test';
      case 'voice':
        return 'Voice Assessment';
      default:
        return 'Assessment';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
