import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/diagnostic_item.dart';
import '../models/user_diagnostic_profile.dart';
import '../services/item_bank_service.dart';
import '../services/irt_engine.dart';
import '../services/diagnostics_service.dart';
import 'comprehensive_results_screen.dart';

class CATAssessmentScreen extends StatefulWidget {
  final String sessionId;
  final String userId;
  final Map<String, dynamic> metadata;

  const CATAssessmentScreen({
    Key? key,
    required this.sessionId,
    required this.userId,
    required this.metadata,
  }) : super(key: key);

  @override
  State<CATAssessmentScreen> createState() => _CATAssessmentScreenState();
}

class _CATAssessmentScreenState extends State<CATAssessmentScreen> {
  late ItemBankService _itemService;
  late DiagnosticsService _diagnosticsService;

  List<IRTResponse> responses = [];
  List<String> answeredItemIds = [];
  DiagnosticItem? currentItem;
  bool _assessmentComplete = false;
  ThetaEstimate? currentEstimate;
  Future<bool>? _initializationFuture;

  // Selected answer for current question
  String? _selectedAnswer;

  // Assessment progress
  int _currentStep = 0;
  int _maxSteps = 20; // Target number of items
  double _reliability = 0.0;
  Map<String, dynamic> _progressData = {};

  // Analysis results
  Map<String, dynamic>? _analysis;
  Map<String, dynamic>? _basicResults;

  // Debug information for UI display
  String _debugInfo = '';
  List<String> _debugMessages = [];

  @override
  void initState() {
    super.initState();
    _itemService = ItemBankService();
    _diagnosticsService = DiagnosticsService();
    _addDebugMessage('initState: CAT Assessment screen initialized');
    _initializationFuture = _initializeAssessment();
  }

  Future<bool> _initializeAssessment() async {
    try {
      _addDebugMessage('INIT: Starting CAT assessment initialization...');

      // Generate dynamic questions using Gemini
      _addDebugMessage('INIT: Generating dynamic CAT questions...');
      final questions = await _diagnosticsService.generateCATQuestions(
        userId: widget.userId,
        sessionId: widget.sessionId,
        count: _maxSteps,
      );

      if (questions.isEmpty) {
        throw Exception('No questions generated for CAT assessment.');
      }

      _addDebugMessage('INIT: Generated ${questions.length} CAT questions');

      // Convert questions to DiagnosticItem format for compatibility
      final diagnosticItems = questions.map((q) {
        // Convert options to proper format and determine correct answer letter
        List<String> options = List<String>.from(q['options'] ?? []);
        int correctIndex = q['correctAnswer'] ?? 0;
        String correctAnswerLetter = '';
        List<String> distractors = [];

        for (int i = 0; i < options.length; i++) {
          String letter = String.fromCharCode(65 + i); // A, B, C, D
          String formattedOption = '$letter) ${options[i]}';
          options[i] = formattedOption;

          if (i == correctIndex) {
            correctAnswerLetter = letter;
          } else {
            distractors.add(formattedOption);
          }
        }

        return DiagnosticItem(
          itemId: 'cat_${questions.indexOf(q)}',
          category: q['category'] ?? 'General',
          type: ItemType.cat,
          content: {
            'question': q['question'],
            'options': options,
          },
          parameters: {
            'difficulty': q['difficulty'] ?? 'Medium',
            'category': q['category'] ?? 'General',
          },
          difficulty: 0.0, // Default difficulty
          discrimination: 1.0, // Default discrimination
          correctResponses: [correctAnswerLetter],
          distractors: distractors,
          metadata: {
            'generated': true,
            'source': 'gemini',
          },
          active: true,
          createdAt: DateTime.now(),
          authorId: 'gemini_system',
        );
      }).toList();

      // Store items for IRT processing
      _itemService.addItems(diagnosticItems);

      // Get initial estimate from previous assessments if available
      UserDiagnosticProfile? profile =
          await _diagnosticsService.getUserDiagnosticProfile(widget.userId);
      double initialTheta = 0.0;

      if (profile != null && profile.traitScores.isNotEmpty) {
        // Use mean of existing scores as starting point
        initialTheta = profile.traitScores.values.reduce((a, b) => a + b) /
            profile.traitScores.length;
        _addDebugMessage(
            'Using previous profile data for initial theta: ${initialTheta.toStringAsFixed(3)}');
      } else {
        _addDebugMessage('No previous profile found, starting with theta 0.0');
      }

      // Select first item
      _addDebugMessage(
          'INIT: Selecting first item with initialTheta: ${initialTheta.toStringAsFixed(3)}');
      _selectNextItem(initialTheta);
      _addDebugMessage('INIT: First item selection process finished.');
      _updateDebugInfo();

      if (currentItem == null) {
        _addDebugMessage(
            'INIT: CRITICAL - currentItem is null after first selection.');
        throw Exception('Failed to select an initial item.');
      } else {
        _addDebugMessage(
            'INIT: Successfully selected initial item: ${currentItem!.itemId}');
      }

      return true;
    } catch (e, stackTrace) {
      print('CAT Assessment initialization error: $e');
      print('Stack trace: $stackTrace');
      _addDebugMessage('Initialization failed: $e');
      _showError('Failed to initialize CAT assessment: $e');
      return false;
    }
  }

  void _selectNextItem(double currentTheta) {
    _addDebugMessage(
        'SELECT: Selecting next item. Current theta: ${currentTheta.toStringAsFixed(3)}');
    final availableItems = _itemService.getItemsByType(ItemType.cat);
    _addDebugMessage(
        'SELECT: Found ${availableItems.length} available CAT items.');

    currentItem = IRTEngine.selectNextItem(
      availableItems,
      responses,
      answeredItemIds,
    );
    _addDebugMessage(
        'SELECT: IRTEngine.selectNextItem returned. currentItem is ${currentItem == null ? "null" : currentItem!.itemId}');

    // Update debug info and trigger rebuild
    _updateDebugInfo();
    setState(() {});

    if (currentItem == null) {
      _addDebugMessage('No more items available - completing assessment');
      _completeAssessment();
    } else {
      _addDebugMessage(
          'Selected item: ${currentItem!.itemId} (${currentItem!.category})');
    }

    _updateDebugInfo();
    setState(() {});
  }

  void _addDebugMessage(String message) {
    // A simple logging method for debugging.
    // In a real app, you'd use a proper logger.
    print(message);
  }

  void _updateDebugInfo() {
    final availableItems = _itemService.getItemsByType(ItemType.cat);
    final stats = _itemService.getItemBankStats();

    _debugInfo = '''
Total items in bank: ${stats['totalItems']}
CAT items available: ${availableItems.length}
Answered items: ${answeredItemIds.length}
Current theta: ${currentEstimate?.theta.toStringAsFixed(3) ?? '0.000'}
Reliability: ${(_reliability * 100).toStringAsFixed(1)}%
Current step: ${_currentStep}/${_maxSteps}
Current item: ${currentItem?.itemId ?? 'None'}
    ''';
  }

  void _submitResponse(String selectedAnswer) {
    if (currentItem == null) return;

    final isCorrect = currentItem!.isCorrectResponse(selectedAnswer);
    final response = IRTResponse(
      item: currentItem!,
      isCorrect: isCorrect,
      responseTime: 1000, // Would be measured in actual implementation
    );

    responses.add(response);
    answeredItemIds.add(currentItem!.itemId);

    _currentStep++;

    // Update theta estimate
    currentEstimate = IRTEngine.estimateThetaEAP(responses);
    _reliability = IRTEngine.calculateReliability(responses);

    // Check if we should stop
    if (_currentStep >= _maxSteps ||
        IRTEngine.shouldStopTest(responses, 0.80)) {
      _completeAssessment();
    } else {
      _selectNextItem(currentEstimate!.theta);
    }

    _updateProgressData();
    setState(() {});
  }

  void _updateProgressData() {
    _progressData = {
      'currentItem': currentItem?.itemId ?? null,
      'currentStep': _currentStep,
      'totalSteps': _maxSteps,
      'reliability': _reliability,
      'completedItems': responses.length,
      'currentTheta': currentEstimate?.theta ?? 0.0,
      'thetaVariance': currentEstimate?.variance ?? 0.0,
      'itemLevel': _getItemLevel(),
    };
  }

  String _getItemLevel() {
    if (responses.isEmpty) return 'Beginning';
    double avgScore =
        responses.where((r) => r.isCorrect).length / responses.length;
    if (avgScore >= 0.8) return 'Advanced';
    if (avgScore >= 0.6) return 'Intermediate';
    if (avgScore >= 0.4) return 'Basic';
    return 'Beginning';
  }

  void _completeAssessment() async {
    _assessmentComplete = true;

    // Final theta estimate
    final finalEstimate = IRTEngine.estimateThetaEAP(responses);

    // Calculate final scores
    final correctCount = responses.where((r) => r.isCorrect).length;
    final totalCount = responses.length;
    final percentage = totalCount > 0 ? correctCount / totalCount : 0.0;

    _basicResults = {
      'totalQuestions': totalCount,
      'correctAnswers': correctCount,
      'accuracy': percentage,
      'theta': finalEstimate.theta,
      'reliability': finalEstimate.reliability,
    };

    // Store user responses in Firebase
    final userResponseDetails = responses
        .map((r) => {
              'itemId': r.item.itemId,
              'userAnswer': r.item.correctResponses.isNotEmpty
                  ? r.item.correctResponses.first
                  : '',
              'isCorrect': r.isCorrect,
              'responseTime': r.responseTime,
              'question': {
                'question': r.item.content['question'],
                'options': r.item.content['options']
              },
            })
        .toList();

    await _diagnosticsService.storeUserResponses(
        widget.sessionId, widget.userId, userResponseDetails);

    // Save basic results
    await _saveAssessmentResults(finalEstimate);

    // Analyze results with AI
    _analysis = await _diagnosticsService.analyzeCATResults(
      userId: widget.userId,
      sessionId: widget.sessionId,
      responses: responses
          .map((r) => {
                'isCorrect': r.isCorrect,
                'responseTime': r.responseTime,
                'itemId': r.item.itemId,
              })
          .toList(),
      thetaEstimate: finalEstimate.theta,
      reliability: finalEstimate.reliability,
    );

    setState(() {});
  }

  Future<void> _saveAssessmentResults(ThetaEstimate estimate) async {
    // Calculate final scores
    final correctCount = responses.where((r) => r.isCorrect).length;
    final totalItems = responses.length;

    // This would integrate with the diagnostics service to save results
    // For now, just print the results
    print('Assessment Results Saved:');
    print('Theta: ${estimate.theta.toStringAsFixed(3)}');
    print('Standard Error: ${estimate.standardError.toStringAsFixed(3)}');
    print('Reliability: ${(estimate.reliability * 100).toStringAsFixed(1)}%');
    print('Items Answered: $totalItems');
    print('Correct Answers: $correctCount');
    print(
        'Accuracy: ${((correctCount / totalItems) * 100).toStringAsFixed(1)}%');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              centerTitle: true,
              title: const Text('CAT Assessment'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitPouringHourGlass(
                    color: Color(0xFF5BC0EB),
                    size: 120,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Generating questions...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!) {
          return _buildErrorScreen(snapshot.error);
        }

        if (_assessmentComplete) {
          return _buildCompletionScreen();
        }

        if (currentItem == null) {
          return _buildDebugScreen();
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            centerTitle: true,
            title: const Text('CAT Assessment'),
            actions: [
              _buildProgressIndicator(),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuestionHeader(),
                const SizedBox(height: 24),
                _buildQuestionContent(),
                const SizedBox(height: 32),
                Expanded(child: _buildAnswerOptions()),
                _buildSubmitButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text('$_currentStep/$_maxSteps',
              style: const TextStyle(color: Colors.white, fontSize: 10)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: _currentStep / _maxSteps,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5BC0EB)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${_currentStep + 1} of $_maxSteps',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF323232),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  currentItem!.category,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5BC0EB).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF5BC0EB).withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  'CAT Assessment',
                  style: const TextStyle(
                    color: Color(0xFF5BC0EB),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reliability: ${(_reliability * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent() {
    final question = currentItem!.content['question'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF5BC0EB).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        question,
        style: const TextStyle(
          fontSize: 18,
          height: 1.5,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAnswerOptions() {
    final options = List<String>.from(currentItem!.content['options'] ?? []);

    return ListView.builder(
      shrinkWrap: true,
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final optionLetter = option.split(')')[0].trim();
        bool isSelected = _selectedAnswer == optionLetter;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedAnswer = optionLetter;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF5BC0EB).withOpacity(0.15)
                    : const Color(0xFF252525),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF5BC0EB)
                      : const Color(0xFF333333),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Option letter indicator
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF5BC0EB)
                          : const Color(0xFF404040),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index), // A, B, C, D
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Option text (already formatted with letters)
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),

                  // Selection indicator
                  if (isSelected)
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5BC0EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    bool hasSelection = _selectedAnswer != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: hasSelection
            ? () {
                if (_selectedAnswer != null) {
                  _submitResponse(_selectedAnswer!);
                  // Reset selection for next question
                  _selectedAnswer = null;
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5BC0EB),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          'Next Question',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDebugScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text('CAT Assessment Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _initializationFuture = _initializeAssessment();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _debugInfo,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Log Messages',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _debugMessages.length,
                itemBuilder: (context, index) {
                  final message =
                      _debugMessages[_debugMessages.length - 1 - index];
                  return Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _initializationFuture = _initializeAssessment();
                });
              },
              child: const Text('Retry Initialization'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    final correctCount = responses.where((r) => r.isCorrect).length;
    final totalCount = responses.length;
    final accuracy = totalCount > 0 ? (correctCount / totalCount * 100) : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text('Assessment Complete'),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xFF1A1A1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF5BC0EB).withOpacity(0.2),
                      const Color(0xFF5BC0EB).withOpacity(0.1)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFF5BC0EB).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF5BC0EB),
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'CAT Assessment Complete!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '$correctCount of $totalCount correct\n${accuracy.toStringAsFixed(1)}% accuracy',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 280),
                child: ElevatedButton(
                  onPressed: () {
                    if (_analysis != null && _basicResults != null) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => ComprehensiveResultsScreen(
                            sessionId: widget.sessionId,
                            userId: widget.userId,
                            assessmentType: 'cat',
                            analysis: _analysis!,
                            basicResults: _basicResults!,
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5BC0EB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text(
                    'View Detailed Analysis',
                    style: TextStyle(
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
      ),
    );
  }

  Widget _buildErrorScreen(Object? error) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text('Assessment Error'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Failed to load assessment',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'An error occurred during initialization. Please try again later.',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(
                  error.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
