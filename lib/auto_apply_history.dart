import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'web.dart';

class AutoApplyHistoryPage extends StatefulWidget {
  const AutoApplyHistoryPage({super.key});

  @override
  State<AutoApplyHistoryPage> createState() => _AutoApplyHistoryPageState();
}

class _AutoApplyHistoryPageState extends State<AutoApplyHistoryPage> {
  List<Map<String, String>> _successfulApplications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuccessfulApplications();
  }

  Future<void> _loadSuccessfulApplications() async {
    try {
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
      if (userId.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final DatabaseReference userRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('autoApply');

      final DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map;
        final List<Map<String, String>> applications =
            List<Map<String, String>>.from(
          (data['successfulApplications'] ?? []).map((item) {
            if (item is Map) {
              return Map<String, String>.from(item);
            } else if (item is String) {
              // Handle legacy string format
              final parts = item.split(' - ');
              return {
                'title': parts[0],
                'date': parts.length > 1
                    ? parts[1]
                    : DateTime.now().toString().split(' ')[0],
                'link': '',
              };
            }
            return {
              'title': item.toString(),
              'date': DateTime.now().toString().split(' ')[0],
              'link': ''
            };
          }),
        );
        setState(() {
          _successfulApplications = applications;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading applications: $e')),
      );
    }
  }

  void _navigateToJobLink(String url, String title) {
    if (url.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InAppWebViewScreen(
            url: url,
            title: title,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job link not available')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        centerTitle: true,
        title: const Text(
          'Auto Apply History',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5BC0EB),
              ),
            )
          : _successfulApplications.isEmpty
              ? const Center(
                  child: Text(
                    'No successful auto-applications yet.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _successfulApplications.length,
                  itemBuilder: (context, index) {
                    final application = _successfulApplications[index];
                    final jobTitle = application['title'] ?? 'Unknown Job';
                    final applicationDate = application['date'] ?? '';
                    final jobLink = application['link'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: const Color(0xFF1F1F1F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: const BorderSide(
                          color: Color(0xFF5BC0EB),
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _navigateToJobLink(jobLink, jobTitle),
                        borderRadius: BorderRadius.circular(10.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF4CAF50),
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      jobTitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (applicationDate.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Applied on: $applicationDate',
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                jobLink.isNotEmpty
                                    ? Icons.launch
                                    : Icons.link_off,
                                color: jobLink.isNotEmpty
                                    ? const Color(0xFF5BC0EB)
                                    : Colors.grey.shade600,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
