import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gamification_service.dart';
import 'gamification_widgets.dart';
import 'leaderboard_screen.dart';
import 'social_screens.dart';

class GamificationDashboard extends StatefulWidget {
  const GamificationDashboard({Key? key}) : super(key: key);

  @override
  _GamificationDashboardState createState() => _GamificationDashboardState();
}

class _GamificationDashboardState extends State<GamificationDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _userStats;
  List<Map<String, dynamic>> _achievements = [];
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_currentUserId == null) {
      // No user logged in, provide default stats
      setState(() {
        _userStats = {
          'level': 1,
          'totalPoints': 0,
          'currentStreak': 0,
          'longestStreak': 0,
          'pointHistory': [],
        };
        _achievements = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await GamificationService().getUserStats(_currentUserId!);
      final achievements =
          await GamificationService().getUserAchievements(_currentUserId!);

      // Always provide user stats, even if null from service
      setState(() {
        _userStats = stats ??
            {
              'level': 1,
              'totalPoints': 0,
              'currentStreak': 0,
              'longestStreak': 0,
              'pointHistory': [],
            };
        _achievements = achievements;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading gamification data: $e');
      // On error, provide default stats
      setState(() {
        _userStats = {
          'level': 1,
          'totalPoints': 0,
          'currentStreak': 0,
          'longestStreak': 0,
          'pointHistory': [],
        };
        _achievements = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Rewards Center',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard, color: Color(0xFF5BC0EB)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF5BC0EB),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Challenges'),
            Tab(text: 'Activity'),
            Tab(text: 'Social'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BC0EB)),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildChallengesTab(),
                _buildActivityTab(),
                _buildSocialTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF5BC0EB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats Grid
            _buildQuickStatsGrid(),
            const SizedBox(height: 20),

            // Achievements
            AchievementShowcase(achievements: _achievements),
            const SizedBox(height: 20),

            // Recent Points History
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
                    'Recent Points History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(_userStats!['pointHistory'] as List<dynamic>? ?? [])
                      .reversed
                      .take(5)
                      .map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: (entry['points'] as int? ?? 0) > 0
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF6B35),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry['reason'] ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            '${(entry['points'] as int? ?? 0) > 0 ? '+' : ''}${entry['points'] ?? 0}',
                            style: TextStyle(
                              color: (entry['points'] as int? ?? 0) > 0
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF6B35),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if ((_userStats!['pointHistory'] as List<dynamic>? ?? [])
                      .isEmpty)
                    const Center(
                      child: Text(
                        'No points history yet',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    final level = _userStats!['level'] ?? 1;
    final points = _userStats!['totalPoints'] ?? 0;
    final streak = _userStats!['currentStreak'] ?? 0;
    final longestStreak = _userStats!['longestStreak'] ?? 0;

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
            'Quick Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Level',
                  level.toString(),
                  Icons.stars,
                  const Color(0xFF5BC0EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Points',
                  points.toString(),
                  Icons.monetization_on,
                  const Color(0xFFFFD700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Current Streak',
                  streak.toString(),
                  Icons.local_fire_department,
                  const Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Best Streak',
                  longestStreak.toString(),
                  Icons.emoji_events,
                  const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    try {
      final pointHistory = List.from(_userStats!['pointHistory'] ?? []);

      if (pointHistory.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'No recent activity',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        );
      }

      // Show last 5 activities
      final recentActivities = pointHistory.reversed.take(5).toList();

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
              'Recent Activity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...recentActivities.map((activity) => _buildActivityItem(activity)),
          ],
        ),
      );
    } catch (e) {
      print('Error building recent activity: $e');
      // Return a safe fallback
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Activity data loading...',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    try {
      final points = activity['points'] ?? 0;
      final reason = activity['reason'] ?? 'Activity';

      // Safely parse timestamp
      DateTime? timestamp;
      try {
        final timestampStr = activity['timestamp'];
        if (timestampStr != null && timestampStr is String) {
          timestamp = DateTime.parse(timestampStr);
        }
      } catch (e) {
        // If parsing fails, use current time
        timestamp = DateTime.now();
      }

      final timeAgo = timestamp != null ? _getTimeAgo(timestamp) : 'Recently';

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: points > 0
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF5BC0EB),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              points > 0 ? '+$points' : '$points',
              style: TextStyle(
                color: points > 0
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF6B35),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // Return a safe fallback for this item
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF5BC0EB),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            const Text(
              '+0',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildChallengesTab() {
    if (_currentUserId == null) {
      return const Center(
        child: Text(
          'Please log in to view challenges',
          style: TextStyle(color: Colors.grey, fontSize: 16),
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
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly/Monthly Challenges',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete challenges to earn points and level up!',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ChallengesShowcase(userId: _currentUserId!),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateChallengeSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
                  'Create Friend Challenge',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Challenge your friends to compete and earn rewards together!',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChallengeFriendsScreen(
                            currentUserId: _currentUserId!,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Create Challenge',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5BC0EB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    if (_currentUserId == null) {
      return const Center(
        child: Text(
          'Please log in to view activity',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          StreakHeatmap(userId: _currentUserId!, months: 6),
          const SizedBox(height: 20),
          _buildActivityInsights(),
        ],
      ),
    );
  }

  Widget _buildActivityInsights() {
    final pointHistory = List.from(_userStats!['pointHistory'] ?? []);
    final today = DateTime.now();
    final thisWeek = pointHistory.where((activity) {
      final date = DateTime.parse(activity['timestamp']);
      return date.isAfter(today.subtract(const Duration(days: 7)));
    }).toList();

    final thisMonth = pointHistory.where((activity) {
      final date = DateTime.parse(activity['timestamp']);
      return date.isAfter(today.subtract(const Duration(days: 30)));
    }).toList();

    final totalPointsThisWeek = thisWeek.fold<int>(
        0, (sum, activity) => sum + ((activity['points'] ?? 0) as int));
    final totalPointsThisMonth = thisMonth.fold<int>(
        0, (sum, activity) => sum + ((activity['points'] ?? 0) as int));

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
            'Activity Insights',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  'This Week',
                  totalPointsThisWeek.toString(),
                  '${thisWeek.length} activities',
                  const Color(0xFF5BC0EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInsightCard(
                  'This Month',
                  totalPointsThisMonth.toString(),
                  '${thisMonth.length} activities',
                  const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
      String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialTab() {
    if (_currentUserId == null) {
      return const Center(
        child: Text(
          'Please log in to view social features',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFriendsSection(),
          const SizedBox(height: 20),
          _buildSocialFeatures(),
        ],
      ),
    );
  }

  Widget _buildFriendsSection() {
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
            'Friends Leaderboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future:
                GamificationService().getFriendsLeaderboard(_currentUserId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF5BC0EB)),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'Add friends to see their progress!',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                );
              }

              final friends = snapshot.data!.take(5).toList(); // Show top 5

              return Column(
                children: friends.map((friend) {
                  final isCurrentUser = friend['userId'] == _currentUserId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? const Color(0xFF5BC0EB).withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrentUser
                            ? const Color(0xFF5BC0EB).withOpacity(0.3)
                            : Colors.grey.shade800,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF5BC0EB),
                          child: Text(
                            (friend['displayName'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            friend['displayName'] ?? 'Unknown',
                            style: TextStyle(
                              color: isCurrentUser
                                  ? const Color(0xFF5BC0EB)
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: isCurrentUser
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${friend['points'] ?? 0} pts',
                          style: const TextStyle(
                            color: Color(0xFF5BC0EB),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSocialFeatures() {
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
            'Social Features',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildSocialFeatureCard(
            'Add Friends',
            'Connect with other learners to compare progress',
            Icons.person_add,
            _navigateToAddFriends,
          ),
          const SizedBox(height: 12),
          _buildSocialFeatureCard(
            'Share Achievements',
            'Show off your accomplishments to friends',
            Icons.share,
            _navigateToShareAchievements,
          ),
          const SizedBox(height: 12),
          _buildSocialFeatureCard(
            'Challenge Friends',
            'Create custom challenges for your friends',
            Icons.sports_score,
            _navigateToChallengeFriends,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialFeatureCard(
      String title, String description, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5BC0EB), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddFriends() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFriendsScreen(currentUserId: _currentUserId!),
      ),
    );
  }

  void _navigateToShareAchievements() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShareAchievementsScreen(
          userId: _currentUserId!,
          achievements: _achievements,
          userStats: _userStats!,
        ),
      ),
    );
  }

  void _navigateToChallengeFriends() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengeFriendsScreen(currentUserId: _currentUserId!),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
