import 'dart:async';
import 'package:flutter/material.dart';
import 'gamification_service.dart';

class LevelIndicator extends StatelessWidget {
  final int level;
  final int points;
  final int pointsToNextLevel;

  const LevelIndicator({
    Key? key,
    required this.level,
    required this.points,
    required this.pointsToNextLevel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF5BC0EB).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars, size: 16, color: const Color(0xFF5BC0EB)),
          const SizedBox(width: 6),
          Text(
            'Level $level',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor:
                  (points % 100) / 100, // Assuming 100 points per level
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF5BC0EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FriendChallengeCard extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final String currentUserId;

  const FriendChallengeCard({
    Key? key,
    required this.challenge,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final participants =
        Map<String, dynamic>.from(challenge['participants'] ?? {});
    final currentUserProgress = participants[currentUserId]?['progress'] ?? 0;
    final opponentId = challenge['creatorId'] == currentUserId
        ? challenge['friendId']
        : challenge['creatorId'];
    final opponentProgress = participants[opponentId]?['progress'] ?? 0;
    final target = challenge['target'] ?? 1;
    final status = challenge['status'] ?? 'active';
    final winner = challenge['winner'];
    final isCurrentUserWinner = winner == currentUserId;
    final isTie = winner == 'tie';

    // Determine opponent display name
    final opponentDisplayName = challenge['opponentDisplayName'] ?? 'Friend';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'completed'
              ? (isCurrentUserWinner
                  ? const Color(0xFF4CAF50).withOpacity(0.3)
                  : isTie
                      ? const Color(0xFFFF6B35).withOpacity(0.3)
                      : const Color(0xFFFF6B35).withOpacity(0.3))
              : const Color(0xFF5BC0EB).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and status
          Row(
            children: [
              Icon(
                status == 'completed'
                    ? (isCurrentUserWinner
                        ? Icons.emoji_events
                        : isTie
                            ? Icons.handshake
                            : Icons.cancel)
                    : Icons.sports_score,
                size: 20,
                color: status == 'completed'
                    ? (isCurrentUserWinner
                        ? const Color(0xFF4CAF50)
                        : isTie
                            ? const Color(0xFFFF6B35)
                            : const Color(0xFFFF6B35))
                    : const Color(0xFF5BC0EB),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  challenge['title'] ?? 'Challenge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (status == 'completed')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCurrentUserWinner
                        ? const Color(0xFF4CAF50).withOpacity(0.2)
                        : isTie
                            ? const Color(0xFFFF6B35).withOpacity(0.2)
                            : const Color(0xFFFF6B35).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCurrentUserWinner
                        ? 'Won!'
                        : isTie
                            ? 'Tie!'
                            : 'Lost',
                    style: TextStyle(
                      color: isCurrentUserWinner
                          ? const Color(0xFF4CAF50)
                          : isTie
                              ? const Color(0xFFFF6B35)
                              : const Color(0xFFFF6B35),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            challenge['description'] ?? '',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 16),

          // Progress comparison
          Row(
            children: [
              // Current user progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: currentUserProgress / target,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        status == 'completed' && isCurrentUserWinner
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF5BC0EB),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentUserProgress/$target',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Opponent progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opponentDisplayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: opponentProgress / target,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        status == 'completed' && !isCurrentUserWinner && !isTie
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF6B35),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$opponentProgress/$target',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Time remaining or completion info
          Row(
            children: [
              Icon(
                status == 'completed' ? Icons.check_circle : Icons.schedule,
                size: 14,
                color: status == 'completed'
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade400,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _getTimeInfo(challenge),
                  style: TextStyle(
                    color: status == 'completed'
                        ? const Color(0xFF4CAF50)
                        : Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeInfo(Map<String, dynamic> challenge) {
    final status = challenge['status'] ?? 'active';

    if (status == 'completed') {
      final completedAt = challenge['completedAt'];
      if (completedAt != null) {
        final completedDate = DateTime.parse(completedAt);
        final now = DateTime.now();
        final difference = now.difference(completedDate);

        if (difference.inDays > 0) {
          return 'Completed ${difference.inDays} days ago';
        } else if (difference.inHours > 0) {
          return 'Completed ${difference.inHours} hours ago';
        } else {
          return 'Completed recently';
        }
      }
      return 'Completed';
    }

    final endDate = challenge['endDate'];
    if (endDate != null) {
      final endDateTime = DateTime.parse(endDate);
      final now = DateTime.now();
      final difference = endDateTime.difference(now);

      if (difference.isNegative) {
        return 'Expired';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} days left';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours left';
      } else {
        return 'Less than 1 hour left';
      }
    }

    return 'Active';
  }
}

class FriendChallengesShowcase extends StatefulWidget {
  final String userId;

  const FriendChallengesShowcase({Key? key, required this.userId})
      : super(key: key);

  @override
  _FriendChallengesShowcaseState createState() =>
      _FriendChallengesShowcaseState();
}

class _FriendChallengesShowcaseState extends State<FriendChallengesShowcase>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _activeChallenges = [];
  List<Map<String, dynamic>> _completedChallenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: 0); // Start on Active tab
    _loadChallenges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    // Hard coded challenge data instead of fetching from DB
    final hardCodedChallenge = {
      'title': 'Answer Questions',
      'description': 'Challenge to answer 20 questions',
      'creatorId': widget.userId,
      'friendId': 'gajanan_id',
      'opponentDisplayName': 'Gajanan',
      'target': 20,
      'status': 'active',
      'participants': {
        widget.userId: {'progress': 0}, // Current user progress
        'gajanan_id': {'progress': 0}, // Gajanan's progress
      },
      'endDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    };

    if (mounted) {
      setState(() {
        _activeChallenges = [hardCodedChallenge];
        _completedChallenges = []; // No completed challenges for now
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Friend Challenges',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF5BC0EB),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'Active (${_activeChallenges.length})'),
                    Tab(text: 'Completed (${_completedChallenges.length})'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChallengesList(_activeChallenges, 'active'),
                _buildChallengesList(_completedChallenges, 'completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesList(
      List<Map<String, dynamic>> challenges, String type) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BC0EB)),
        ),
      );
    }

    print('DEBUG: Building challenges list for type: $type');
    print('DEBUG: Challenges count: ${challenges.length}');
    print('DEBUG: Challenges: $challenges');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Challenges List
          if (challenges.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type == 'active' ? Icons.sports_score : Icons.emoji_events,
                    size: 48,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    type == 'active'
                        ? 'No active challenges'
                        : 'No completed challenges',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type == 'active'
                        ? 'Create a challenge to get started!'
                        : 'Completed challenges will appear here.',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: challenges.length,
                itemBuilder: (context, index) {
                  final challenge = challenges[index];
                  print(
                      'DEBUG: Rendering challenge $index: ${challenge['title']}');
                  return FriendChallengeCard(
                    challenge: challenge,
                    currentUserId: widget.userId,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class PointsDisplay extends StatelessWidget {
  final int points;

  const PointsDisplay({Key? key, required this.points}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/coins.png', width: 16, height: 16),
        const SizedBox(width: 4),
        Text(
          points.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class StreakCounter extends StatelessWidget {
  final int currentStreak;

  const StreakCounter({Key? key, required this.currentStreak})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: currentStreak > 0
            ? const Color(0xFFFF6B35).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: currentStreak > 0
            ? Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 14,
            color: currentStreak > 0 ? const Color(0xFFFF6B35) : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            currentStreak.toString(),
            style: TextStyle(
              color: currentStreak > 0 ? const Color(0xFFFF6B35) : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AchievementBadge extends StatelessWidget {
  final String name;
  final String description;
  final bool unlocked;

  const AchievementBadge({
    Key? key,
    required this.name,
    required this.description,
    this.unlocked = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? const Color(0xFF5BC0EB).withOpacity(0.1)
                  : Colors.grey.shade800,
              border: Border.all(
                color:
                    unlocked ? const Color(0xFF5BC0EB) : Colors.grey.shade700,
                width: 2,
              ),
            ),
            child: Icon(
              unlocked ? Icons.emoji_events : Icons.lock,
              color: unlocked ? const Color(0xFF5BC0EB) : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              color: unlocked ? Colors.white : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class DailyChallenge extends StatelessWidget {
  final String challenge;
  final int progress;
  final int target;
  final bool completed;

  const DailyChallenge({
    Key? key,
    required this.challenge,
    required this.progress,
    required this.target,
    this.completed = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : const Color(0xFF5BC0EB).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                completed ? Icons.check_circle : Icons.flag,
                size: 16,
                color: completed
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF5BC0EB),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  challenge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress / target,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(
              completed ? const Color(0xFF4CAF50) : const Color(0xFF5BC0EB),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$progress/$target',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class GamificationHeader extends StatelessWidget {
  final Map<String, dynamic> userStats;

  const GamificationHeader({Key? key, required this.userStats})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    int level = userStats['level'] ?? 1;
    int points = userStats['totalPoints'] ?? 0;
    int currentStreak = userStats['currentStreak'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          LevelIndicator(
            level: level,
            points: points,
            pointsToNextLevel: _getPointsToNextLevel(level),
          ),
          const Spacer(),
          StreakCounter(currentStreak: currentStreak),
          const SizedBox(width: 12),
          PointsDisplay(points: points),
        ],
      ),
    );
  }

  int _getPointsToNextLevel(int level) {
    switch (level) {
      case 1:
        return 100;
      case 2:
        return 200;
      case 3:
        return 300;
      case 4:
        return 400;
      case 5:
        return 500;
      case 6:
        return 700;
      default:
        return 0;
    }
  }
}

class AchievementShowcase extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;

  const AchievementShowcase({Key? key, required this.achievements})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Complete activities to unlock achievements!',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Achievements',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return AchievementBadge(
                  name: achievement['name'] ?? '',
                  description: achievement['description'] ?? '',
                  unlocked: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PointsPopup extends StatelessWidget {
  final int points;
  final String reason;

  const PointsPopup({
    Key? key,
    required this.points,
    required this.reason,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            '+$points XP',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            reason,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class StreakHeatmap extends StatefulWidget {
  final String userId;
  final int months;

  const StreakHeatmap({
    Key? key,
    required this.userId,
    this.months = 6,
  }) : super(key: key);

  @override
  _StreakHeatmapState createState() => _StreakHeatmapState();
}

class _StreakHeatmapState extends State<StreakHeatmap> {
  Map<String, int> _heatmapData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHeatmapData();
  }

  Future<void> _loadHeatmapData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await GamificationService()
          .getStreakHeatmapData(widget.userId, widget.months);
      setState(() {
        _heatmapData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading heatmap data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BC0EB)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Heatmap',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your learning activity over the last ${widget.months} months',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          _buildHeatmap(),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeatmap() {
    final now = DateTime.now();
    final months = <DateTime>[];

    // Generate months from most recent to oldest
    for (int i = 0; i < widget.months; i++) {
      months.add(DateTime(now.year, now.month - i, 1));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: months.map((month) => _buildMonthRow(month)).toList(),
      ),
    );
  }

  Widget _buildMonthRow(DateTime month) {
    final monthName = _getMonthName(month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Month label
          SizedBox(
            width: 60,
            child: Text(
              monthName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Day cells
          ...List.generate(daysInMonth, (day) {
            final date = DateTime(month.year, month.month, day + 1);
            final dateKey = date.toIso8601String().split('T')[0];
            final activity = _heatmapData[dateKey] ?? 0;

            return Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: _getActivityColor(activity),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      children: [
        const Text(
          'Activity Intensity',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // No activity
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getActivityColor(0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '0',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Light activity (1 activity)
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getActivityColor(1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '1',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Medium activity (2-10 activities)
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getActivityColor(5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '2-10',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // High activity (10+ activities)
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getActivityColor(15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '10+',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Color _getActivityColor(int activity) {
    if (activity == 0) {
      return Colors.grey.shade800; // No activity
    } else if (activity > 0 && activity < 2) {
      return const Color(0xFF87CEEB)
          .withOpacity(0.6); // Light blue for 1 activity
    } else if (activity >= 2 && activity <= 10) {
      return const Color(0xFF5BC0EB)
          .withOpacity(0.8); // Medium blue for 2-10 activities
    } else {
      return const Color(0xFF1E90FF)
          .withOpacity(0.9); // Dark blue for 10+ activities
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

class ChallengeCard extends StatelessWidget {
  final String title;
  final String description;
  final int progress;
  final int target;
  final bool completed;
  final bool claimed;
  final int reward;
  final VoidCallback? onClaim;

  const ChallengeCard({
    Key? key,
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
    this.completed = false,
    this.claimed = false,
    required this.reward,
    this.onClaim,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : const Color(0xFF5BC0EB).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                completed ? Icons.check_circle : Icons.flag,
                size: 20,
                color: completed
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF5BC0EB),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (completed && !claimed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+$reward',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress / target,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(
              completed ? const Color(0xFF4CAF50) : const Color(0xFF5BC0EB),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$progress/$target',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
              if (completed && !claimed)
                ElevatedButton(
                  onPressed: onClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'Claim',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChallengesShowcase extends StatefulWidget {
  final String userId;

  const ChallengesShowcase({Key? key, required this.userId}) : super(key: key);

  @override
  _ChallengesShowcaseState createState() => _ChallengesShowcaseState();

  // Static method to refresh challenges from outside
  static void refreshChallenges(BuildContext context) {
    final state = context.findAncestorStateOfType<_ChallengesShowcaseState>();
    if (state != null && state.mounted) {
      state._loadChallenges();
    }
  }
}

class _ChallengesShowcaseState extends State<ChallengesShowcase>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _weeklyChallenges = {};
  Map<String, dynamic> _monthlyChallenges = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChallenges();

    // Auto-refresh challenges every 30 seconds to update progress
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadChallenges();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final weekly =
          await GamificationService().getWeeklyChallenges(widget.userId);
      final monthly =
          await GamificationService().getMonthlyChallenges(widget.userId);

      if (mounted) {
        setState(() {
          _weeklyChallenges = weekly;
          _monthlyChallenges = monthly;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading challenges: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BC0EB)),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Challenges',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF5BC0EB),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'Weekly'),
                    Tab(text: 'Monthly'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChallengesList(_weeklyChallenges, 'weekly'),
                _buildChallengesList(_monthlyChallenges, 'monthly'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesList(Map<String, dynamic> challenges, String period) {
    if (challenges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'No challenges available',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challengeKey = challenges.keys.elementAt(index);
          final challenge = challenges[challengeKey];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ChallengeCard(
              title: challenge['title'] ?? '',
              description: challenge['description'] ?? '',
              progress: challenge['progress'] ?? 0,
              target: challenge['target'] ?? 1,
              completed: challenge['completed'] ?? false,
              claimed: challenge['claimed'] ?? false,
              reward: challenge['reward'] ?? 0,
              onClaim: () async {
                await GamificationService().claimChallengeReward(
                  widget.userId,
                  challengeKey,
                  period,
                  challenge['reward'] ?? 0,
                );
                await _loadChallenges(); // Refresh
              },
            ),
          );
        },
      ),
    );
  }
}
