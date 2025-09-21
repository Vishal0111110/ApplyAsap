import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ComprehensiveResultsScreen extends StatefulWidget {
  final String sessionId;
  final String userId;
  final String assessmentType;
  final Map<String, dynamic> analysis;
  final Map<String, dynamic> basicResults;

  const ComprehensiveResultsScreen({
    Key? key,
    required this.sessionId,
    required this.userId,
    required this.assessmentType,
    required this.analysis,
    required this.basicResults,
  }) : super(key: key);

  @override
  State<ComprehensiveResultsScreen> createState() =>
      _ComprehensiveResultsScreenState();
}

class _ComprehensiveResultsScreenState extends State<ComprehensiveResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getThemeColor() {
    switch (widget.assessmentType) {
      case 'cat':
        return const Color(0xFF5BC0EB);
      case 'sjt':
        return const Color(0xFF4CAF50);
      case 'voice':
        return const Color(0xFF9C27B0);
      default:
        return Colors.blue;
    }
  }

  String _getAssessmentTitle() {
    switch (widget.assessmentType) {
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

  @override
  Widget build(BuildContext context) {
    final themeColor = _getThemeColor();
    final overallScore = widget.analysis['overallScore'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Text('${_getAssessmentTitle()} Results'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF333333),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: themeColor,
              labelColor: themeColor,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
                Tab(text: 'Analysis', icon: Icon(Icons.analytics)),
                Tab(text: 'Insights', icon: Icon(Icons.psychology)),
                Tab(text: 'Recommendations', icon: Icon(Icons.lightbulb)),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, const Color(0xFF1A1A1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(themeColor, overallScore),
            _buildAnalysisTab(themeColor),
            _buildInsightsTab(themeColor),
            _buildRecommendationsTab(themeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Color themeColor, int overallScore) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score Overview Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Overall Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                CircularPercentIndicator(
                  radius: 80,
                  lineWidth: 12,
                  percent: overallScore / 100,
                  center: Text(
                    '$overallScore%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                  progressColor: themeColor,
                  backgroundColor: Colors.white24,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.analysis['scoreInterpretation'] ??
                      'Performance analysis',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Basic Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF333333),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assessment Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatRow('Total Questions',
                    '${widget.basicResults['totalQuestions']}'),
                _buildStatRow('Correct Answers',
                    '${widget.basicResults['correctAnswers']}'),
                _buildStatRow('Accuracy Rate',
                    '${(widget.basicResults['accuracy'] * 100).toStringAsFixed(1)}%'),
                _buildStatRow('Theta Score',
                    widget.basicResults['theta'].toStringAsFixed(3)),
                _buildStatRow('Reliability',
                    '${(widget.basicResults['reliability'] * 100).toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab(Color themeColor) {
    final analysis = widget.analysis;

    if (widget.assessmentType == 'cat') {
      return _buildCognitiveAnalysis(analysis, themeColor);
    } else if (widget.assessmentType == 'sjt') {
      return _buildBehavioralAnalysis(analysis, themeColor);
    } else if (widget.assessmentType == 'voice') {
      return _buildCommunicationAnalysis(analysis, themeColor);
    }

    return const Center(child: Text('Analysis not available'));
  }

  Widget _buildCognitiveAnalysis(
      Map<String, dynamic> analysis, Color themeColor) {
    final cognitiveProfile =
        analysis['cognitiveProfile'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cognitive Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Cognitive Skills Breakdown
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF333333),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildSkillBar('Logical Reasoning',
                    cognitiveProfile['logicalReasoning'] ?? 0, themeColor),
                const SizedBox(height: 16),
                _buildSkillBar('Pattern Recognition',
                    cognitiveProfile['patternRecognition'] ?? 0, themeColor),
                const SizedBox(height: 16),
                _buildSkillBar('Quantitative Reasoning',
                    cognitiveProfile['quantitativeReasoning'] ?? 0, themeColor),
                const SizedBox(height: 16),
                _buildSkillBar('Verbal Reasoning',
                    cognitiveProfile['verbalReasoning'] ?? 0, themeColor),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Strengths and Areas for Improvement
          Row(
            children: [
              Expanded(
                child: _buildStrengthsCard(
                    analysis['strengths'] as List<dynamic>? ?? [], themeColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAreasCard(
                    analysis['areasForImprovement'] as List<dynamic>? ?? [],
                    themeColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBehavioralAnalysis(
      Map<String, dynamic> analysis, Color themeColor) {
    final behavioralProfile =
        analysis['behavioralProfile'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Behavioral Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF333333),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildSkillBar('Leadership',
                    behavioralProfile['leadership'] ?? 0, themeColor),
                const SizedBox(height: 16),
                _buildSkillBar(
                    'Teamwork', behavioralProfile['teamwork'] ?? 0, themeColor),
                const SizedBox(height: 16),
                _buildSkillBar('Communication',
                    behavioralProfile['communication'] ?? 0, themeColor),
                const SizedBox(height: 16),
                _buildSkillBar('Problem Solving',
                    behavioralProfile['problemSolving'] ?? 0, themeColor),
                const SizedBox(height: 16),
                _buildSkillBar(
                    'Emotional Intelligence',
                    behavioralProfile['emotionalIntelligence'] ?? 0,
                    themeColor),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Leadership Style
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leadership Style',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  analysis['leadershipStyle'] ?? 'Leadership style analysis',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationAnalysis(
      Map<String, dynamic> analysis, Color themeColor) {
    final communicationProfile =
        analysis['communicationProfile'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Communication Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF333333),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildSkillBar('Clarity', communicationProfile['clarity'] ?? 0,
                    themeColor),
                const SizedBox(height: 16),
                _buildSkillBar(
                    'Pace', communicationProfile['pace'] ?? 0, themeColor),
                const SizedBox(height: 16),
                _buildSkillBar('Pronunciation',
                    communicationProfile['pronunciation'] ?? 0, themeColor),
                const SizedBox(height: 16),
                _buildSkillBar('Confidence',
                    communicationProfile['confidence'] ?? 0, themeColor),
                const SizedBox(height: 16),
                _buildSkillBar(
                    'Emotional Expression',
                    communicationProfile['emotionalExpression'] ?? 0,
                    themeColor),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Communication Style
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Communication Style',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  analysis['communicationStyle'] ??
                      'Communication style analysis',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(Color themeColor) {
    final analysis = widget.analysis;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Insights',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF333333),
                width: 1,
              ),
            ),
            child: Text(
              analysis['detailedAnalysis'] ?? 'Detailed analysis not available',
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Career Implications
          if (analysis['careerImplications'] != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: themeColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Career Implications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(analysis['careerImplications'] as List<dynamic>).map(
                    (implication) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.work_outline,
                            color: themeColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              implication.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab(Color themeColor) {
    final analysis = widget.analysis;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personalized Recommendations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                ...(analysis['recommendations'] as List<dynamic>? ?? []).map(
                  (recommendation) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: themeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            recommendation.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillBar(String label, int score, Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            Text(
              '$score%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: themeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          lineHeight: 8,
          percent: score / 100,
          backgroundColor: Colors.white24,
          progressColor: themeColor,
          barRadius: const Radius.circular(4),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthsCard(List<dynamic> strengths, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thumb_up, color: themeColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Strengths',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...strengths.map((strength) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '• ${strength.toString()}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAreasCard(List<dynamic> areas, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B35).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: const Color(0xFFFF6B35), size: 18),
              const SizedBox(width: 8),
              Text(
                'Areas for Growth',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF6B35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...areas.map((area) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '• ${area.toString()}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
