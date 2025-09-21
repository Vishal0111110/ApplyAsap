import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/diagnostic_item.dart';
import '../services/item_bank_service.dart';
import '../services/irt_engine.dart';
import '../services/diagnostics_service.dart';
import 'comprehensive_results_screen.dart';

class VoiceAssessmentScreen extends StatefulWidget {
  final String sessionId;
  final String userId;
  final Map<String, dynamic> metadata;

  const VoiceAssessmentScreen({
    Key? key,
    required this.sessionId,
    required this.userId,
    required this.metadata,
  }) : super(key: key);

  @override
  State<VoiceAssessmentScreen> createState() => _VoiceAssessmentScreenState();
}

class _VoiceAssessmentScreenState extends State<VoiceAssessmentScreen> {
  late ItemBankService _itemService;
  late DiagnosticsService _diagnosticsService;

  List<IRTResponse> responses = [];
  List<String> answeredItemIds = [];
  DiagnosticItem? currentItem;
  bool _isLoading = true;
  bool _assessmentComplete = false;
  ThetaEstimate? currentEstimate;

  // Recording state
  bool _isRecording = false;
  bool _hasRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;

  // Assessment progress
  int _currentStep = 0;
  int _maxSteps = 5; // Target number of voice tasks
  double _reliability = 0.0;

  // Analysis results
  Map<String, dynamic>? _analysis;
  Map<String, dynamic>? _basicResults;

  @override
  void initState() {
    super.initState();
    _itemService = ItemBankService();
    _diagnosticsService = DiagnosticsService();
    _initializeAssessment();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeAssessment() async {
    try {
      await _itemService.initializeItemBank();

      // Check if we have any Voice items
      List<DiagnosticItem> availableItems =
          _itemService.getItemsByType(ItemType.voice);
      if (availableItems.isEmpty) {
        throw Exception(
            'No Voice items available. Please check item bank initialization.');
      }

      _selectNextItem(0.0); // Start with neutral theta

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Voice Assessment initialization error: $e');
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to initialize voice assessment: $e');
    }
  }

  void _selectNextItem(double currentTheta) {
    final availableItems = _itemService.getItemsByType(ItemType.voice);
    currentItem = IRTEngine.selectNextItem(
      availableItems,
      responses,
      answeredItemIds,
    );

    if (currentItem == null) {
      _completeAssessment();
    }

    // Reset recording state
    _hasRecording = false;
    _recordingDuration = 0;
  }

  void _startRecording() {
    if (_isRecording) return;

    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });

    // Start timer
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration++;
      });

      // Auto-stop after max duration if not stopped manually
      int maxDuration = currentItem!.content['maxDurationSeconds'] ?? 30;
      if (_recordingDuration >= maxDuration) {
        _stopRecording();
      }
    });

    print('Voice recording started...');
    // In a real implementation, you would:
    // 1. Request microphone permissions if not granted
    // 2. Initialize audio recorder
    // 3. Start recording to a temporary file
  }

  void _stopRecording() {
    if (!_isRecording) return;

    _recordingTimer?.cancel();
    setState(() {
      _isRecording = false;
      _hasRecording = _recordingDuration > 0;
    });

    print('Voice recording stopped. Duration: $_recordingDuration seconds');
    // In a real implementation, you would:
    // 1. Stop the audio recorder
    // 2. Save recording file
    // 3. Optionally process audio features (prosody, clarity, etc.)
  }

  void _submitVoiceResponse() {
    if (currentItem == null) return;

    // For voice assessment, we'll evaluate based on recording quality and length
    // In a real implementation, this would use speech analysis libraries
    bool isCorrect;
    int minDuration = currentItem!.content['minDurationSeconds'] ?? 5;
    int qualityScore = _evaluateRecordingQuality();

    // Simple evaluation: good if recorded for min duration and quality > 50%
    isCorrect =
        _hasRecording && _recordingDuration >= minDuration && qualityScore > 50;

    final response = IRTResponse(
      item: currentItem!,
      isCorrect: isCorrect,
      responseTime: _recordingDuration * 1000, // Convert to milliseconds
    );

    responses.add(response);
    answeredItemIds.add(currentItem!.itemId);

    _currentStep++;

    // Update theta estimate
    currentEstimate = IRTEngine.estimateThetaEAP(responses);
    _reliability = IRTEngine.calculateReliability(responses);

    // Check if we should stop
    if (_currentStep >= _maxSteps ||
        IRTEngine.shouldStopTest(responses, 0.70)) {
      _completeAssessment();
    } else {
      _selectNextItem(currentEstimate!.theta);
    }

    setState(() {});
  }

  int _evaluateRecordingQuality() {
    // Simulate voice quality evaluation
    // In a real implementation, this would analyze:
    // - Audio volume levels
    // - Speech clarity
    // - Pronunciation accuracy
    // - Prosody features
    // - Keyword detection

    if (!_hasRecording) return 0;

    int quality = 70; // Base quality score
    if (_recordingDuration > 15)
      quality += 15; // Longer recordings tend to be better
    if (_recordingDuration < 5) quality -= 20; // Too short recordings are poor

    // Simulate random variation (would be based on actual analysis)
    quality += (DateTime.now().millisecondsSinceEpoch % 20) - 10;

    return quality.clamp(0, 100);
  }

  void _completeAssessment() async {
    _assessmentComplete = true;
    final finalEstimate = IRTEngine.estimateThetaEAP(responses);

    _basicResults = {
      'totalTasks': responses.length,
      'avgQuality': responses.fold<double>(
              0, (sum, r) => sum + (_evaluateRecordingQuality())) /
          responses.length,
      'avgDuration':
          responses.fold<double>(0, (sum, r) => sum + _recordingDuration) /
              responses.length,
      'theta': finalEstimate.theta,
      'reliability': finalEstimate.reliability,
    };

    // Save basic results
    await _saveAssessmentResults(finalEstimate);

    // Analyze results with AI
    _analysis = await _diagnosticsService.analyzeVoiceResults(
      userId: widget.userId,
      sessionId: widget.sessionId,
      responses: responses
          .map((r) => {
                'quality': _evaluateRecordingQuality(),
                'duration': _recordingDuration,
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
    int goodRecordings = responses.where((r) => r.isCorrect).length;

    print('Voice Assessment Results Saved:');
    print('Theta: ${estimate.theta.toStringAsFixed(3)}');
    print('Standard Error: ${estimate.standardError.toStringAsFixed(3)}');
    print('Reliability: ${(estimate.reliability * 100).toStringAsFixed(1)}%');
    print('Voice Tasks Completed: $totalItems');
    print('Good Recordings: $goodRecordings');
    print(
        'Recording Quality: ${(goodRecordings / totalItems * 100).toStringAsFixed(1)}%');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          centerTitle: true,
          title: const Text('Voice Assessment'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpinKitPouringHourGlass(
                color: Color(0xFF9C27B0),
                size: 120,
              ),
              SizedBox(height: 24),
              Text(
                'Initializing voice assessment...',
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

    if (_assessmentComplete) {
      return _buildCompletionScreen();
    }

    if (currentItem == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          centerTitle: true,
          title: const Text('Voice Assessment'),
        ),
        body: const Center(
          child: Text(
            'No voice tasks available',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text('Voice Assessment'),
        actions: [
          _buildProgressIndicator(),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildTaskHeader(),
                const SizedBox(height: 30),
                _buildPromptText(),
                const SizedBox(height: 40),
                _buildRecordingInterface(),
                const SizedBox(height: 30),
                _buildRecordingInfo(),
                const SizedBox(height: 40),
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
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
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Task ${_currentStep + 1} of $_maxSteps',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF9C27B0).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Voice Assessment',
                  style: TextStyle(
                    color: Color(0xFF9C27B0),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              currentItem!.category,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Colors.grey.shade400,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Reliability: ${(_reliability * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromptText() {
    final prompt = currentItem!.content['prompt'] as String;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
          Row(
            children: [
              Icon(
                Icons.record_voice_over_outlined,
                color: const Color(0xFF9C27B0),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Reading Prompt',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF9C27B0).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              prompt,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingInterface() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
          // Recording button
          GestureDetector(
            onTap: () {
              if (_isRecording) {
                _stopRecording();
              } else {
                _startRecording();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isRecording ? 140 : 120,
              height: _isRecording ? 140 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isRecording
                      ? [const Color(0xFFE53E3E), const Color(0xFFC53030)]
                      : [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isRecording
                        ? const Color(0xFFE53E3E).withOpacity(0.4)
                        : const Color(0xFF9C27B0).withOpacity(0.4),
                    spreadRadius: _isRecording ? 8 : 4,
                    blurRadius: _isRecording ? 16 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                size: _isRecording ? 70 : 60,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Recording status text
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 16,
              color: _isRecording ? const Color(0xFFE53E3E) : Colors.white70,
              fontWeight: FontWeight.w600,
            ),
            child: Text(
              _isRecording
                  ? 'Recording in Progress...'
                  : (_hasRecording
                      ? 'Recording Complete'
                      : 'Tap to Start Recording'),
            ),
          ),

          // Visual feedback during recording
          if (_isRecording) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildWaveformIndicator(0),
                const SizedBox(width: 2),
                _buildWaveformIndicator(1),
                const SizedBox(width: 2),
                _buildWaveformIndicator(2),
                const SizedBox(width: 2),
                _buildWaveformIndicator(3),
                const SizedBox(width: 2),
                _buildWaveformIndicator(4),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$_recordingDuration seconds',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFE53E3E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaveformIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: 4,
      height: 20 + (index % 2 == 0 ? 10 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE53E3E),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53E3E).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingInfo() {
    if (!_hasRecording && !_isRecording) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFF6B35).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: const Color(0xFFFF6B35),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Please record your voice before submitting',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFFFF6B35),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    int maxDuration = currentItem!.content['maxDurationSeconds'] ?? 30;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _hasRecording ? Icons.check_circle : Icons.access_time,
                color: const Color(0xFF4CAF50),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Recording Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Duration',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$_recordingDuration / $maxDuration seconds',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (_hasRecording) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quality',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_evaluateRecordingQuality()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    bool canSubmit = _hasRecording || _isRecording;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSubmit ? _submitVoiceResponse : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9C27B0),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          'Submit Voice Response',
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
                      const Color(0xFF9C27B0).withOpacity(0.2),
                      const Color(0xFF9C27B0).withOpacity(0.1)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFF9C27B0).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.mic_outlined,
                  color: Color(0xFF9C27B0),
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Voice Assessment Complete!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '$_currentStep voice assessment\ntasks completed',
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
                            assessmentType: 'voice',
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
                    backgroundColor: const Color(0xFF9C27B0),
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
}
