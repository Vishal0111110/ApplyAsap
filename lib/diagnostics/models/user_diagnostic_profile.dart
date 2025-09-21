class UserDiagnosticProfile {
  final String userId;
  final Map<String, double>
      traitScores; // e.g., {'cognitive_ability': 2.3, 'emotional_intelligence': 1.8}
  final Map<String, double> standardErrors;
  final List<AssessmentResult> assessmentHistory;
  final Map<String, dynamic>
      voiceFeatures; // Extracted prosody and articulation features
  final Map<String, dynamic> metadata;
  final DateTime lastAssessment;
  final bool privacyConsent;
  final bool dataSharingConsent;
  final DateTime consentDate;

  UserDiagnosticProfile({
    required this.userId,
    required this.traitScores,
    required this.standardErrors,
    required this.assessmentHistory,
    required this.voiceFeatures,
    required this.metadata,
    required this.lastAssessment,
    required this.privacyConsent,
    required this.dataSharingConsent,
    required this.consentDate,
  });

  factory UserDiagnosticProfile.fromMap(Map<dynamic, dynamic> data) {
    return UserDiagnosticProfile(
      userId: data['userId'] ?? '',
      traitScores: Map<String, double>.from(data['traitScores'] ?? {}),
      standardErrors: Map<String, double>.from(data['standardErrors'] ?? {}),
      assessmentHistory: List<dynamic>.from(data['assessmentHistory'] ?? [])
          .map((e) => AssessmentResult.fromMap(e))
          .toList(),
      voiceFeatures: data['voiceFeatures'] ?? {},
      metadata: data['metadata'] ?? {},
      lastAssessment:
          DateTime.fromMillisecondsSinceEpoch(data['lastAssessment'] ?? 0),
      privacyConsent: data['privacyConsent'] ?? false,
      dataSharingConsent: data['dataSharingConsent'] ?? false,
      consentDate:
          DateTime.fromMillisecondsSinceEpoch(data['consentDate'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'traitScores': traitScores,
      'standardErrors': standardErrors,
      'assessmentHistory': assessmentHistory.map((e) => e.toMap()).toList(),
      'voiceFeatures': voiceFeatures,
      'metadata': metadata,
      'lastAssessment': lastAssessment.millisecondsSinceEpoch,
      'privacyConsent': privacyConsent,
      'dataSharingConsent': dataSharingConsent,
      'consentDate': consentDate.millisecondsSinceEpoch,
    };
  }

  // Get the most recent score for a trait
  double? getTraitScore(String trait) {
    return traitScores[trait];
  }

  // Check if trait score is statistically significant
  bool isTraitScoreSignificant(String trait, {double confidence = 1.96}) {
    double? score = traitScores[trait];
    double? se = standardErrors[trait];
    if (score == null || se == null) return false;
    return (score.abs() / se) > confidence;
  }

  // Get reliability for all traits
  Map<String, double> getReliabilities() {
    Map<String, double> reliabilities = {};
    traitScores.forEach((trait, score) {
      double? se = standardErrors[trait];
      if (se != null && se > 0) {
        double reliability = 1 - (se * se / (score * score + se * se));
        reliabilities[trait] = reliability.clamp(0.0, 1.0);
      }
    });
    return reliabilities;
  }

  // Update consent status
  UserDiagnosticProfile updateConsents({
    bool? privacy,
    bool? dataSharing,
  }) {
    return UserDiagnosticProfile(
      userId: userId,
      traitScores: traitScores,
      standardErrors: standardErrors,
      assessmentHistory: assessmentHistory,
      voiceFeatures: voiceFeatures,
      metadata: metadata,
      lastAssessment: lastAssessment,
      privacyConsent: privacy ?? privacyConsent,
      dataSharingConsent: dataSharing ?? dataSharingConsent,
      consentDate: (privacy ?? privacyConsent) != privacyConsent ||
              (dataSharing ?? dataSharingConsent) != dataSharingConsent
          ? DateTime.now()
          : consentDate,
    );
  }
}

class AssessmentResult {
  final String sessionId;
  final String assessmentType;
  final DateTime completedAt;
  final Map<String, double> subscaleScores;
  final Map<String, double> subscaleErrors;
  final double totalScore;
  final double reliability;
  final int itemsResponded;
  final Map<String, dynamic> additionalMetrics;

  AssessmentResult({
    required this.sessionId,
    required this.assessmentType,
    required this.completedAt,
    required this.subscaleScores,
    required this.subscaleErrors,
    required this.totalScore,
    required this.reliability,
    required this.itemsResponded,
    required this.additionalMetrics,
  });

  factory AssessmentResult.fromMap(Map<String, dynamic> data) {
    return AssessmentResult(
      sessionId: data['sessionId'] ?? '',
      assessmentType: data['assessmentType'] ?? '',
      completedAt: DateTime.parse(data['completedAt']),
      subscaleScores: Map<String, double>.from(data['subscaleScores'] ?? {}),
      subscaleErrors: Map<String, double>.from(data['subscaleErrors'] ?? {}),
      totalScore: (data['totalScore'] as num).toDouble(),
      reliability: (data['reliability'] as num).toDouble(),
      itemsResponded: data['itemsResponded'] ?? 0,
      additionalMetrics: data['additionalMetrics'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'assessmentType': assessmentType,
      'completedAt': completedAt.toIso8601String(),
      'subscaleScores': subscaleScores,
      'subscaleErrors': subscaleErrors,
      'totalScore': totalScore,
      'reliability': reliability,
      'itemsResponded': itemsResponded,
      'additionalMetrics': additionalMetrics,
    };
  }

  // Check if assessment is reliable
  bool isReliable({double minimumReliability = 0.7}) {
    return reliability > minimumReliability && itemsResponded >= 10;
  }
}

class DiagnosticResponse {
  final String responseId;
  final String sessionId;
  final String itemId;
  final String userId;
  final Map<String, dynamic> response; // Answer, timing, confidence, etc.
  final int responseTimeMs;
  final DateTime timestamp;
  final String clientFingerprint; // Anti-cheat measure

  DiagnosticResponse({
    required this.responseId,
    required this.sessionId,
    required this.itemId,
    required this.userId,
    required this.response,
    required this.responseTimeMs,
    required this.timestamp,
    required this.clientFingerprint,
  });

  factory DiagnosticResponse.fromMap(Map<String, dynamic> data) {
    return DiagnosticResponse(
      responseId: data['responseId'] ?? '',
      sessionId: data['sessionId'] ?? '',
      itemId: data['itemId'] ?? '',
      userId: data['userId'] ?? '',
      response: data['response'] ?? {},
      responseTimeMs: data['responseTimeMs'] ?? 0,
      timestamp: DateTime.parse(data['timestamp']),
      clientFingerprint: data['clientFingerprint'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'responseId': responseId,
      'sessionId': sessionId,
      'itemId': itemId,
      'userId': userId,
      'response': response,
      'responseTimeMs': responseTimeMs,
      'timestamp': timestamp.toIso8601String(),
      'clientFingerprint': clientFingerprint,
    };
  }

  // Detect suspicious response patterns
  bool isSuspiciousResponse() {
    // Response time suspiciously fast (< 500ms for CAT items)
    if (responseTimeMs < 500) return true;
    // Response time suspiciously slow (> 5 min)
    if (responseTimeMs > 300000) return true;
    return false;
  }
}
