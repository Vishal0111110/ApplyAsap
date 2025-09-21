import 'package:flutter/material.dart';
import '../models/diagnostic_item.dart';
import '../models/user_diagnostic_profile.dart';
import '../services/item_bank_service.dart';
import '../services/irt_engine.dart';
import '../services/diagnostics_service.dart';
import 'comprehensive_results_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SJTAssessmentScreen extends StatefulWidget {
  final String sessionId;
  final String userId;
  final Map<String, dynamic> metadata;

  const SJTAssessmentScreen({
    Key? key,
    required this.sessionId,
    required this.userId,
    required this.metadata,
  }) : super(key: key);

  @override
  State<SJTAssessmentScreen> createState() => _SJTAssessmentScreenState();
}

class _SJTAssessmentScreenState extends State<SJTAssessmentScreen> {
  late ItemBankService _itemService;
  late DiagnosticsService _diagnosticsService;

  List<IRTResponse> responses = [];
  List<String> answeredItemIds = [];
  DiagnosticItem? currentItem;
  bool _assessmentComplete = false;
  ThetaEstimate? currentEstimate;
  Future<bool>? _initializationFuture;

  // Best-Worst selection tracking
  String? _selectedBest;
  String? _selectedWorst;
  bool _bestSelected = false;
  bool _worstSelected = false;

  // Assessment progress
  int _currentStep = 0;
  int _maxSteps = 20; // Target number of SJT scenarios
  double _reliability = 0.0;
  Map<String, dynamic> _progressData = {};

  // Analysis results
  Map<String, dynamic>? _analysis;
  Map<String, dynamic>? _basicResults;

  @override
  void initState() {
    super.initState();
    _itemService = ItemBankService();
    _diagnosticsService = DiagnosticsService();
    _addDebugMessage('initState: SJT Assessment screen initialized');
    _initializationFuture = _initializeAssessment();
  }

  Future<bool> _initializeAssessment() async {
    try {
      _addDebugMessage('INIT: Starting SJT assessment initialization...');

      // Generate dynamic SJT questions using Gemini
      _addDebugMessage('INIT: Generating dynamic SJT scenarios...');
      final scenarios = await _diagnosticsService.generateSJTQuestions(
        userId: widget.userId,
        sessionId: widget.sessionId,
        count: _maxSteps,
      );

      if (scenarios.isEmpty) {
        throw Exception('No scenarios generated for SJT assessment.');
      }

      _addDebugMessage('INIT: Generated ${scenarios.length} SJT scenarios');

      // Convert scenarios to DiagnosticItem format for compatibility
      final diagnosticItems = scenarios.map((s) {
        // Convert scoring matrix to proper type
        Map<String, int>? scoringMatrix;
        if (s['scoringMatrix'] != null && s['scoringMatrix'] is Map) {
          var localMatrix = <String, int>{};
          (s['scoringMatrix']! as Map<dynamic, dynamic>).forEach((key, value) {
            if (value is int) {
              localMatrix[key.toString()] = value;
            } else if (value is double) {
              localMatrix[key.toString()] = value.round();
            }
          });
          scoringMatrix = localMatrix;
        }

        return DiagnosticItem(
          itemId: 'sjt_${scenarios.indexOf(s)}',
          category: s['category'] ?? 'General',
          type: ItemType.sjt,
          content: {
            'scenario': s['scenario'],
            'bestWorstQuestion': s['bestWorstQuestion'],
            'responseOptions': s['responseOptions'],
          },
          parameters: {
            'category': s['category'] ?? 'General',
          },
          difficulty: 0.0, // Default difficulty
          discrimination: 1.0, // Default discrimination
          correctResponses: [
            'best_worst_selected'
          ], // SJT has no single correct answer
          distractors: [],
          metadata: {
            'generated': true,
            'source': 'gemini',
          },
          scoringMatrix: scoringMatrix,
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
      print('SJT Assessment initialization error: $e');
      print('Stack trace: $stackTrace');
      _addDebugMessage('Initialization failed: $e');
      _showError('Failed to initialize SJT assessment: $e');
      return false;
    }
  }

  void _selectNextItem(double currentTheta) {
    _addDebugMessage(
        'SELECT: Selecting next item. Current theta: ${currentTheta.toStringAsFixed(3)}');
    final availableItems = _itemService.getItemsByType(ItemType.sjt);
    _addDebugMessage(
        'SELECT: Found ${availableItems.length} available SJT items.');

    currentItem = IRTEngine.selectNextItem(
      availableItems,
      responses,
      answeredItemIds,
    );
    _addDebugMessage(
        'SELECT: IRTEngine.selectNextItem returned. currentItem is ${currentItem == null ? "null" : currentItem!.itemId}');

    if (currentItem == null) {
      _completeAssessment();
    }

    // Reset selections for new item
    _selectedBest = null;
    _selectedWorst = null;
    _bestSelected = false;
    _worstSelected = false;
  }

  void _submitBestWorstResponse() {
    if (currentItem == null || _selectedBest == null || _selectedWorst == null)
      return;

    // For SJT, we don't have a simple "correct/incorrect" - instead we score based on best-worst pair
    // For IRT purposes, we'll consider it "correct" if the selected pair matches expected patterns
    String pairKey = '${_selectedBest}_${_selectedWorst}';
    Map<String, int>? scoringMatrix = currentItem!.scoringMatrix;

    if (scoringMatrix == null) {
      // If no scoring matrix, treat as incorrect for IRT purposes
      final isCorrect = false;
    }

    // In a real implementation, this would be 1.0 if the pair is optimal, 0.0 otherwise
    // For simplicity, let's use a score between 0.0 and 1.0 based on the scoring value
    int maxScore = scoringMatrix!.values.reduce((a, b) => a > b ? a : b);
    int score = scoringMatrix[pairKey] ?? 0;
    double normalizedScore = score.toDouble() / maxScore.toDouble();

    bool isCorrect = normalizedScore >= 0.7; // Arbitrary threshold for IRT

    if (scoringMatrix == null) {
      isCorrect = false; // Ensure it's false if no scoring matrix
    }

    final response = IRTResponse(
      item: currentItem!,
      isCorrect: isCorrect,
      responseTime: 3000, // SJT typically takes longer
    );

    responses.add(response);
    answeredItemIds.add(currentItem!.itemId);

    _currentStep++;

    // Update theta estimate
    currentEstimate = IRTEngine.estimateThetaEAP(responses);
    _reliability = IRTEngine.calculateReliability(responses);

    // Check if we should stop
    if (_currentStep >= _maxSteps ||
        IRTEngine.shouldStopTest(responses, 0.75)) {
      _completeAssessment();
    } else {
      _selectNextItem(currentEstimate!.theta);
    }

    _updateProgressData();
    setState(() {});
  }

  bool _canSubmit() {
    return _bestSelected && _worstSelected && _selectedBest != _selectedWorst;
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
      'selectedBest': _selectedBest,
      'selectedWorst': _selectedWorst,
    };
  }

  void _completeAssessment() async {
    _assessmentComplete = true;
    final finalEstimate = IRTEngine.estimateThetaEAP(responses);

    _basicResults = {
      'totalScenarios': responses.length,
      'avgScore':
          responses.fold<double>(0, (sum, r) => sum + (r.isCorrect ? 1 : 0)) /
              responses.length,
      'theta': finalEstimate.theta,
      'reliability': finalEstimate.reliability,
    };

    // Save basic results
    await _saveAssessmentResults(finalEstimate);

    // Analyze results with AI
    _analysis = await _diagnosticsService.analyzeSJTResults(
      userId: widget.userId,
      sessionId: widget.sessionId,
      responses: responses
          .map((r) => {
                'score': r.isCorrect ? 1 : 0,
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
    final totalItems = responses.length;
    int bestWorstPairs = 0;

    // Count how many responses had both best and worst selected
    for (var response in responses) {
      // This would need to be tracked differently in a full implementation
      // For now, we'll assume all were completed properly
      bestWorstPairs++;
    }

    print('SJT Assessment Results Saved:');
    print('Theta: ${estimate.theta.toStringAsFixed(3)}');
    print('Standard Error: ${estimate.standardError.toStringAsFixed(3)}');
    print('Reliability: ${(estimate.reliability * 100).toStringAsFixed(1)}%');
    print('Scenarios Completed: $totalItems');
    print('Best-Worst Pairs: $bestWorstPairs');
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
              title: const Text('SJT Assessment'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitPouringHourGlass(
                    color: Color(0xFF4CAF50),
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
          return _buildDebugScreen(snapshot.error);
        }

        if (_assessmentComplete) {
          return _buildCompletionScreen();
        }

        if (currentItem == null) {
          return _buildDebugScreen('No more scenarios available.');
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            centerTitle: true,
            title: const Text('SJT Assessment'),
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
                Expanded(child: _buildScenarioContent()),
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
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
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
            'Scenario ${_currentStep + 1} of $_maxSteps',
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
                  color: const Color(0xFF4CAF50).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'SJT Assessment',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select the BEST and WORST responses',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.thumb_up, color: Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              Text(_bestSelected ? 'Best: $_selectedBest' : 'Select Best',
                  style: TextStyle(
                      color: _bestSelected
                          ? Color(0xFF4CAF50)
                          : Colors.grey.shade400)),
              const SizedBox(width: 24),
              const Icon(Icons.thumb_down, color: Color(0xFFFF6B35)),
              const SizedBox(width: 8),
              Text(_worstSelected ? 'Worst: $_selectedWorst' : 'Select Worst',
                  style: TextStyle(
                      color: _worstSelected
                          ? Color(0xFFFF6B35)
                          : Colors.grey.shade400)),
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

  Widget _buildScenarioContent() {
    final scenario = currentItem!.content['scenario'] as String;
    final bestWorstQuestion =
        currentItem!.content['bestWorstQuestion'] as String;
    final responseOptions =
        List<String>.from(currentItem!.content['responseOptions'] ?? []);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scenario text
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
            child: Text(
              scenario,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Best-Worst question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              bestWorstQuestion,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Response options with toggle buttons
          ...responseOptions.asMap().entries.map((entry) {
            int index = entry.key;
            String option = entry.value;
            String optionLetter = option.split(')')[0].trim();

            return _buildOptionCard(option, optionLetter, index);
          }),
        ],
      ),
    );
  }

  Widget _buildOptionCard(String fullOption, String optionLetter, int index) {
    bool isSelectedBest = _selectedBest == optionLetter;
    bool isSelectedWorst = _selectedWorst == optionLetter;

    Color cardColor = const Color(0xFF1A1A1A);
    if (isSelectedBest) cardColor = const Color(0xFF4CAF50).withOpacity(0.2);
    if (isSelectedWorst) cardColor = const Color(0xFFFF6B35).withOpacity(0.2);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    fullOption,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          if (_selectedBest == optionLetter) {
                            _selectedBest = null;
                            _bestSelected = false;
                          } else {
                            _selectedBest = optionLetter;
                            _bestSelected = true;
                          }
                        });
                      },
                      icon: Icon(
                        Icons.thumb_up,
                        color: isSelectedBest
                            ? Colors.white
                            : const Color(0xFF4CAF50),
                        size: 16,
                      ),
                      label: const Text('Best'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelectedBest
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF2A2A2A),
                        foregroundColor: isSelectedBest
                            ? Colors.white
                            : const Color(0xFF4CAF50),
                        minimumSize: const Size(60, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          if (_selectedWorst == optionLetter) {
                            _selectedWorst = null;
                            _worstSelected = false;
                          } else {
                            _selectedWorst = optionLetter;
                            _worstSelected = true;
                          }
                        });
                      },
                      icon: Icon(
                        Icons.thumb_down,
                        color: isSelectedWorst
                            ? Colors.white
                            : const Color(0xFFFF6B35),
                        size: 16,
                      ),
                      label: const Text('Worst'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelectedWorst
                            ? const Color(0xFFFF6B35)
                            : const Color(0xFF2A2A2A),
                        foregroundColor: isSelectedWorst
                            ? Colors.white
                            : const Color(0xFFFF6B35),
                        minimumSize: const Size(60, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canSubmit() ? _submitBestWorstResponse : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          'Next Scenario',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
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
                      const Color(0xFF4CAF50).withOpacity(0.2),
                      const Color(0xFF4CAF50).withOpacity(0.1)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: Color(0xFF4CAF50),
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'SJT Assessment Complete!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '$_currentStep situational judgment\nscenarios completed',
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
                            assessmentType: 'sjt',
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
                    backgroundColor: const Color(0xFF4CAF50),
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

  void _updateDebugInfo() {
    final availableItems = _itemService.getItemsByType(ItemType.sjt);
    final stats = _itemService.getItemBankStats();

    String debugInfo = '''
Total items in bank: ${stats['totalItems']}
SJT items available: ${availableItems.length}
Answered items: ${answeredItemIds.length}
Current theta: ${currentEstimate?.theta.toStringAsFixed(3) ?? '0.000'}
Reliability: ${(_reliability * 100).toStringAsFixed(1)}%
Current step: ${_currentStep}/${_maxSteps}
Current item: ${currentItem?.itemId ?? 'None'}
Selected Best: ${_selectedBest ?? 'None'}
Selected Worst: ${_selectedWorst ?? 'None'}
    ''';
  }

  void _addDebugMessage(String message) {
    // A simple logging method for debugging.
    // In a real app, you'd use a proper logger.
    print(message);
  }

  Widget _buildDebugScreen(Object? error) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text('SJT Assessment Debug'),
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
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 16),
            if (error != null) ...[
              Text(
                'Error: ${error.toString()}',
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
            ],
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
}
