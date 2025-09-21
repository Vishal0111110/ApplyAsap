import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class EnrollmentService {
  /// Fetches user's current coins balance from database (same logic as GamificationService)
  Future<int> getUserCoins() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 0;

    try {
      // Use same Firebase path as GamificationService (gamification/userStats/)
      // Debug: Log user ID
      await Future.delayed(
          Duration(milliseconds: 100)); // Avoid rapid-fire reads
      final userRef = FirebaseDatabase.instance
          .ref()
          .child('gamification')
          .child('userStats')
          .child(userId);
      final DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map;
        final coins = data['totalPoints'] != null
            ? int.parse(data['totalPoints'].toString())
            : 0;

        // Debug: Log the fetched data
        print(
            'getUserCoins: Found user data in gamification/userStats/: $data');
        print('getUserCoins: Coins value: $coins');

        return coins;
      } else {
        // Create user with 0 points if not exists
        await userRef.set({'totalPoints': 0, 'level': 1});
        print(
            'getUserCoins: Created new user with 0 coins in gamification/userStats/');
        return 0;
      }
    } catch (e) {
      print('Error fetching user coins: $e');
      return 0;
    }
  }

  /// Updates user's coins balance after payment
  Future<void> updateUserCoins(int newBalance) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Get current stats first
      final userRef = FirebaseDatabase.instance
          .ref()
          .child('gamification')
          .child('userStats')
          .child(userId);
      final snapshot = await userRef.get();

      Map<String, dynamic> stats = {};
      if (snapshot.exists) {
        stats = Map<String, dynamic>.from(snapshot.value as Map);
      }

      // Update totalPoints
      stats['totalPoints'] = newBalance;
      stats['level'] = _calculateLevel(newBalance);

      await userRef.set(stats);
    } catch (e) {
      print('Error updating user coins: $e');
      rethrow;
    }
  }

  int _calculateLevel(int points) {
    if (points < 100) return 1;
    if (points < 300) return 2;
    if (points < 600) return 3;
    if (points < 1000) return 4;
    if (points < 1500) return 5;
    if (points < 2200) return 6;
    return 7;
  }

  /// Deducts coins from user's balance
  Future<bool> deductCoins(int amount) async {
    final currentCoins = await getUserCoins();
    if (currentCoins < amount) {
      return false; // Insufficient coins
    }

    final newBalance = currentCoins - amount;
    await updateUserCoins(newBalance);
    return true;
  }

  /// Stores transaction record for coin deduction
  Future<void> storeCoinTransaction({
    required String courseId,
    required String courseName,
    required Map<String, dynamic> courseData,
    required int coinsUsed,
    required int amount,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final transactionId = _generateTransactionId();

    final transactionData = {
      'transactionId': transactionId,
      'courseId': courseId,
      'courseName': courseName,
      'courseData': courseData,
      'coinsUsed': coinsUsed,
      'totalAmount': amount,
      'paymentMethod': 'coins_partial',
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'transactionType': 'course_enrollment_partial',
      'remainingAmount': amount - coinsUsed,
    };

    // Store in transactions node
    await FirebaseDatabase.instance
        .ref()
        .child('transactions')
        .child(transactionId)
        .set(transactionData);

    // Store in user-specific transactions
    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(userId)
        .child('transactions')
        .child(transactionId)
        .set(transactionData);
  }

  /// Stores enrollment data after successful payment
  Future<void> storeEnrollment({
    required String courseId,
    required String courseName,
    required Map<String, dynamic> courseData,
    required String paymentId,
    required int coinsUsed,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final enrollmentData = {
      'courseId': courseId,
      'courseName': courseName,
      'courseData': courseData,
      'paymentId': paymentId,
      'coinsUsed': coinsUsed,
      'enrollmentDate': DateTime.now().toIso8601String(),
      'status': 'active',
      'progress': 0,
      'completedLectures': [],
    };

    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(userId)
        .child('enrollments')
        .child(courseId)
        .set(enrollmentData);
  }

  /// Adds coins to user's balance (for rewards, etc.)
  Future<void> addCoins(int amount) async {
    final currentCoins = await getUserCoins();
    final newBalance = currentCoins + amount;
    await updateUserCoins(newBalance);
  }

  /// Records coin rewards transaction
  Future<void> recordCoinReward({
    required int amount,
    required String reason,
    required String source,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final transactionId = _generateTransactionId();

    final rewardData = {
      'transactionId': transactionId,
      'amount': amount,
      'reason': reason,
      'source': source,
      'type': 'reward',
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Store in rewards transactions
    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(userId)
        .child('coinTransactions')
        .child(transactionId)
        .set(rewardData);
  }

  String _generateTransactionId() {
    final now = DateTime.now();
    return 'TXN${now.millisecondsSinceEpoch}';
  }

  Future<bool> isEnrolled(String courseId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('enrollments')
          .child(courseId)
          .get();
      return snapshot.exists;
    } catch (e) {
      print('Error checking enrollment status: $e');
      return false;
    }
  }

  /// Marks a lecture as completed in the user's enrollment
  Future<void> markLectureCompleted(String courseId, int lectureIndex) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final enrollmentRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('enrollments')
          .child(courseId);

      // Get current enrollment data
      final snapshot = await enrollmentRef.get();
      if (!snapshot.exists) return;

      Map<String, dynamic> enrollmentData =
          Map<String, dynamic>.from(snapshot.value as Map);
      List<dynamic> completedLectures =
          enrollmentData['completedLectures'] ?? [];

      // Add lecture to completed list if not already there
      if (!completedLectures.contains(lectureIndex)) {
        completedLectures.add(lectureIndex);

        // Update progress percentage
        final totalLectures =
            enrollmentData['courseData']?['lectures']?.length ?? 1;
        final progressPercentage =
            (completedLectures.length / totalLectures) * 100;

        // Update enrollment data
        enrollmentData['completedLectures'] = completedLectures;
        enrollmentData['progress'] = progressPercentage;
        enrollmentData['lastUpdated'] = DateTime.now().toIso8601String();

        await enrollmentRef.set(enrollmentData);

        // Also store individual lecture completion data
        final lectureRef =
            enrollmentRef.child('lectures').child(lectureIndex.toString());
        await lectureRef.set({
          'index': lectureIndex,
          'completed': true,
          'completionDate': DateTime.now().toIso8601String(),
          'title': enrollmentData['courseData']?['lectures']?[lectureIndex] ??
              'Unknown Lecture',
        });
      }
    } catch (e) {
      print('Error marking lecture completed: $e');
      rethrow;
    }
  }

  /// Gets completion status of a specific lecture
  Future<Map<String, dynamic>> getLectureProgress(
      String courseId, int lectureIndex) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return {'completed': false};

    try {
      final lectureRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('enrollments')
          .child(courseId)
          .child('lectures')
          .child(lectureIndex.toString());

      final snapshot = await lectureRef.get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return {'completed': false};
    } catch (e) {
      print('Error getting lecture progress: $e');
      return {'completed': false};
    }
  }

  /// Gets overall course progress including completed lectures count and percentage
  Future<Map<String, dynamic>> getCourseProgress(String courseId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return {'completedLectures': 0, 'progress': 0};

    try {
      final enrollmentRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('enrollments')
          .child(courseId);

      final snapshot = await enrollmentRef.get();
      if (!snapshot.exists) return {'completedLectures': 0, 'progress': 0};

      final data = snapshot.value as Map;
      final completedLectures = data['completedLectures'] ?? [];
      final progress = data['progress'] ?? 0;

      return {
        'completedLectures': completedLectures.length,
        'progress': progress,
        'totalLectures': data['courseData']?['lectures']?.length ?? 1,
        'lastUpdated': data['lastUpdated'],
      };
    } catch (e) {
      print('Error getting course progress: $e');
      return {'completedLectures': 0, 'progress': 0};
    }
  }
}
