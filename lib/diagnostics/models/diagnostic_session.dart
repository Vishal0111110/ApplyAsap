import 'dart:math';

class DiagnosticSession {
  final String sessionId;
  final String userId;
  final String assessmentType; // 'cat', 'sjt', 'voice'
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, dynamic> metadata;
  final SessionStatus status;
  final Map<String, dynamic>? results;
  final int currentItemIndex;
  final List<String> itemIds;
  final double? thetaEstimate;

  DiagnosticSession({
    required this.sessionId,
    required this.userId,
    required this.assessmentType,
    required this.startTime,
    this.endTime,
    required this.metadata,
    required this.status,
    this.results,
    required this.currentItemIndex,
    required this.itemIds,
    this.thetaEstimate,
  });

  factory DiagnosticSession.fromMap(Map<dynamic, dynamic> data) {
    return DiagnosticSession(
      sessionId: data['sessionId'] ?? '',
      userId: data['userId'] ?? '',
      assessmentType: data['assessmentType'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(data['startTime'] ?? 0),
      endTime: data['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['endTime'])
          : null,
      metadata: data['metadata'] ?? {},
      status: SessionStatus.values[data['status'] ?? 0],
      results: data['results'],
      currentItemIndex: data['currentItemIndex'] ?? 0,
      itemIds: List<String>.from(data['itemIds'] ?? []),
      thetaEstimate: data['thetaEstimate']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'assessmentType': assessmentType,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'metadata': metadata,
      'status': status.index,
      'results': results,
      'currentItemIndex': currentItemIndex,
      'itemIds': itemIds,
      'thetaEstimate': thetaEstimate,
    };
  }
}

enum SessionStatus {
  started,
  in_progress,
  completed,
  suspended,
  terminated,
}

class ConfidenceInterval implements Comparable<ConfidenceInterval> {
  final double lower;
  final double upper;

  ConfidenceInterval({required this.lower, required this.upper});

  double get midpoint => (lower + upper) / 2.0;
  double get width => upper - lower;

  @override
  int compareTo(ConfidenceInterval other) => midpoint.compareTo(other.midpoint);

  bool contains(double value) => value >= lower && value <= upper;

  bool overlaps(ConfidenceInterval other) =>
      !(upper < other.lower || lower > other.upper);

  ConfidenceInterval combine(ConfidenceInterval other) {
    return ConfidenceInterval(
      lower: min(lower, other.lower),
      upper: max(upper, other.upper),
    );
  }
}

double calculateStandardError(int itemsResponded, double reliability) {
  if (reliability <= 0 || itemsResponded <= 1) return double.infinity;
  return sqrt((1 - reliability) / reliability) / sqrt(itemsResponded - 1);
}

ConfidenceInterval calculateThetaConfidence(double theta, double se) {
  return ConfidenceInterval(lower: theta - 1.96 * se, upper: theta + 1.96 * se);
}
