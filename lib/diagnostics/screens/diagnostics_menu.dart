import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../colors.dart';
import '../services/diagnostics_service.dart';
import '../services/item_bank_service.dart';
import '../widgets/assessment_card.dart';
import 'consent_screen.dart';
import 'diagnostics_profile_screen.dart';
import 'cat_assessment_screen.dart';
import 'sjt_assessment_screen.dart';
import 'voice_assessment_screen.dart';

class DiagnosticsMenuScreen extends StatefulWidget {
  const DiagnosticsMenuScreen({super.key});

  @override
  State<DiagnosticsMenuScreen> createState() => _DiagnosticsMenuScreenState();
}

class _DiagnosticsMenuScreenState extends State<DiagnosticsMenuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await ItemBankService().initializeItemBank();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing services: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading assessment data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading Assessments...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFF333333),
                        width: 1,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF5BC0EB),
                    labelColor: const Color(0xFF5BC0EB),
                    unselectedLabelColor: Colors.grey,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 32),
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(
                        text: 'Assessments',
                      ),
                      Tab(
                        text: 'My Profile',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAssessmentsTab(),
                      const DiagnosticsProfileScreen(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAssessmentsTab() {
    final assessments = [
      {
        'title': 'Cognitive Ability Test',
        'description':
            'Measure your problem-solving and logical reasoning skills. This computer adaptive test adjusts difficulty based on your responses.',
        'type': 'cat',
        'duration': '15-20 min',
        'questions': '~20 questions',
        'icon': Icons.psychology,
        'gradient': const [Color(0xFF5BC0EB), Color(0xFF4FC3F7)],
      },
      {
        'title': 'Situational Judgment Test',
        'description':
            'Assess your decision-making and interpersonal skills through realistic workplace scenarios.',
        'type': 'sjt',
        'duration': '10-15 min',
        'questions': '20 scenarios',
        'icon': Icons.people,
        'gradient': const [Color(0xFFFF6B35), Color(0xFFFF8A5C)],
      },
      {
        'title': 'Voice Assessment',
        'description':
            'Evaluate communication skills and emotional intelligence through enhanced prosody analysis.',
        'type': 'voice',
        'duration': '5-10 min',
        'questions': '5 prompts',
        'icon': Icons.mic,
        'gradient': const [Color(0xFF4CAF50), Color(0xFF66BB6A)],
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1F1F1F), Color(0xFF252525)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF5BC0EB).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.science_outlined,
                  color: Color(0xFF5BC0EB),
                  size: 28,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Comprehensive Career Assessment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Discover your cognitive strengths, behavioral competencies, and communication skills.',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Available Assessments',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: assessments.length,
              itemBuilder: (context, index) {
                final assessment = assessments[index];
                return AssessmentCard(
                  assessmentData: assessment,
                  onStartAssessment: () async {
                    await _handleAssessmentStart(context, assessment);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAssessmentStart(
      BuildContext context, Map<String, dynamic> assessment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if user has given consent
    final hasConsent = await DiagnosticsService().checkUserConsent(user.uid);

    if (!hasConsent) {
      // Navigate to consent screen
      final consentGranted = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ConsentScreen(),
        ),
      );

      if (!consentGranted || consentGranted == null) return;
    }

    // Start the assessment
    try {
      final sessionResult = await DiagnosticsService().startAssessment(
        userId: user.uid,
        assessmentType: assessment['type'],
        metadata: {
          'assessmentName': assessment['title'],
          'userAgent': '', // Would get from platform
        },
      );

      // Navigate to actual assessment based on type
      _navigateToAssessment(
          context, assessment['type'], sessionResult['sessionId']);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start assessment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToAssessment(
      BuildContext context, String type, String sessionId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Widget? assessmentScreen;

    switch (type) {
      case 'cat':
        assessmentScreen = CATAssessmentScreen(
          sessionId: sessionId,
          userId: user.uid,
          metadata: {'assessmentName': 'Cognitive Ability Test'},
        );
        break;
      case 'sjt':
        assessmentScreen = SJTAssessmentScreen(
          sessionId: sessionId,
          userId: user.uid,
          metadata: {'assessmentName': 'Situational Judgment Test'},
        );
        break;
      case 'voice':
        assessmentScreen = VoiceAssessmentScreen(
          sessionId: sessionId,
          userId: user.uid,
          metadata: {'assessmentName': 'Voice Assessment'},
        );
        break;
    }

    if (assessmentScreen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => assessmentScreen!),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assessment type not supported'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
