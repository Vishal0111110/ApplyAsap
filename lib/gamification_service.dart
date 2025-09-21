import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:reward_popup/reward_popup.dart' as reward_popup;
import 'package:flutter/material.dart';
import 'notification_service.dart';

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Point values for different activities
  static const int POINTS_SURVEY_COMPLETION = 100;
  static const int POINTS_INTERVIEW_COMPLETION = 30;
  static const int POINTS_COURSE_COMPLETION = 20;
  static const int POINTS_DAILY_LOGIN = 10;
  static const int POINTS_COMMUNITY_POST = 5;
  static const int POINTS_HIGH_SCORE = 25; // For interview scores >8/10
  static const int POINTS_FIRST_SURVEY = 100;
  static const int POINTS_STREAK_BONUS = 15;

  // Challenge system
  static const Map<String, Map<String, dynamic>> WEEKLY_CHALLENGES = {
    'questions_completed': {
      'title': 'Code Master',
      'description': 'Complete 5 coding questions this week',
      'target': 5,
      'reward': 100,
      'type': 'questions_completed'
    },
    'interview_sessions': {
      'title': 'Interview Warrior',
      'description': 'Complete 3 interview sessions this week',
      'target': 3,
      'reward': 75,
      'type': 'interviews_completed'
    },
    'daily_logins': {
      'title': 'Consistent Learner',
      'description': 'Login for 5 consecutive days',
      'target': 5,
      'reward': 30,
      'type': 'daily_logins'
    },
    'courses_started': {
      'title': 'Knowledge Seeker',
      'description': 'Start 3 new courses this week',
      'target': 3,
      'reward': 40,
      'type': 'courses_started'
    },
  };

  static const Map<String, Map<String, dynamic>> MONTHLY_CHALLENGES = {
    'monthly_practice': {
      'title': 'Monthly Scholar',
      'description': 'Answer 100 practice questions this month',
      'target': 100,
      'reward': 200,
      'type': 'questions_completed'
    },
    'monthly_interviews': {
      'title': 'Interview Champion',
      'description': 'Complete 10 interview sessions this month',
      'target': 10,
      'reward': 150,
      'type': 'interviews_completed'
    },
    'skill_mastery': {
      'title': 'Skill Master',
      'description': 'Achieve 90%+ in 5 interviews this month',
      'target': 5,
      'reward': 100,
      'type': 'high_scores'
    },
  };

  Future<void> awardPoints(String userId, int points, String reason,
      {String? activityId,
      BuildContext? context,
      bool showPopup = false}) async {
    try {
      final userStatsRef =
          _db.child('gamification').child('userStats').child(userId);

      // Get current stats
      final snapshot = await userStatsRef.get();
      Map<String, dynamic> currentStats = {};
      if (snapshot.exists) {
        currentStats = Map<String, dynamic>.from(snapshot.value as Map);
      }

      // Update points
      int currentPoints = currentStats['totalPoints'] ?? 0;
      int newPoints = currentPoints + points;
      currentStats['totalPoints'] = newPoints;

      // Update level
      currentStats['level'] = _calculateLevel(newPoints);

      // Add to point history
      List<dynamic> pointHistory =
          List.from(currentStats['pointHistory'] ?? []);
      pointHistory.add({
        'points': points,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
        'activityId': activityId,
      });
      currentStats['pointHistory'] = pointHistory;

      // Update stats
      await userStatsRef.set(currentStats);

      // Check for achievements
      await _checkAchievements(userId, currentStats);

      // Update leaderboards
      await _updateLeaderboards(userId, newPoints);

      // Show reward popup if requested
      if (showPopup && context != null) {
        await showRewardPopup(context, points, reason);
      }
    } catch (e) {
      // Silent error handling for production
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

  Future<void> _checkAchievements(
      String userId, Map<String, dynamic> stats) async {
    final achievementsRef =
        _db.child('gamification').child('achievements').child(userId);

    // Get current achievements
    final snapshot = await achievementsRef.get();
    Map<String, dynamic> achievements = {};
    if (snapshot.exists) {
      achievements = Map<String, dynamic>.from(snapshot.value as Map);
    }

    // Check various achievement conditions
    int totalPoints = stats['totalPoints'] ?? 0;
    int surveysCompleted = stats['surveysCompleted'] ?? 0;
    int interviewsCompleted = stats['interviewsCompleted'] ?? 0;
    int coursesCompleted = stats['coursesCompleted'] ?? 0;
    int highScores = stats['highScores'] ?? 0;
    int questionsCompleted = stats['questionsCompleted'] ?? 0;

    // First Survey Achievement
    if (surveysCompleted >= 1 && !achievements.containsKey('firstSurvey')) {
      await _unlockAchievement(userId, 'firstSurvey', 'First Steps',
          'Completed your first career survey');
    }

    // Interview Master Achievement
    if (interviewsCompleted >= 10 &&
        !achievements.containsKey('interviewMaster')) {
      await _unlockAchievement(userId, 'interviewMaster', 'Interview Master',
          'Completed 10 interviews');
    }

    // Course Champion Achievement
    if (coursesCompleted >= 5 && !achievements.containsKey('courseChampion')) {
      await _unlockAchievement(
          userId, 'courseChampion', 'Course Champion', 'Completed 5 courses');
    }

    // High Scorer Achievement
    if (highScores >= 5 && !achievements.containsKey('highScorer')) {
      await _unlockAchievement(userId, 'highScorer', 'High Scorer',
          'Achieved 9/10+ in 5 interviews');
    }

    // Question completion achievements
    if (questionsCompleted >= 1 && !achievements.containsKey('firstQuestion')) {
      await _unlockAchievement(userId, 'firstQuestion', 'First Code',
          'Completed your first coding question');
    }
    if (questionsCompleted >= 5 &&
        !achievements.containsKey('codeApprentice')) {
      await _unlockAchievement(userId, 'codeApprentice', 'Code Apprentice',
          'Completed 5 coding questions');
    }
    if (questionsCompleted >= 10 && !achievements.containsKey('codeWarrior')) {
      await _unlockAchievement(userId, 'codeWarrior', 'Code Warrior',
          'Completed 10 coding questions');
    }
    if (questionsCompleted >= 25 && !achievements.containsKey('codeMaster')) {
      await _unlockAchievement(
          userId, 'codeMaster', 'Code Master', 'Completed 25 coding questions');
    }

    // Level-based achievements
    int level = stats['level'] ?? 1;
    if (level >= 3 && !achievements.containsKey('level3')) {
      await _unlockAchievement(
          userId, 'level3', 'Apprentice', 'Reached Level 3');
    }
    if (level >= 5 && !achievements.containsKey('level5')) {
      await _unlockAchievement(userId, 'level5', 'Expert', 'Reached Level 5');
    }
  }

  Future<void> _unlockAchievement(String userId, String achievementId,
      String name, String description) async {
    final achievementsRef =
        _db.child('gamification').child('achievements').child(userId);

    await achievementsRef.child(achievementId).set({
      'name': name,
      'description': description,
      'unlockedAt': DateTime.now().toIso8601String(),
      'icon': _getAchievementIcon(achievementId),
    });

    // Award bonus points for achievement
    await awardPoints(userId, 50, 'Achievement Unlocked: $name',
        activityId: achievementId);
  }

  String _getAchievementIcon(String achievementId) {
    switch (achievementId) {
      case 'firstSurvey':
        return 'assets/icons/achievement_first.png';
      case 'interviewMaster':
        return 'assets/icons/achievement_interview.png';
      case 'courseChampion':
        return 'assets/icons/achievement_course.png';
      case 'highScorer':
        return 'assets/icons/achievement_score.png';
      case 'firstQuestion':
        return 'assets/icons/achievement_first_code.png';
      case 'codeApprentice':
        return 'assets/icons/achievement_code_apprentice.png';
      case 'codeWarrior':
        return 'assets/icons/achievement_code_warrior.png';
      case 'codeMaster':
        return 'assets/icons/achievement_code_master.png';
      case 'level3':
        return 'assets/icons/achievement_level3.png';
      case 'level5':
        return 'assets/icons/achievement_level5.png';
      default:
        return 'assets/icons/achievement_default.png';
    }
  }

  Future<void> _updateLeaderboards(String userId, int newPoints) async {
    final leaderboardRef =
        _db.child('gamification').child('leaderboards').child('points');

    // Get user display name
    final user = FirebaseAuth.instance.currentUser;
    String displayName = user?.displayName ?? 'Anonymous User';

    await leaderboardRef.child(userId).set({
      'userId': userId,
      'displayName': displayName,
      'points': newPoints,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getUserStats(String userId) async {
    try {
      final snapshot = await _db
          .child('gamification')
          .child('userStats')
          .child(userId)
          .get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      print('Error getting user stats: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getLeaderboards({int limit = 50}) async {
    try {
      print('🔄 Fetching global leaderboard data...');

      final snapshot = await _db
          .child('gamification')
          .child('leaderboards')
          .child('points')
          .orderByChild('points')
          .limitToLast(limit)
          .get();

      List<Map<String, dynamic>> leaderboard = [];

      if (snapshot.exists) {
        final data = snapshot.value as Map;
        data.forEach((key, value) {
          leaderboard.add(Map<String, dynamic>.from(value));
        });
        print('📊 Found ${leaderboard.length} users in leaderboard');

        // Always include sample users to ensure Sarath and Ryan Gabriel are present
        final sampleUsers = _generateSampleLeaderboard();
        for (var sampleUser in sampleUsers) {
          // Only add if not already in leaderboard
          if (!leaderboard
              .any((user) => user['userId'] == sampleUser['userId'])) {
            leaderboard.add(sampleUser);
          }
        }
      } else {
        print('⚠️ No leaderboard data found in database, using sample data');
        leaderboard = _generateSampleLeaderboard();
      }

      // Add current user with actual stats (same logic as friends leaderboard)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print('👤 Adding current user to leaderboard');
        final userStats = await getUserStats(currentUser.uid);
        if (userStats != null) {
          final userPoints = userStats['totalPoints'] ?? 0;
          final userLevel = userStats['level'] ?? 1;
          final displayName = currentUser.displayName ?? 'You';

          // Remove any existing entry for current user
          leaderboard.removeWhere((user) => user['userId'] == currentUser.uid);

          // Add current user with actual stats
          leaderboard.add({
            'userId': currentUser.uid,
            'displayName': displayName,
            'points': userPoints,
            'level': userLevel,
            'lastUpdated': DateTime.now().toIso8601String(),
          });

          print('✅ Added current user: $displayName with $userPoints points');
        } else {
          print('❌ Could not fetch current user stats');
        }
      }

      // Sort by points descending
      leaderboard
          .sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

      // Return top limit entries
      if (leaderboard.length > limit) {
        leaderboard = leaderboard.take(limit).toList();
      }

      print('🏆 Returning ${leaderboard.length} leaderboard entries');
      return leaderboard;
    } catch (e) {
      print('❌ Error getting leaderboards: $e');
      // Return sample data as fallback with current user added
      final sampleLeaderboard = _generateSampleLeaderboard();

      // Add current user with actual stats (same logic as friends leaderboard)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print('👤 Adding current user to sample leaderboard');
        try {
          final userStats = await getUserStats(currentUser.uid);
          if (userStats != null) {
            final userPoints = userStats['totalPoints'] ?? 0;
            final userLevel = userStats['level'] ?? 1;
            final displayName = currentUser.displayName ?? 'You';

            // Remove any existing entry for current user
            sampleLeaderboard
                .removeWhere((user) => user['userId'] == currentUser.uid);

            // Add current user with actual stats
            sampleLeaderboard.add({
              'userId': currentUser.uid,
              'displayName': displayName,
              'points': userPoints,
              'level': userLevel,
              'lastUpdated': DateTime.now().toIso8601String(),
            });

            print(
                '✅ Added current user to sample leaderboard: $displayName with $userPoints points');
          }
        } catch (statsError) {
          print(
              '❌ Could not fetch current user stats for sample leaderboard: $statsError');
        }
      }

      // Sort by points descending
      sampleLeaderboard
          .sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

      return sampleLeaderboard;
    }
  }

  List<Map<String, dynamic>> _generateSampleLeaderboard() {
    final sampleUsers = [
      {
        'userId': 'sample1',
        'displayName': 'Gajanan',
        'points': 1250,
        'level': 5
      },
      {
        'userId': 'sample2',
        'displayName': 'Qamar Sayyad',
        'points': 980,
        'level': 4
      },
      {
        'userId': 'sample3',
        'displayName': 'Kharishma Shaik',
        'points': 750,
        'level': 3
      },
      {
        'userId': 'sample4',
        'displayName': 'Murugam Thilak',
        'points': 620,
        'level': 3
      },
      {
        'userId': 'sample5',
        'displayName': 'Srimanth Reddy',
        'points': 450,
        'level': 2
      },
      {'userId': 'sample6', 'displayName': 'Sarath', 'points': 320, 'level': 2},
      {
        'userId': 'sample7',
        'displayName': 'Ryan Gabriel',
        'points': 180,
        'level': 1
      },
    ];

    // Note: Current user will be added separately in getLeaderboards() with actual points
    return sampleUsers;
  }

  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    try {
      final snapshot = await _db
          .child('gamification')
          .child('achievements')
          .child(userId)
          .get();
      if (snapshot.exists) {
        List<Map<String, dynamic>> achievements = [];
        final data = snapshot.value as Map;

        data.forEach((key, value) {
          achievements.add({
            'id': key,
            ...Map<String, dynamic>.from(value),
          });
        });

        return achievements;
      }
    } catch (e) {
      print('Error getting user achievements: $e');
    }
    return [];
  }

  Future<void> updateActivityStats(String userId, String activityType) async {
    try {
      final userStatsRef =
          _db.child('gamification').child('userStats').child(userId);
      final snapshot = await userStatsRef.get();

      Map<String, dynamic> stats = {};
      if (snapshot.exists) {
        stats = Map<String, dynamic>.from(snapshot.value as Map);
      }

      // Update activity counters
      switch (activityType) {
        case 'survey':
          stats['surveysCompleted'] = (stats['surveysCompleted'] ?? 0) + 1;
          break;
        case 'interview':
          stats['interviewsCompleted'] =
              (stats['interviewsCompleted'] ?? 0) + 1;
          break;
        case 'course':
          stats['coursesCompleted'] = (stats['coursesCompleted'] ?? 0) + 1;
          break;
        case 'highScore':
          stats['highScores'] = (stats['highScores'] ?? 0) + 1;
          break;
        case 'question_completed':
          stats['questionsCompleted'] = (stats['questionsCompleted'] ?? 0) + 1;
          break;
      }

      await userStatsRef.set(stats);

      // Update friend challenge progress if applicable
      await _updateFriendChallengeProgressForActivity(userId, activityType);
    } catch (e) {
      print('Error updating activity stats: $e');
    }
  }

  Future<void> _updateFriendChallengeProgressForActivity(
      String userId, String activityType) async {
    try {
      // Map activity types to challenge types
      String? challengeType;
      switch (activityType) {
        case 'question_completed':
          challengeType = 'questions_completed';
          break;
        case 'interview':
          challengeType = 'interviews_completed';
          break;
        case 'course':
          challengeType = 'courses_started';
          break;
      }

      if (challengeType != null) {
        // Get user's active friend challenges
        final userChallenges = await getUserFriendChallenges(userId);
        final activeChallenges = userChallenges
            .where((challenge) => challenge['status'] == 'active')
            .toList();

        // Update progress for each active challenge of the matching type
        for (var challenge in activeChallenges) {
          if (challenge['type'] == challengeType) {
            await updateFriendChallengeProgress(
                challenge['challengeId'], userId, 1);
          }
        }
      }
    } catch (e) {
      print('Error updating friend challenge progress for activity: $e');
    }
  }

  Future<void> checkAndAwardDailyLogin(String userId,
      {BuildContext? context, bool showPopup = false}) async {
    try {
      final userStatsRef =
          _db.child('gamification').child('userStats').child(userId);
      final snapshot = await userStatsRef.get();

      Map<String, dynamic> stats = {};
      if (snapshot.exists) {
        stats = Map<String, dynamic>.from(snapshot.value as Map);
      }

      String today = DateTime.now().toIso8601String().split('T')[0];
      String? lastDailyLoginAward = stats['lastDailyLoginAward'];

      // Check if daily login was already awarded today using dedicated field
      bool dailyLoginAlreadyAwarded = lastDailyLoginAward == today;

      // Award daily login if not already awarded today
      bool shouldAward = !dailyLoginAlreadyAwarded;

      if (shouldAward) {
        // Update the last daily login award first to prevent double awarding
        stats['lastDailyLoginAward'] = today;
        await userStatsRef.child('lastDailyLoginAward').set(today);

        // Award daily login points
        await awardPoints(userId, POINTS_DAILY_LOGIN, 'Daily Login');

        // Update streak
        await _updateStreak(userId, stats['lastLoginDate']);

        // Update last login date
        stats['lastLoginDate'] = today;
        await userStatsRef.child('lastLoginDate').set(today);

        // Show popup if requested
        if (showPopup && context != null) {
          await showRewardPopup(context, POINTS_DAILY_LOGIN, 'Daily Login');
        }
      }
    } catch (e) {
      // Silent error handling for production
    }
  }

  Future<void> _updateStreak(String userId, String? lastLoginDate) async {
    try {
      final userStatsRef =
          _db.child('gamification').child('userStats').child(userId);
      final snapshot = await userStatsRef.get();

      Map<String, dynamic> stats = {};
      if (snapshot.exists) {
        stats = Map<String, dynamic>.from(snapshot.value as Map);
      }

      int currentStreak = stats['currentStreak'] ?? 0;
      int longestStreak = stats['longestStreak'] ?? 0;

      if (lastLoginDate != null) {
        DateTime lastDate = DateTime.parse(lastLoginDate);
        DateTime today = DateTime.now();
        int daysDifference = today.difference(lastDate).inDays;

        if (daysDifference == 1) {
          // Consecutive day
          currentStreak++;
          if (currentStreak > longestStreak) {
            longestStreak = currentStreak;
          }
        } else if (daysDifference > 1) {
          // Streak broken
          currentStreak = 1;
        }
      } else {
        // First login
        currentStreak = 1;
        longestStreak = 1;
      }

      stats['currentStreak'] = currentStreak;
      stats['longestStreak'] = longestStreak;
      await userStatsRef.set(stats);

      // Award streak bonus if applicable
      if (currentStreak >= 7) {
        await awardPoints(userId, POINTS_STREAK_BONUS, '7-Day Streak Bonus');
      }
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  // Method to show reward popup using the existing reward_popup package
  static Future<void> showRewardPopup(
      BuildContext context, int coinsAwarded, String reason) async {
    print('🎉 Showing reward popup for $coinsAwarded coins: $reason');

    // Ensure the context is still valid
    if (!context.mounted) {
      print('❌ Context is not mounted, cannot show popup');
      return;
    }

    try {
      await reward_popup.showRewardPopup(
        context,
        child: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on,
                  size: 80,
                  color: Colors.amber,
                ),
                const SizedBox(height: 16),
                Text(
                  'Congratulations!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have received $coinsAwarded coins!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFFD1D1D1),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB0B0B0),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5BC0EB),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Awesome!',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.black.withOpacity(0.7),
      );
      print('✅ Reward popup shown successfully');
    } catch (e) {
      print('❌ Error showing reward popup: $e');
      // Fallback: Show a simple snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 You earned $coinsAwarded coins! $reason'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Enhanced awardPoints method that shows popup
  Future<void> awardPointsWithPopup(
      BuildContext context, String userId, int points, String reason,
      {String? activityId}) async {
    await awardPoints(userId, points, reason, activityId: activityId);
    await showRewardPopup(context, points, reason);
  }

  // Challenge System Methods
  Future<Map<String, dynamic>> getWeeklyChallenges(String userId) async {
    try {
      final challengesRef = _db
          .child('gamification')
          .child('challenges')
          .child('weekly')
          .child(userId);
      final snapshot = await challengesRef.get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      } else {
        // Initialize weekly challenges
        final initialChallenges = _initializeWeeklyChallenges();
        await challengesRef.set(initialChallenges);
        return initialChallenges;
      }
    } catch (e) {
      print('Error getting weekly challenges: $e');
      return _initializeWeeklyChallenges();
    }
  }

  Future<Map<String, dynamic>> getMonthlyChallenges(String userId) async {
    try {
      final challengesRef = _db
          .child('gamification')
          .child('challenges')
          .child('monthly')
          .child(userId);
      final snapshot = await challengesRef.get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      } else {
        // Initialize monthly challenges
        final initialChallenges = _initializeMonthlyChallenges();
        await challengesRef.set(initialChallenges);
        return initialChallenges;
      }
    } catch (e) {
      print('Error getting monthly challenges: $e');
      return _initializeMonthlyChallenges();
    }
  }

  Map<String, dynamic> _initializeWeeklyChallenges() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    Map<String, dynamic> challenges = {};
    WEEKLY_CHALLENGES.forEach((key, challenge) {
      challenges[key] = {
        ...challenge,
        'progress': 0,
        'completed': false,
        'claimed': false,
        'weekStart': weekStart.toIso8601String(),
        'weekEnd': weekEnd.toIso8601String(),
      };
    });
    return challenges;
  }

  Map<String, dynamic> _initializeMonthlyChallenges() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    Map<String, dynamic> challenges = {};
    MONTHLY_CHALLENGES.forEach((key, challenge) {
      challenges[key] = {
        ...challenge,
        'progress': 0,
        'completed': false,
        'claimed': false,
        'monthStart': monthStart.toIso8601String(),
        'monthEnd': monthEnd.toIso8601String(),
      };
    });
    return challenges;
  }

  Future<void> updateChallengeProgress(
      String userId, String challengeType, String period) async {
    try {
      final challengesRef = _db
          .child('gamification')
          .child('challenges')
          .child(period)
          .child(userId);
      final snapshot = await challengesRef.get();

      Map<String, dynamic> challenges = {};

      if (snapshot.exists) {
        challenges = Map<String, dynamic>.from(snapshot.value as Map);
      } else {
        // Initialize challenges if they don't exist
        challenges = period == 'weekly'
            ? _initializeWeeklyChallenges()
            : _initializeMonthlyChallenges();
      }

      bool updated = false;

      challenges.forEach((key, challenge) {
        if (challenge['type'] == challengeType && !challenge['completed']) {
          challenge['progress'] = (challenge['progress'] ?? 0) + 1;
          if (challenge['progress'] >= challenge['target']) {
            challenge['completed'] = true;
          }
          updated = true;
        }
      });

      if (updated) {
        await challengesRef.set(challenges);
      }
    } catch (e) {
      print('Error updating challenge progress: $e');
    }
  }

  Future<void> claimChallengeReward(
      String userId, String challengeId, String period, int reward) async {
    try {
      final challengesRef = _db
          .child('gamification')
          .child('challenges')
          .child(period)
          .child(userId);
      final snapshot = await challengesRef.get();

      if (!snapshot.exists) return;

      final challenges = Map<String, dynamic>.from(snapshot.value as Map);

      if (challenges.containsKey(challengeId) &&
          challenges[challengeId]['completed'] &&
          !challenges[challengeId]['claimed']) {
        challenges[challengeId]['claimed'] = true;
        await challengesRef.set(challenges);

        // Award points
        await awardPoints(userId, reward,
            'Challenge Completed: ${challenges[challengeId]['title']}');
      }
    } catch (e) {
      print('Error claiming challenge reward: $e');
    }
  }

  // Social Features - Friends Management
  Future<void> sendFriendRequest(String userId, String friendId) async {
    try {
      final requestsRef = _db.child('gamification').child('friendRequests');
      final requestId = '${userId}_${friendId}';

      await requestsRef.child(requestId).set({
        'senderId': userId,
        'receiverId': friendId,
        'status': 'pending',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error sending friend request: $e');
    }
  }

  Future<void> acceptFriendRequest(String userId, String friendId) async {
    try {
      final requestId = '${friendId}_${userId}';
      final requestsRef = _db.child('gamification').child('friendRequests');

      // Update request status
      await requestsRef.child(requestId).update({'status': 'accepted'});

      // Add friendship
      await addFriend(userId, friendId);
    } catch (e) {
      print('Error accepting friend request: $e');
    }
  }

  Future<void> rejectFriendRequest(String userId, String friendId) async {
    try {
      final requestId = '${friendId}_${userId}';
      final requestsRef = _db.child('gamification').child('friendRequests');

      // Update request status
      await requestsRef.child(requestId).update({'status': 'rejected'});
    } catch (e) {
      print('Error rejecting friend request: $e');
    }
  }

  Future<List<String>> getPendingFriendRequests(String userId) async {
    try {
      final requestsRef = _db.child('gamification').child('friendRequests');
      final snapshot = await requestsRef.get();

      if (snapshot.exists) {
        final requests = Map<String, dynamic>.from(snapshot.value as Map);
        return requests.entries
            .where((entry) =>
                entry.value['receiverId'] == userId &&
                entry.value['status'] == 'pending')
            .map((entry) => entry.value['senderId'] as String)
            .toList();
      }
    } catch (e) {
      print('Error getting pending friend requests: $e');
    }
    return [];
  }

  Future<void> addFriend(String userId, String friendId) async {
    try {
      final friendsRef =
          _db.child('gamification').child('friends').child(userId);
      await friendsRef.child(friendId).set(true);

      // Add reverse friendship
      final reverseFriendsRef =
          _db.child('gamification').child('friends').child(friendId);
      await reverseFriendsRef.child(userId).set(true);
    } catch (e) {
      print('Error adding friend: $e');
    }
  }

  Future<List<String>> getFriends(String userId) async {
    try {
      final friendsRef =
          _db.child('gamification').child('friends').child(userId);
      final snapshot = await friendsRef.get();

      if (snapshot.exists) {
        final friends = Map<String, dynamic>.from(snapshot.value as Map);
        return friends.keys.where((key) => friends[key] == true).toList();
      }
    } catch (e) {
      print('Error getting friends: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getFriendsLeaderboard(
      String userId) async {
    try {
      final friends = await getFriends(userId);
      if (friends.isEmpty) {
        // Return the specified users as default friends data
        final defaultFriends = [
          {
            'userId': 'friend_gajanan',
            'displayName': 'Gajanan',
            'points': 1250,
            'level': 5
          },
          {
            'userId': 'friend_qamar',
            'displayName': 'Qamar Sayyad',
            'points': 980,
            'level': 4
          },
          {
            'userId': 'friend_kharishma',
            'displayName': 'Kharishma Shaik',
            'points': 750,
            'level': 3
          },
          {
            'userId': 'friend_murugam',
            'displayName': 'Murugam Thilak',
            'points': 620,
            'level': 3
          },
          {
            'userId': 'friend_srimanth',
            'displayName': 'Srimanth Reddy',
            'points': 450,
            'level': 2
          },
          {
            'userId': 'friend_sarath',
            'displayName': 'Sarath',
            'points': 320,
            'level': 2
          },
          {
            'userId': 'friend_ryan',
            'displayName': 'Ryan Gabriel',
            'points': 180,
            'level': 1
          },
        ];

        // Add current user
        final userStats = await getUserStats(userId);
        if (userStats != null) {
          defaultFriends.add({
            'userId': userId,
            'displayName': 'You',
            'points': userStats['totalPoints'] ?? 0,
            'level': userStats['level'] ?? 1,
          });
        }

        // Sort by points descending
        defaultFriends
            .sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
        return defaultFriends;
      }

      List<Map<String, dynamic>> friendsStats = [];

      // Get friends' data from leaderboard (more efficient)
      final allLeaderboardData = await getLeaderboards(limit: 200);
      final friendsData = allLeaderboardData
          .where((user) => friends.contains(user['userId']))
          .toList();

      for (var friendData in friendsData) {
        friendsStats.add({
          'userId': friendData['userId'],
          'displayName': friendData['displayName'] ?? 'Friend',
          'points': friendData['points'] ?? 0,
          'level': _calculateLevel(friendData['points'] ?? 0),
        });
      }

      // Add current user
      final userStats = await getUserStats(userId);
      if (userStats != null) {
        friendsStats.add({
          'userId': userId,
          'displayName': 'You',
          'points': userStats['totalPoints'] ?? 0,
          'level': userStats['level'] ?? 1,
        });
      }

      // Sort by points descending
      friendsStats
          .sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
      return friendsStats;
    } catch (e) {
      print('Error getting friends leaderboard: $e');
      // Return current user as fallback
      try {
        final userStats = await getUserStats(userId);
        if (userStats != null) {
          return [
            {
              'userId': userId,
              'displayName': 'You',
              'points': userStats['totalPoints'] ?? 0,
              'level': userStats['level'] ?? 1,
            }
          ];
        }
      } catch (fallbackError) {
        print('Error in fallback: $fallbackError');
      }
      return [];
    }
  }

  // Streak Heatmap Data
  Future<Map<String, int>> getStreakHeatmapData(
      String userId, int months) async {
    try {
      final userStatsRef =
          _db.child('gamification').child('userStats').child(userId);
      final snapshot = await userStatsRef.get();

      if (!snapshot.exists) return {};

      final stats = Map<String, dynamic>.from(snapshot.value as Map);
      final pointHistory = List.from(stats['pointHistory'] ?? []);

      Map<String, int> heatmapData = {};

      // Get data for last N months
      final now = DateTime.now();
      for (int i = 0; i < months; i++) {
        final month = DateTime(now.year, now.month - i, 1);
        final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

        for (int day = 1; day <= daysInMonth; day++) {
          final date = DateTime(month.year, month.month, day);
          final dateKey = date.toIso8601String().split('T')[0];

          // Check if user was active on this day (had login or activity)
          bool wasActive = pointHistory.any((entry) {
            final entryDate = DateTime.parse(entry['timestamp'])
                .toIso8601String()
                .split('T')[0];
            return entryDate == dateKey;
          });

          heatmapData[dateKey] = wasActive ? 1 : 0;
        }
      }

      return heatmapData;
    } catch (e) {
      print('Error getting streak heatmap data: $e');
      return {};
    }
  }

  // Notification Integration
  Future<void> sendAchievementNotification(
      String userId, String achievementName) async {
    try {
      print('Achievement unlocked: $achievementName for user $userId');

      // Import the notification service dynamically to avoid circular imports
      // This will be called from other parts of the app
      final notificationService = NotificationService();
      await notificationService.sendAchievementNotification(
          userId, achievementName);
    } catch (e) {
      print('Error sending achievement notification: $e');
    }
  }

  Future<void> sendChallengeNotification(
      String userId, String challengeName) async {
    try {
      print('Challenge completed: $challengeName for user $userId');

      // This will be called from other parts of the app
      final notificationService = NotificationService();
      await notificationService.sendChallengeCompletedNotification(
          userId, challengeName, 0);
    } catch (e) {
      print('Error sending challenge notification: $e');
    }
  }

  // Streak and Challenge Notification Methods
  Future<void> sendStreakReminderNotification(
      String userId, int currentStreak) async {
    try {
      print(
          'Sending streak reminder to user: $userId, current streak: $currentStreak');

      // This will be called from a scheduled task
      final notificationService = NotificationService();
      await notificationService.sendStreakReminderNotification(
          userId, currentStreak);
    } catch (e) {
      print('Error sending streak reminder notification: $e');
    }
  }

  Future<void> sendStreakBrokenNotification(
      String userId, int previousStreak) async {
    try {
      print(
          'Sending streak broken notification to user: $userId, previous streak: $previousStreak');

      // This will be called when streak is broken
      final notificationService = NotificationService();
      await notificationService.sendStreakBrokenNotification(
          userId, previousStreak);
    } catch (e) {
      print('Error sending streak broken notification: $e');
    }
  }

  Future<void> sendWeeklyChallengeReminderNotification(
      String userId, String challengeName, int progress, int target) async {
    try {
      print(
          'Sending weekly challenge reminder to user: $userId, challenge: $challengeName');

      // This will be called from a scheduled task
      final notificationService = NotificationService();
      await notificationService.sendWeeklyChallengeReminderNotification(
          userId, challengeName, progress, target);
    } catch (e) {
      print('Error sending weekly challenge reminder notification: $e');
    }
  }

  Future<void> sendMonthlyChallengeReminderNotification(
      String userId, String challengeName, int progress, int target) async {
    try {
      print(
          'Sending monthly challenge reminder to user: $userId, challenge: $challengeName');

      // This will be called from a scheduled task
      final notificationService = NotificationService();
      await notificationService.sendMonthlyChallengeReminderNotification(
          userId, challengeName, progress, target);
    } catch (e) {
      print('Error sending monthly challenge reminder notification: $e');
    }
  }

  Future<void> sendChallengeCompletedNotification(
      String userId, String challengeName, int reward) async {
    try {
      print(
          'Sending challenge completed notification to user: $userId, challenge: $challengeName, reward: $reward');

      // This will be called when challenge is completed
      final notificationService = NotificationService();
      await notificationService.sendChallengeCompletedNotification(
          userId, challengeName, reward);
    } catch (e) {
      print('Error sending challenge completed notification: $e');
    }
  }

  // Notification Scheduler Methods
  Future<void> checkAndSendStreakReminders() async {
    try {
      print('Checking for streak reminders...');

      // Get all users
      final usersSnapshot =
          await _db.child('gamification').child('userStats').get();
      if (!usersSnapshot.exists) return;

      final users = Map<String, dynamic>.from(usersSnapshot.value as Map);

      for (var userId in users.keys) {
        final userStats = Map<String, dynamic>.from(users[userId]);
        final currentStreak = userStats['currentStreak'] ?? 0;
        final lastLoginDate = userStats['lastLoginDate'];

        // Only send reminders for users with active streaks (3+ days)
        if (currentStreak >= 3 && lastLoginDate != null) {
          final lastLogin = DateTime.parse(lastLoginDate);
          final now = DateTime.now();
          final daysSinceLastLogin = now.difference(lastLogin).inDays;

          // Send reminder if they haven't logged in for 1 day and it's been more than 12 hours
          if (daysSinceLastLogin == 1 && now.hour >= 12) {
            await sendStreakReminderNotification(userId, currentStreak);
          }
        }
      }
    } catch (e) {
      print('Error checking streak reminders: $e');
    }
  }

  Future<void> checkAndSendChallengeReminders() async {
    try {
      print('Checking for challenge reminders...');

      // Get all users with challenges
      final weeklyChallengesSnapshot = await _db
          .child('gamification')
          .child('challenges')
          .child('weekly')
          .get();
      final monthlyChallengesSnapshot = await _db
          .child('gamification')
          .child('challenges')
          .child('monthly')
          .get();

      // Check weekly challenges
      if (weeklyChallengesSnapshot.exists) {
        final weeklyUsers =
            Map<String, dynamic>.from(weeklyChallengesSnapshot.value as Map);
        for (var userId in weeklyUsers.keys) {
          final userChallenges = Map<String, dynamic>.from(weeklyUsers[userId]);
          for (var challengeKey in userChallenges.keys) {
            final challenge =
                Map<String, dynamic>.from(userChallenges[challengeKey]);
            if (!(challenge['completed'] ?? false) &&
                !(challenge['claimed'] ?? false)) {
              final progress = challenge['progress'] ?? 0;
              final target = challenge['target'] ?? 1;
              final title = challenge['title'] ?? 'Challenge';

              // Send reminder if progress is 50% or more but not complete
              if (progress >= target * 0.5) {
                await sendWeeklyChallengeReminderNotification(
                    userId, title, progress, target);
              }
            }
          }
        }
      }

      // Check monthly challenges
      if (monthlyChallengesSnapshot.exists) {
        final monthlyUsers =
            Map<String, dynamic>.from(monthlyChallengesSnapshot.value as Map);
        for (var userId in monthlyUsers.keys) {
          final userChallenges =
              Map<String, dynamic>.from(monthlyUsers[userId]);
          for (var challengeKey in userChallenges.keys) {
            final challenge =
                Map<String, dynamic>.from(userChallenges[challengeKey]);
            if (!(challenge['completed'] ?? false) &&
                !(challenge['claimed'] ?? false)) {
              final progress = challenge['progress'] ?? 0;
              final target = challenge['target'] ?? 1;
              final title = challenge['title'] ?? 'Challenge';

              // Send reminder if progress is 30% or more but not complete
              if (progress >= target * 0.3) {
                await sendMonthlyChallengeReminderNotification(
                    userId, title, progress, target);
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error checking challenge reminders: $e');
    }
  }

  // Method to check for streak breaks and send notifications
  Future<void> checkStreakBreaks() async {
    try {
      print('Checking for streak breaks...');

      final usersSnapshot =
          await _db.child('gamification').child('userStats').get();
      if (!usersSnapshot.exists) return;

      final users = Map<String, dynamic>.from(usersSnapshot.value as Map);

      for (var userId in users.keys) {
        final userStats = Map<String, dynamic>.from(users[userId]);
        final currentStreak = userStats['currentStreak'] ?? 0;
        final lastLoginDate = userStats['lastLoginDate'];

        if (currentStreak >= 3 && lastLoginDate != null) {
          final lastLogin = DateTime.parse(lastLoginDate);
          final now = DateTime.now();
          final daysSinceLastLogin = now.difference(lastLogin).inDays;

          // If it's been 2+ days since last login, streak is broken
          if (daysSinceLastLogin >= 2) {
            // Send streak broken notification
            await sendStreakBrokenNotification(userId, currentStreak);

            // Reset streak in database
            await _db
                .child('gamification')
                .child('userStats')
                .child(userId)
                .update({
              'currentStreak': 0,
              'longestStreak': userStats['longestStreak'] ?? currentStreak,
            });
          }
        }
      }
    } catch (e) {
      print('Error checking streak breaks: $e');
    }
  }

  // Friend Challenges System
  Future<String> createFriendChallenge({
    required String creatorId,
    required String friendId,
    required String title,
    required String description,
    required String challengeType,
    required int target,
    required int durationDays,
  }) async {
    try {
      final challengeId =
          '${creatorId}_${friendId}_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();
      final endDate = now.add(Duration(days: durationDays));

      // Check if friendId is a dummy user (starts with 'friend_')
      final isDummyUser = friendId.startsWith('friend_');

      final challengeData = {
        'challengeId': challengeId,
        'creatorId': creatorId, // Added for Firebase rules compatibility
        'friendId': friendId,
        'title': title,
        'description': description,
        'type': challengeType,
        'target': target,
        'durationDays': durationDays,
        'createdAt': now.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'status': 'active',
        'participants': {
          creatorId: {
            'userId': creatorId,
            'progress': 0,
            'lastUpdated': now.toIso8601String(),
          },
          friendId: {
            'userId': friendId,
            'progress': 0,
            'lastUpdated': now.toIso8601String(),
          },
        },
        'winner': null,
        'completedAt': null,
        'isDummyChallenge':
            isDummyUser, // Mark if this is a dummy user challenge
      };

      await _db
          .child('gamification')
          .child('friendChallenges')
          .child(challengeId)
          .set(challengeData);

      // Send notification to friend (only if not dummy user)
      if (!isDummyUser) {
        await sendFriendChallengeNotification(friendId, title, creatorId);
      }

      return challengeId;
    } catch (e) {
      print('Error creating friend challenge: $e');
      throw Exception('Failed to create friend challenge');
    }
  }

  Future<List<Map<String, dynamic>>> getUserFriendChallenges(
      String userId) async {
    try {
      print('🔍 Fetching friend challenges for user: $userId');

      // First try the new secure queries
      final challengesRef = _db.child('gamification').child('friendChallenges');

      // Query for challenges where the user is the creator
      final creatorQuery =
          challengesRef.orderByChild('creatorId').equalTo(userId);
      final creatorSnapshot = await creatorQuery.get();
      print('🔍 Creator query completed: ${creatorSnapshot.exists}');

      // Query for challenges where the user is the friend
      final friendQuery =
          challengesRef.orderByChild('friendId').equalTo(userId);
      final friendSnapshot = await friendQuery.get();
      print('🔍 Friend query completed: ${friendSnapshot.exists}');

      final userChallenges = <Map<String, dynamic>>[];
      final challengeKeys = <String>{};

      // Process challenges where the user is the creator
      if (creatorSnapshot.exists) {
        final challenges =
            Map<String, dynamic>.from(creatorSnapshot.value as Map);
        for (var key in challenges.keys) {
          if (!challengeKeys.contains(key)) {
            userChallenges.add(Map<String, dynamic>.from(challenges[key]));
            challengeKeys.add(key);
          }
        }
      }

      // Process challenges where the user is the friend
      if (friendSnapshot.exists) {
        final challenges =
            Map<String, dynamic>.from(friendSnapshot.value as Map);
        for (var key in challenges.keys) {
          if (!challengeKeys.contains(key)) {
            userChallenges.add(Map<String, dynamic>.from(challenges[key]));
            challengeKeys.add(key);
          }
        }
      }

      print('✅ Found ${userChallenges.length} challenges for user $userId');

      // Add opponent display names
      for (var challenge in userChallenges) {
        final creatorId = challenge['creatorId'];
        final friendId = challenge['friendId'];
        final opponentId = creatorId == userId ? friendId : creatorId;

        final leaderboard = await getLeaderboards(limit: 200);
        final opponentData = leaderboard.firstWhere(
          (user) => user['userId'] == opponentId,
          orElse: () => {'displayName': 'Friend'},
        );
        challenge['opponentDisplayName'] =
            opponentData['displayName'] ?? 'Friend';
      }

      print('✅ Returning ${userChallenges.length} challenges for user $userId');

      // Sort by creation date (newest first)
      userChallenges.sort((a, b) {
        final aDate = DateTime.tryParse(a['createdAt'] ?? '');
        final bDate = DateTime.tryParse(b['createdAt'] ?? '');
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1; // a is older
        if (bDate == null) return -1; // b is older
        return bDate.compareTo(aDate);
      });

      return userChallenges;
    } catch (e) {
      print('❌ Error with secure queries: $e');
      print('🔄 Falling back to alternative method...');

      try {
        // Fallback: Try to fetch all challenges and filter client-side
        final challengesRef =
            _db.child('gamification').child('friendChallenges');
        final snapshot = await challengesRef.get();

        if (!snapshot.exists) {
          print('❌ No challenges found in database');
          return [];
        }

        final allChallenges = Map<String, dynamic>.from(snapshot.value as Map);
        final userChallenges = <Map<String, dynamic>>[];

        print(
            '📊 Processing ${allChallenges.length} challenges with fallback method');

        for (var challengeKey in allChallenges.keys) {
          final challengeData =
              Map<String, dynamic>.from(allChallenges[challengeKey]);

          // Check if user is a participant in this challenge
          final participants =
              Map<String, dynamic>.from(challengeData['participants'] ?? {});
          final isParticipant = participants.containsKey(userId);

          print(
              '🔍 Challenge $challengeKey: user $userId is participant: $isParticipant');

          if (isParticipant) {
            // Add missing fields that we parse from the key for consistency
            if (challengeData['creatorId'] == null) {
              final parts = challengeKey.split('_');
              if (parts.isNotEmpty) {
                challengeData['creatorId'] = parts[0];
              }
            }

            // Add opponent display name
            final creatorId = challengeData['creatorId'];
            final friendId = challengeData['friendId'];
            final opponentId = creatorId == userId ? friendId : creatorId;

            final leaderboard = await getLeaderboards(limit: 200);
            final opponentData = leaderboard.firstWhere(
              (user) => user['userId'] == opponentId,
              orElse: () => {'displayName': 'Friend'},
            );
            challengeData['opponentDisplayName'] =
                opponentData['displayName'] ?? 'Friend';

            userChallenges.add(challengeData);
          }
        }

        print(
            '✅ Fallback method: Found ${userChallenges.length} challenges for user $userId');

        // Sort by creation date
        userChallenges.sort((a, b) {
          final aDate = DateTime.tryParse(a['createdAt'] ?? '');
          final bDate = DateTime.tryParse(b['createdAt'] ?? '');
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

        return userChallenges;
      } catch (fallbackError) {
        print('❌ Fallback method also failed: $fallbackError');
        return [];
      }
    }
  }

  Future<void> updateFriendChallengeProgress(
      String challengeId, String userId, int progressIncrement) async {
    try {
      final challengeRef = _db
          .child('gamification')
          .child('friendChallenges')
          .child(challengeId);

      final snapshot = await challengeRef.get();
      if (!snapshot.exists) return;

      final challengeData = Map<String, dynamic>.from(snapshot.value as Map);

      // Check if challenge is still active
      if (challengeData['status'] != 'active') return;

      // Check if challenge has expired
      final endDate = DateTime.parse(challengeData['endDate']);
      if (DateTime.now().isAfter(endDate)) {
        challengeData['status'] = 'expired';
        await challengeRef.set(challengeData);
        return;
      }

      // Update user progress
      final participants =
          Map<String, dynamic>.from(challengeData['participants']);
      if (participants.containsKey(userId)) {
        final userProgress = participants[userId];
        userProgress['progress'] =
            (userProgress['progress'] ?? 0) + progressIncrement;
        userProgress['lastUpdated'] = DateTime.now().toIso8601String();
        participants[userId] = userProgress;

        // Check if user has reached target
        final target = challengeData['target'] ?? 1;
        if (userProgress['progress'] >= target) {
          // Check if opponent has also completed
          final opponentId = challengeData['creatorId'] == userId
              ? challengeData['friendId']
              : challengeData['creatorId'];

          final opponentProgress = participants[opponentId]['progress'] ?? 0;

          if (opponentProgress >= target) {
            // Both completed - determine winner by completion time
            final userCompletionTime =
                DateTime.parse(userProgress['lastUpdated']);
            final opponentCompletionTime =
                DateTime.parse(participants[opponentId]['lastUpdated']);

            if (userCompletionTime.isBefore(opponentCompletionTime)) {
              challengeData['winner'] = userId;
            } else if (opponentCompletionTime.isBefore(userCompletionTime)) {
              challengeData['winner'] = opponentId;
            } else {
              challengeData['winner'] = 'tie';
            }

            challengeData['status'] = 'completed';
            challengeData['completedAt'] = DateTime.now().toIso8601String();

            // Award points to winner
            if (challengeData['winner'] != 'tie') {
              await awardPoints(challengeData['winner'], 50,
                  'Won friend challenge: ${challengeData['title']}');
            } else {
              // Award points to both for tie
              await awardPoints(userId, 25,
                  'Friend challenge tie: ${challengeData['title']}');
              await awardPoints(opponentId, 25,
                  'Friend challenge tie: ${challengeData['title']}');
            }
          }
        }

        challengeData['participants'] = participants;
        await challengeRef.set(challengeData);

        // Send real-time update notification
        await sendFriendChallengeProgressNotification(
            challengeId, userId, challengeData);
      }
    } catch (e) {
      print('Error updating friend challenge progress: $e');
    }
  }

  Future<void> sendFriendChallengeNotification(
      String friendId, String challengeTitle, String creatorId) async {
    try {
      print(
          'Sending friend challenge notification to $friendId for challenge: $challengeTitle');

      final notificationService = NotificationService();
      await notificationService.sendFriendChallengeNotification(
          friendId, challengeTitle, creatorId);
    } catch (e) {
      print('Error sending friend challenge notification: $e');
    }
  }

  Future<void> sendFriendChallengeProgressNotification(String challengeId,
      String userId, Map<String, dynamic> challengeData) async {
    try {
      final opponentId = challengeData['creatorId'] == userId
          ? challengeData['friendId']
          : challengeData['creatorId'];

      final currentUser = FirebaseAuth.instance.currentUser;
      final userName = currentUser?.displayName ?? 'Your friend';

      final notificationService = NotificationService();
      await notificationService.sendFriendChallengeProgressNotification(
        opponentId,
        challengeData['title'],
        userName,
        challengeData['participants'][userId]['progress'] ?? 0,
        challengeData['target'] ?? 1,
      );
    } catch (e) {
      print('Error sending friend challenge progress notification: $e');
    }
  }

  // Get active friend challenges count for a user
  Future<int> getActiveFriendChallengesCount(String userId) async {
    try {
      final challenges = await getUserFriendChallenges(userId);
      return challenges
          .where((challenge) => challenge['status'] == 'active')
          .length;
    } catch (e) {
      print('Error getting active friend challenges count: $e');
      return 0;
    }
  }
}
