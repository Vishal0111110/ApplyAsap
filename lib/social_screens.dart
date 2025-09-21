import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:share_plus/share_plus.dart';
import 'gamification_service.dart';

class AddFriendsScreen extends StatefulWidget {
  final String currentUserId;

  const AddFriendsScreen({Key? key, required this.currentUserId})
      : super(key: key);

  @override
  _AddFriendsScreenState createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends State<AddFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<String> _currentFriends = [];
  List<String> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all data in parallel
      final results = await Future.wait([
        GamificationService().getFriends(widget.currentUserId),
        GamificationService().getPendingFriendRequests(widget.currentUserId),
        GamificationService().getLeaderboards(limit: 100),
      ]);

      setState(() {
        _currentFriends = results[0] as List<String>;
        _pendingRequests = results[1] as List<String>;
        _allUsers = (results[2] as List<Map<String, dynamic>>)
            .where((user) => user['userId'] != widget.currentUserId)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendFriendRequest(String friendId) async {
    try {
      await GamificationService()
          .sendFriendRequest(widget.currentUserId, friendId);
      await _loadData(); // Refresh data

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request sent!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send friend request'),
          backgroundColor: Color(0xFFFF6B35),
        ),
      );
    }
  }

  Future<void> _acceptFriendRequest(String friendId) async {
    try {
      await GamificationService()
          .acceptFriendRequest(widget.currentUserId, friendId);
      await _loadData(); // Refresh data

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request accepted!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to accept friend request'),
          backgroundColor: Color(0xFFFF6B35),
        ),
      );
    }
  }

  Future<void> _rejectFriendRequest(String friendId) async {
    try {
      await GamificationService()
          .rejectFriendRequest(widget.currentUserId, friendId);
      await _loadData(); // Refresh data

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request rejected'),
          backgroundColor: Color(0xFFFF6B35),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reject friend request'),
          backgroundColor: Color(0xFFFF6B35),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchController.text.trim().isEmpty) {
      return _allUsers;
    }

    final query = _searchController.text.toLowerCase();
    return _allUsers.where((user) {
      final displayName = user['displayName']?.toString().toLowerCase() ?? '';
      final userId = user['userId']?.toString().toLowerCase() ?? '';
      return displayName.contains(query) || userId.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        title: const Text(
          'Add Friends',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BC0EB)),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Pending Requests Section
                  if (_pendingRequests.isNotEmpty) ...[
                    const Text(
                      'Friend Requests',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._pendingRequests.map((requestId) {
                      final user = _allUsers.firstWhere(
                        (u) => u['userId'] == requestId,
                        orElse: () => {
                          'userId': requestId,
                          'displayName': 'Unknown User'
                        },
                      );
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F1F),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF4CAF50).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF4CAF50),
                              child: Text(
                                (user['displayName'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['displayName'] ?? 'Unknown User',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Text(
                                    'Sent you a friend request',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      _acceptFriendRequest(requestId),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4CAF50),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                  ),
                                  child: const Text('Accept',
                                      style: TextStyle(color: Colors.white)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () =>
                                      _rejectFriendRequest(requestId),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6B35),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                  ),
                                  child: const Text('Reject',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by name or ID...',
                      hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF5BC0EB)),
                      filled: true,
                      fillColor: const Color(0xFF1F1F1F),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // All Users List
                  const Text(
                    'All Users',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: _filteredUsers.isEmpty
                        ? const Center(
                            child: Text(
                              'No users found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              final isFriend =
                                  _currentFriends.contains(user['userId']);
                              final hasPendingRequest =
                                  _pendingRequests.contains(user['userId']);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F1F1F),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: const Color(0xFF5BC0EB),
                                      child: Text(
                                        (user['displayName'] ?? 'U')[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user['displayName'] ??
                                                'Unknown User',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            '${user['points'] ?? 0} points',
                                            style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.shade600,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        disabledBackgroundColor:
                                            Colors.grey.shade600,
                                      ),
                                      child: const Text(
                                        'Friend',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class ShareAchievementsScreen extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> achievements;
  final Map<String, dynamic> userStats;

  const ShareAchievementsScreen({
    Key? key,
    required this.userId,
    required this.achievements,
    required this.userStats,
  }) : super(key: key);

  @override
  _ShareAchievementsScreenState createState() =>
      _ShareAchievementsScreenState();
}

class _ShareAchievementsScreenState extends State<ShareAchievementsScreen> {
  String _shareMessage = '';

  @override
  void initState() {
    super.initState();
    _generateShareMessage();
  }

  void _generateShareMessage() {
    final level = widget.userStats['level'] ?? 1;
    final points = widget.userStats['totalPoints'] ?? 0;
    final achievementsCount = widget.achievements.length;

    setState(() {
      _shareMessage = '''
🏆 Achievement Unlocked! 🏆

I've reached Level $level with $points points in Apply ASAP!

Recent Achievements:
${widget.achievements.take(3).map((a) => '• ${a['name']}').join('\n')}

${achievementsCount > 3 ? '...and ${achievementsCount - 3} more!' : ''}

Join me in mastering new skills! 🚀
#ApplyASAP #SkillDevelopment
      '''
          .trim();
    });
  }

  Future<void> _shareAchievements() async {
    try {
      await Share.share(_shareMessage);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to share achievements'),
          backgroundColor: Color(0xFFFF6B35),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        title: const Text(
          'Share Achievements',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF5BC0EB)),
            onPressed: _shareAchievements,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Stats Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF5BC0EB),
                    child: Text(
                      'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level ${widget.userStats['level'] ?? 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.userStats['totalPoints'] ?? 0} Points',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Achievements List
            const Text(
              'Your Achievements',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            if (widget.achievements.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'No achievements yet. Keep learning!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                children: widget.achievements.map((achievement) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Color(0xFF5BC0EB),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                achievement['name'] ?? 'Achievement',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                achievement['description'] ?? '',
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
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),

            // Share Preview
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
                    'Share Preview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _shareMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _shareAchievements,
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text('Share Achievements',
                    style: TextStyle(color: Colors.white)),
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
    );
  }
}

class ChallengeFriendsScreen extends StatefulWidget {
  final String currentUserId;

  const ChallengeFriendsScreen({Key? key, required this.currentUserId})
      : super(key: key);

  @override
  _ChallengeFriendsScreenState createState() => _ChallengeFriendsScreenState();
}

class _ChallengeFriendsScreenState extends State<ChallengeFriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _activeChallenges = [];
  List<Map<String, dynamic>> _completedChallenges = [];
  bool _isLoading = true;
  final TextEditingController _challengeTitleController =
      TextEditingController();
  final TextEditingController _challengeDescriptionController =
      TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  String _selectedChallengeType = 'questions_completed';
  String _selectedFriendId = '';
  int _durationDays = 7;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _challengeTitleController.dispose();
    _challengeDescriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load friends and challenges in parallel
      final results = await Future.wait([
        GamificationService().getFriendsLeaderboard(
            widget.currentUserId), // Use leaderboard to get default friends
        GamificationService().getUserFriendChallenges(widget.currentUserId),
      ]);

      final friendsData = results[0] as List<Map<String, dynamic>>;
      final allChallenges = results[1] as List<Map<String, dynamic>>;

      print('📱 UI: Received ${allChallenges.length} challenges from service');

      // Filter out current user from friends list (keep all default friends)
      final filteredFriends = friendsData
          .where((friend) => friend['userId'] != widget.currentUserId)
          .toList();

      final activeChallenges = allChallenges
          .where((challenge) => challenge['status'] == 'active')
          .toList();
      final completedChallenges = allChallenges
          .where((challenge) => challenge['status'] == 'completed')
          .toList();

      // Hard coded challenge data instead of fetching from DB
      final hardCodedChallenge = {
        'title': 'Answer Questions',
        'description': 'Challenge to answer 20 questions',
        'creatorId': widget.currentUserId,
        'friendId': 'gajanan_id',
        'opponentDisplayName': 'Gajanan',
        'target': 20,
        'status': 'active',
        'participants': {
          widget.currentUserId: {'progress': 0}, // Current user progress
          'gajanan_id': {'progress': 0}, // Gajanan's progress
        },
        'endDate':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'type': 'questions_completed'
      };
      activeChallenges.add(hardCodedChallenge);

      print('📱 UI: Filtered ${activeChallenges.length} active challenges');
      print(
          '📱 UI: Filtered ${completedChallenges.length} completed challenges');

      setState(() {
        _friends = filteredFriends;
        _activeChallenges = activeChallenges;
        _completedChallenges = completedChallenges;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ UI Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createChallenge() async {
    if (_challengeTitleController.text.trim().isEmpty ||
        _challengeDescriptionController.text.trim().isEmpty ||
        _targetController.text.trim().isEmpty ||
        _selectedFriendId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select a friend'),
          backgroundColor: Color(0xFFFF6B35),
        ),
      );
      return;
    }

    final target = int.tryParse(_targetController.text);
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid target number'),
          backgroundColor: Color(0xFFFF6B35),
        ),
      );
      return;
    }

    try {
      await GamificationService().createFriendChallenge(
        creatorId: widget.currentUserId,
        friendId: _selectedFriendId,
        title: _challengeTitleController.text.trim(),
        description: _challengeDescriptionController.text.trim(),
        challengeType: _selectedChallengeType,
        target: target,
        durationDays: _durationDays,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challenge created successfully!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );

      // Clear form
      _challengeTitleController.clear();
      _challengeDescriptionController.clear();
      _targetController.clear();
      setState(() {
        _selectedFriendId = '';
      });

      // Small delay to ensure database write is complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Refresh data
      await _loadData();
    } catch (e) {
      print('Error creating challenge: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create challenge'),
          backgroundColor: Color(0xFFFF6B35),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        title: const Text(
          'Challenge Friends',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF5BC0EB),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Create'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Create Challenge Tab
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF5BC0EB)),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Create Challenge Form
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
                              'Create New Challenge',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Challenge Title
                            TextField(
                              controller: _challengeTitleController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Challenge Title',
                                labelStyle: TextStyle(color: Color(0xFFB0B0B0)),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFF5BC0EB)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFF5BC0EB)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Challenge Description
                            TextField(
                              controller: _challengeDescriptionController,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                labelStyle: TextStyle(color: Color(0xFFB0B0B0)),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFF5BC0EB)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFF5BC0EB)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Challenge Type
                            DropdownButtonFormField<String>(
                              value: _selectedChallengeType,
                              style: const TextStyle(color: Colors.white),
                              dropdownColor: const Color(0xFF1F1F1F),
                              decoration: const InputDecoration(
                                labelText: 'Challenge Type',
                                labelStyle: TextStyle(color: Color(0xFFB0B0B0)),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFF5BC0EB)),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'questions_completed',
                                  child: Text('Answer Questions'),
                                ),
                                DropdownMenuItem(
                                  value: 'interviews_completed',
                                  child: Text('Complete Interviews'),
                                ),
                                DropdownMenuItem(
                                  value: 'courses_started',
                                  child: Text('Start Courses'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedChallengeType = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            // Target
                            TextField(
                              controller: _targetController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Target Number',
                                labelStyle: TextStyle(color: Color(0xFFB0B0B0)),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFF5BC0EB)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFF5BC0EB)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Select Friends
                      const Text(
                        'Select Friends to Challenge',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_friends.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1F1F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Add friends first to create challenges!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: _friends.map((friend) {
                            final isSelected =
                                _selectedFriendId == friend['userId'];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F1F1F),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF5BC0EB)
                                      : Colors.grey.shade800,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: friend['userId'],
                                    groupValue: _selectedFriendId,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedFriendId = value!;
                                      });
                                    },
                                    activeColor: const Color(0xFF5BC0EB),
                                  ),
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF5BC0EB),
                                    child: Text(
                                      (friend['displayName'] ?? 'U')[0]
                                          .toUpperCase(),
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
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 20),

                      // Create Challenge Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _createChallenge,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5BC0EB),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Create Challenge',
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

          // Active Challenges Tab
          _buildChallengesTab(_activeChallenges, 'Active Challenges'),

          // Completed Challenges Tab
          _buildChallengesTab(_completedChallenges, 'Completed Challenges'),
        ],
      ),
    );
  }

  Widget _buildChallengesTab(
      List<Map<String, dynamic>> challenges, String title) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BC0EB)),
        ),
      );
    }

    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'No $title',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title == 'Active Challenges'
                  ? 'Create a challenge to get started!'
                  : 'Completed challenges will appear here',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return _buildChallengeCard(challenge);
      },
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    final participants =
        Map<String, dynamic>.from(challenge['participants'] ?? {});
    final currentUserId = widget.currentUserId;
    final opponentId = challenge['creatorId'] == currentUserId
        ? challenge['friendId']
        : challenge['creatorId'];

    final currentUserProgress = participants[currentUserId]?['progress'] ?? 0;
    final opponentProgress = participants[opponentId]?['progress'] ?? 0;
    final target = challenge['target'] ?? 1;

    final currentUserPercentage =
        (currentUserProgress / target).clamp(0.0, 1.0);
    final opponentPercentage = (opponentProgress / target).clamp(0.0, 1.0);

    final isCompleted = challenge['status'] == 'completed';
    final winner = challenge['winner'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? (winner == currentUserId
                  ? const Color(0xFF4CAF50)
                  : winner == 'tie'
                      ? const Color(0xFFFFD700)
                      : const Color(0xFFFF6B35))
              : const Color(0xFF5BC0EB),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Challenge Title and Status
          Row(
            children: [
              Expanded(
                child: Text(
                  challenge['title'] ?? 'Challenge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: winner == currentUserId
                        ? const Color(0xFF4CAF50)
                        : winner == 'tie'
                            ? const Color(0xFFFFD700)
                            : const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    winner == currentUserId
                        ? 'Won'
                        : winner == 'tie'
                            ? 'Tie'
                            : 'Lost',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Challenge Description
          Text(
            challenge['description'] ?? '',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 16),

          // Progress Bars
          _buildProgressSection(
            'You',
            currentUserProgress,
            target,
            currentUserPercentage,
            isCurrentUser: true,
          ),

          const SizedBox(height: 12),

          _buildProgressSection(
            challenge['opponentDisplayName'] ?? 'Friend',
            opponentProgress,
            target,
            opponentPercentage,
            isCurrentUser: false,
          ),

          const SizedBox(height: 12),

          // Target and Time Remaining
          Row(
            children: [
              Icon(
                Icons.flag,
                color: const Color(0xFF5BC0EB),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Target: $target ${challenge['type'] == 'questions_completed' ? 'questions' : challenge['type'] == 'interviews_completed' ? 'interviews' : 'courses'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (!isCompleted) ...[
                Icon(
                  Icons.timer,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _getTimeRemaining(challenge['endDate']),
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(
      String name, int progress, int target, double percentage,
      {required bool isCurrentUser}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              name,
              style: TextStyle(
                color: isCurrentUser ? const Color(0xFF5BC0EB) : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '$progress / $target',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade800,
          valueColor: AlwaysStoppedAnimation<Color>(
            isCurrentUser ? const Color(0xFF5BC0EB) : const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildChallengesTabWithDebug(
      List<Map<String, dynamic>> challenges, String title) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Debug Information
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2F2F2F),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.yellow, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔧 DEBUG INFO',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Challenges Count: ${challenges.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Tab: $title',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'User ID: ${widget.currentUserId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                if (challenges.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'First Challenge Data:',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Title: ${challenges[0]['title'] ?? 'N/A'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Status: ${challenges[0]['status'] ?? 'N/A'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Creator: ${challenges[0]['creatorId'] ?? 'N/A'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Friend: ${challenges[0]['friendId'] ?? 'N/A'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Original Challenge Display
          if (challenges.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No $title',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title == 'Active Challenges'
                        ? 'Create a challenge to get started!'
                        : 'Completed challenges will appear here',
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
            Column(
              children: challenges.map((challenge) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _buildChallengeCard(challenge),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  String _getTimeRemaining(String? endDateString) {
    if (endDateString == null) return 'Unknown';

    try {
      final endDate = DateTime.parse(endDateString);
      final now = DateTime.now();
      final difference = endDate.difference(now);

      if (difference.isNegative) return 'Expired';

      final days = difference.inDays;
      final hours = difference.inHours % 24;

      if (days > 0) {
        return '$days days left';
      } else if (hours > 0) {
        return '$hours hours left';
      } else {
        return 'Less than 1 hour';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
