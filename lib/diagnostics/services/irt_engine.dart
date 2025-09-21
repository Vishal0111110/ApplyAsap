import 'dart:math';
import '../models/diagnostic_item.dart';

class IRTEngine {
  static const int maxNewtonIterations = 20;
  static const double newtonTolerance = 0.01;
  static const double priorVariance = 1.0;
  static const double maxTheta = 4.0;
  static const double minTheta = -4.0;

  // ===========================================
  // 2PL/3PL IRT MODEL FUNCTIONS
  // ===========================================

  /// Probability of correct response for 3PL model
  static double probabilityCorrect(double theta, DiagnosticItem item) {
    double expTerm = -item.discrimination * (theta - item.difficulty);
    double p = item.guessing + (1 - item.guessing) / (1 + exp(expTerm));
    return p.clamp(0.0, 1.0);
  }

  /// Derivative of probability with respect to theta
  static double probabilityDerivative(double theta, DiagnosticItem item) {
    double p = probabilityCorrect(theta, item);
    double discrimination = item.discrimination;
    return discrimination * p * (1 - p);
  }

  /// Second derivative of probability with respect to theta
  static double probabilitySecondDerivative(double theta, DiagnosticItem item) {
    double p = probabilityCorrect(theta, item);
    double discrimination = item.discrimination;
    return discrimination * discrimination * p * (1 - p) * (1 - 2 * p);
  }

  // ===========================================
  // FISHER INFORMATION FUNCTIONS
  // ===========================================

  /// Fisher information for single item
  static double fisherInformation(double theta, DiagnosticItem item) {
    double p = probabilityCorrect(theta, item);
    double q = 1 - p;
    double discrimination = item.discrimination;
    return discrimination * discrimination * p * q;
  }

  /// Total Fisher information for a set of items
  static double totalFisherInformation(
      List<DiagnosticItem> items, double theta) {
    return items.fold(0.0, (sum, item) => sum + fisherInformation(theta, item));
  }

  /// Expected posterior variance of theta
  static double posteriorVariance(List<DiagnosticItem> items, double theta) {
    double fisherInfo = totalFisherInformation(items, theta);
    double priorInfo = 1.0 / priorVariance;
    return 1.0 / (fisherInfo + priorInfo);
  }

  // ===========================================
  // THETA ESTIMATION ALGORITHMS
  // ===========================================

  /// Maximum Likelihood Estimation using Newton-Raphson method
  static ThetaEstimate? estimateThetaMLE(List<IRTResponse> responses) {
    if (responses.isEmpty) return null;

    // Start with mean item difficulty
    double theta =
        responses.map((r) => r.item.difficulty).reduce((a, b) => a + b) /
            responses.length;

    int iterations = 0;
    bool converged = false;

    while (iterations < maxNewtonIterations && !converged) {
      double firstDerivative = 0;
      double secondDerivative = 0;

      for (var response in responses) {
        double p = probabilityCorrect(theta, response.item);
        double score = response.isCorrect ? 1.0 : 0.0;

        firstDerivative += response.item.discrimination * (score - p);
        secondDerivative -= probabilitySecondDerivative(theta, response.item);
      }

      if (secondDerivative.abs() < 1e-10) break; // Prevent division by zero

      double delta = firstDerivative / secondDerivative;
      theta += delta;

      if (delta.abs() < newtonTolerance) {
        converged = true;
      }

      iterations++;
    }

    // Clamp theta to reasonable bounds
    theta = theta.clamp(minTheta, maxTheta);

    double variance =
        converged ? _calculateVariance(responses, theta) : double.infinity;

    return ThetaEstimate(
      theta: theta,
      variance: variance,
      iterations: iterations,
      converged: converged,
    );
  }

  /// Expected A Posteriori (EAP) estimation
  static ThetaEstimate estimateThetaEAP(List<IRTResponse> responses) {
    if (responses.isEmpty) {
      return ThetaEstimate(
        theta: 0.0,
        variance: priorVariance,
        iterations: 0,
        converged: true,
      );
    }

    // Gaussian quadrature points for approximation
    final quadraturePoints = [-2.0, -1.0, 0.0, 1.0, 2.0];
    final quadratureWeights = [0.0113, 0.2221, 0.5333, 0.2221, 0.0113];

    double numerator = 0.0;
    double denominator = 0.0;

    for (int i = 0; i < quadraturePoints.length; i++) {
      double theta = quadraturePoints[i];
      double weight = quadratureWeights[i];

      double likelihood = prior(theta) * _likelihood(responses, theta);
      numerator += theta * likelihood * weight;
      denominator += likelihood * weight;
    }

    double theta = numerator / denominator;
    double variance = _computeEAPVariance(theta, responses);

    return ThetaEstimate(
      theta: theta,
      variance: variance,
      iterations: 1,
      converged: true,
    );
  }

  // ===========================================
  // HELPER FUNCTIONS
  // ===========================================

  /// Normal prior for EAP estimation
  static double prior(double theta) {
    return (1 / sqrt(2 * pi * priorVariance)) *
        exp(-theta * theta / (2 * priorVariance));
  }

  /// Likelihood function for a theta
  static double _likelihood(List<IRTResponse> responses, double theta) {
    return responses.fold(1.0, (product, response) {
      double p = probabilityCorrect(theta, response.item);
      return product * (response.isCorrect ? p : (1 - p));
    });
  }

  /// Calculate variance for MLE estimate
  static double _calculateVariance(List<IRTResponse> responses, double theta) {
    double fisherInfo = 0.0;
    for (var response in responses) {
      double d = probabilityDerivative(theta, response.item);
      fisherInfo += d *
          d /
          probabilityCorrect(theta, response.item) /
          (1 - probabilityCorrect(theta, response.item));
    }
    return fisherInfo > 0 ? 1.0 / fisherInfo : double.infinity;
  }

  /// Compute EAP variance
  static double _computeEAPVariance(double theta, List<IRTResponse> responses) {
    double fisherInfo =
        totalFisherInformation(responses.map((r) => r.item).toList(), theta);
    return 1.0 / (fisherInfo + 1.0 / priorVariance);
  }

  // ===========================================
  // ADAPTIVE TESTING HELPERS
  // ===========================================

  /// Find optimal next item using Fisher Information maximization
  static DiagnosticItem? selectNextItem(
    List<DiagnosticItem> availableItems,
    List<IRTResponse> previousResponses,
    List<String> answeredItemIds,
  ) {
    if (availableItems.isEmpty) return null;

    // Get current theta estimate
    ThetaEstimate? currentEstimate = estimateThetaEAP(previousResponses);
    double theta = currentEstimate?.theta ?? 0.0;

    // Filter out already answered items
    List<DiagnosticItem> remainingItems = availableItems
        .where((item) => !answeredItemIds.contains(item.itemId))
        .toList();

    if (remainingItems.isEmpty) return null;

    // Find item with maximum Fisher Information
    DiagnosticItem? bestItem;
    double maxInfo = -1.0;

    for (var item in remainingItems) {
      double info = fisherInformation(theta, item);
      if (info > maxInfo) {
        maxInfo = info;
        bestItem = item;
      }
    }

    return bestItem;
  }

  /// Check if test should stop (reliability criteria)
  static bool shouldStopTest(
      List<IRTResponse> responses, double targetReliability) {
    if (responses.isEmpty) return false;

    ThetaEstimate estimate = estimateThetaEAP(responses);
    double reliability =
        1.0 - estimate.variance / (estimate.variance + priorVariance);

    return reliability >= targetReliability;
  }

  /// Calculate reliability coefficient
  static double calculateReliability(List<IRTResponse> responses) {
    if (responses.isEmpty) return 0.0;

    ThetaEstimate estimate = estimateThetaEAP(responses);
    return 1.0 - estimate.variance / (estimate.variance + priorVariance);
  }
}

class IRTResponse {
  final DiagnosticItem item;
  final bool isCorrect;
  final double responseTime;

  IRTResponse({
    required this.item,
    required this.isCorrect,
    required this.responseTime,
  });
}

class ThetaEstimate {
  final double theta;
  final double variance;
  final int iterations;
  final bool converged;

  ThetaEstimate({
    required this.theta,
    required this.variance,
    required this.iterations,
    required this.converged,
  });

  double get standardError => sqrt(variance);
  double get reliability => converged ? 1.0 - variance / (variance + 1.0) : 0.0;

  @override
  String toString() {
    return 'ThetaEstimate(theta: ${theta.toStringAsFixed(3)}, SE: ${standardError.toStringAsFixed(3)}, reliability: ${(reliability * 100).toStringAsFixed(1)}%)';
  }
}
