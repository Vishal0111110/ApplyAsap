import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gamification_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _globalLeaderboard = [];
  List<Map<String, dynamic>> _friendsLeaderboard = [];
  List<Map<String, dynamic>> _filteredGlobalLeaderboard = [];
  List<Map<String, dynamic>> _filteredFriendsLeaderboard = [];
  bool _isLoading = true;
  String? _currentUserId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadLeaderboards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filterLeaderboards();
    });
  }

  void _filterLeaderboards() {
    if (_searchQuery.isEmpty) {
      _filteredGlobalLeaderboard = List.from(_globalLeaderboard);
      _filteredFriendsLeaderboard = List.from(_friendsLeaderboard);
    } else {
      _filteredGlobalLeaderboard = _globalLeaderboard.where((user) {
        final displayName = (user['displayName'] ?? '').toLowerCase();
        final userId = (user['userId'] ?? '').toLowerCase();
        return displayName.contains(_searchQuery) ||
            userId.contains(_searchQuery);
      }).toList();

      _filteredFriendsLeaderboard = _friendsLeaderboard.where((user) {
        final displayName = (user['displayName'] ?? '').toLowerCase();
        final userId = (user['userId'] ?? '').toLowerCase();
        return displayName.contains(_searchQuery) ||
            userId.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadLeaderboards() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load global leaderboard (using same logic as friends leaderboard)
      if (_currentUserId != null) {
        _globalLeaderboard =
            await GamificationService().getFriendsLeaderboard(_currentUserId!);
      } else {
        _globalLeaderboard = [];
      }

      // Load friends leaderboard
      if (_currentUserId != null) {
        _friendsLeaderboard =
            await GamificationService().getFriendsLeaderboard(_currentUserId!);
      } else {
        _friendsLeaderboard = [];
      }

      // Sort by points descending
      _globalLeaderboard
          .sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
      _friendsLeaderboard
          .sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

      // Initialize filtered lists
      _filteredGlobalLeaderboard = List.from(_globalLeaderboard);
      _filteredFriendsLeaderboard = List.from(_friendsLeaderboard);
    } catch (e) {
      print('Error loading leaderboards: $e');
      // Provide fallback empty lists
      _globalLeaderboard = [];
      _friendsLeaderboard = [];
      _filteredGlobalLeaderboard = [];
      _filteredFriendsLeaderboard = [];
    }

    setState(() {
      _isLoading = false;
    });
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
          'Leaderboards',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF5BC0EB),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardTab(_filteredGlobalLeaderboard, _globalLeaderboard),
          _buildLeaderboardTab(
              _filteredFriendsLeaderboard, _friendsLeaderboard),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(List<Map<String, dynamic>> filteredLeaderboard,
      List<Map<String, dynamic>> originalLeaderboard) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BC0EB)),
        ),
      );
    }

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by name or ID...',
              hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF5BC0EB)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF1F1F1F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        // Results count
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Found ${filteredLeaderboard.length} result${filteredLeaderboard.length != 1 ? 's' : ''}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),

        // Leaderboard List
        Expanded(
          child: filteredLeaderboard.isEmpty && _searchQuery.isNotEmpty
              ? const Center(
                  child: Text(
                    'No users found matching your search',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : filteredLeaderboard.isEmpty
                  ? const Center(
                      child: Text(
                        'No leaderboard data available',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLeaderboards,
                      color: const Color(0xFF5BC0EB),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredLeaderboard.length,
                        itemBuilder: (context, index) {
                          final user = filteredLeaderboard[index];
                          // Calculate rank based on original leaderboard position
                          final originalIndex = originalLeaderboard
                              .indexWhere((u) => u['userId'] == user['userId']);
                          final rank = originalIndex + 1;
                          final isCurrentUser =
                              user['userId'] == _currentUserId;

                          return _buildLeaderboardItem(
                              user, rank, isCurrentUser);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(
      Map<String, dynamic> user, int rank, bool isCurrentUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? const Color(0xFF5BC0EB).withOpacity(0.1)
            : const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFF5BC0EB).withOpacity(0.3)
              : Colors.grey.shade800,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getRankColor(rank),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['displayName'] ?? 'Anonymous User',
                  style: TextStyle(
                    color:
                        isCurrentUser ? const Color(0xFF5BC0EB) : Colors.white,
                    fontSize: 16,
                    fontWeight:
                        isCurrentUser ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                if (isCurrentUser)
                  const Text(
                    'You',
                    style: TextStyle(
                      color: Color(0xFF5BC0EB),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),

          // Points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF5BC0EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Image.asset('assets/images/coins.png', width: 16, height: 16),
                const SizedBox(width: 4),
                Text(
                  '${user['points'] ?? 0}',
                  style: const TextStyle(
                    color: Color(0xFF5BC0EB),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return const Color(0xFF5BC0EB); // Default blue
    }
  }
}
