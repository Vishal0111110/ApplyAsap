import 'dart:math';

class DiagnosticItem {
  final String itemId;
  final String category;
  final ItemType type; // cat, sjt, voice
  final Map<String, dynamic> content; // Question text, options, etc.
  final Map<String, dynamic> parameters; // IRT parameters for CAT
  final double difficulty; // 'b' in 2PL model
  final double discrimination; // 'a' in 2PL model
  final double guessing; // 'c' in 3PL model, optional
  final List<String> correctResponses;
  final List<String> distractors;
  final Map<String, dynamic> metadata;
  final Map<String, int>? scoringMatrix; // For SJT Best-Worst scaling
  final bool active;
  final DateTime createdAt;
  final String authorId;

  DiagnosticItem({
    required this.itemId,
    required this.category,
    required this.type,
    required this.content,
    required this.parameters,
    required this.difficulty,
    required this.discrimination,
    this.guessing = 0.0,
    required this.correctResponses,
    required this.distractors,
    required this.metadata,
    this.scoringMatrix,
    required this.active,
    required this.createdAt,
    required this.authorId,
  });

  factory DiagnosticItem.fromMap(Map<dynamic, dynamic> data) {
    Map<String, int>? scoringMatrix;
    if (data['scoringMatrix'] != null) {
      scoringMatrix = Map<String, int>.from(data['scoringMatrix']);
    }

    return DiagnosticItem(
      itemId: data['itemId'] ?? '',
      category: data['category'] ?? '',
      type: ItemType.values[data['type']],
      content: data['content'] ?? {},
      parameters: data['parameters'] ?? {},
      difficulty: (data['difficulty'] as num).toDouble(),
      discrimination: (data['discrimination'] as num).toDouble(),
      guessing: (data['guessing'] as num?)?.toDouble() ?? 0.0,
      correctResponses: List<String>.from(data['correctResponses'] ?? []),
      distractors: List<String>.from(data['distractors'] ?? []),
      metadata: data['metadata'] ?? {},
      scoringMatrix: scoringMatrix,
      active: data['active'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      authorId: data['authorId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'category': category,
      'type': type.index,
      'content': content,
      'parameters': parameters,
      'difficulty': difficulty,
      'discrimination': discrimination,
      'guessing': guessing,
      'correctResponses': correctResponses,
      'distractors': distractors,
      'metadata': metadata,
      'scoringMatrix': scoringMatrix,
      'active': active,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'authorId': authorId,
    };
  }

  // 2PL IRT probability function
  double probabilityResponse(double theta) {
    return guessing +
        (1 - guessing) / (1 + exp(-discrimination * (theta - difficulty)));
  }

  // Fisher information function for item selection
  double fisherInformation(double theta) {
    double p = probabilityResponse(theta);
    double q = 1 - p;
    return discrimination * discrimination * p * q;
  }

  // Check if response is correct
  bool isCorrectResponse(String response) {
    return correctResponses.contains(response);
  }

  // Get the correct response set (for SJT Best-Worst)
  Set<String> getCorrectResponseSet() {
    return correctResponses.toSet();
  }
}

enum ItemType {
  cat, // Cognitive Ability Test
  sjt, // Situational Judgment Test
  voice, // Voice analysis task
}

class SJTScenario {
  final String scenarioId;
  final String scenarioText;
  final List<String> responseOptions;
  final Map<String, int> scoringMatrix; // For Best-Worst Scaling

  SJTScenario({
    required this.scenarioId,
    required this.scenarioText,
    required this.responseOptions,
    required this.scoringMatrix,
  });

  int scoreResponse(String bestChoice, String worstChoice) {
    String key = '${bestChoice}_$worstChoice';
    return scoringMatrix[key] ?? 0;
  }
}

class VoiceTask {
  final String taskId;
  final String promptText;
  final int maxDurationSeconds;
  final List<String> expectedKeywords;
  final Map<String, dynamic>
      featureRequirements; // Prosody, articulation features

  VoiceTask({
    required this.taskId,
    required this.promptText,
    required this.maxDurationSeconds,
    required this.expectedKeywords,
    required this.featureRequirements,
  });
}
