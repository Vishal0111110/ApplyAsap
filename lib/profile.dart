import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';

import 'start_screen.dart';
import 'question_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'web.dart';
import 'auto_apply_history.dart';
import 'notification_service.dart';
import 'gamification_service.dart';
import 'gamification_widgets.dart';
import 'gamification_dashboard.dart';
import 'leaderboard_screen.dart';
import 'course_detailed_page.dart';

int getLanguageIndex(String lang) {
  switch (lang) {
    case "کشميري":
    case "कश्मीरी":
      return 0;
    case "ਪੰਜਾਬੀ":
      return 1;
    case "हरियाणवी":
      return 2;
    case "हिन्दी":
      return 3;
    case "राजस्थानी":
      return 4;
    case "भोजपुरी":
      return 5;
    case "বাংলা":
      return 6;
    case "ગુજરાતી":
      return 7;
    case "অসমীয়া":
      return 8;
    case "ଓଡ଼ିଆ":
      return 9;
    case "मराठी":
      return 10;
    case "தமிழ்":
      return 11;
    case "తెలుగు":
      return 12;
    case "ಕನ್ನಡ":
      return 13;
    case "മലയാളം":
      return 14;
    case "English":
    default:
      return 15;
  }
}

class AccountPage extends StatefulWidget {
  final int languageIndex;
  const AccountPage({Key? key, required this.languageIndex}) : super(key: key);
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  // Define the icon color as a constant variable.
  final Color iconColor = const Color(0xFF5BC0EB);
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  int coinBalance = 0;
  final Map<int, Map<String, String>> translations = {
    0: {
      "profile": "پروفائل",
      "user": "صارف",
      "courses": "کورس",
      "hours": "گھنٹے",
      "rating": "5.0",
      "changePreferences": "ترجیحات بدلو",
      "rewards": "انعامات",
      "notification": "اطلاع",
      "privacy policy": "رازداری کی پالیسی",
      "logout": "لاگ آؤٹ",
    },
    1: {
      "profile": "ਪ੍ਰੋਫ਼ਾਈਲ",
      "user": "ਉਪਭੋਗਤਾ",
      "courses": "ਕੋਰਸ",
      "hours": "ਘੰਟੇ",
      "rating": "5.0",
      "changePreferences": "ਤਰਜੀਹਾਂ ਬਦਲੋ",
      "rewards": "ਇਨਾਮ",
      "notification": "ਸੂਚਨਾਵਾਂ",
      "privacy policy": "ਰਹੱਸਯਤਾ ਦੀ ਨੀਤੀ",
      "logout": "ਲੋਗ ਆਉਟ",
    },
    2: {
      "profile": "प्रोफ़ाइल",
      "user": "यूजर",
      "courses": "कोर्स",
      "hours": "घंटे",
      "rating": "5.0",
      "changePreferences": "बदलियो प्राथमिकताएं",
      "rewards": "इनाम",
      "notification": "सूचनाएं",
      "privacy policy": "गोपनीयता नीति",
      "logout": "लॉग आउट",
    },
    3: {
      "profile": "प्रोफ़ाइल",
      "user": "उपयोगकर्ता",
      "courses": "कोर्स",
      "hours": "घंटे",
      "rating": "5.0",
      "changePreferences": "प्राथमिकताएँ बदलें",
      "rewards": "इनाम",
      "notification": "सूचनाएं",
      "privacy policy": "गोपनीयता नीति",
      "logout": "लॉग आउट",
    },
    4: {
      "profile": "प्रोफ़ाइल",
      "user": "उपयोगकर्ता",
      "courses": "कोर्स",
      "hours": "घंटा",
      "rating": "5.0",
      "changePreferences": "पसंद बदलो",
      "rewards": "इनाम",
      "notification": "सूचनाएं",
      "privacy policy": "गोपनीयता नीति",
      "logout": "लॉग आउट",
    },
    5: {
      "profile": "प्रोफ़ाइल",
      "user": "यूजर",
      "courses": "कोर्स",
      "hours": "घंटा",
      "rating": "5.0",
      "changePreferences": "पसंद बदलीं",
      "rewards": "इनाम",
      "notification": "सूचना",
      "privacy policy": "गोपनीयता नीति",
      "logout": "लॉग आउट",
    },
    6: {
      "profile": "প্রোফাইল",
      "user": "ব্যবহারকারী",
      "courses": "কোর্স",
      "hours": "ঘণ্টা",
      "rating": "5.0",
      "changePreferences": "পছন্দ পরিবর্তন করুন",
      "rewards": "পুরস্কার",
      "notification": "বিজ্ঞপ্তি",
      "privacy policy": "গোপনীয়তা নীতি",
      "logout": "লগ আউট",
    },
    7: {
      "profile": "પ્રોફાઈલ",
      "user": "વપરાશકર્તા",
      "courses": "કોર્સ",
      "hours": "કલાકો",
      "rating": "5.0",
      "changePreferences": "પ્રાધાન્ય બદલો",
      "rewards": "ઇનામ",
      "notification": "સૂચના",
      "privacy policy": "ગોપનીયતા નીતિ",
      "logout": "લોગ આઉટ",
    },
    8: {
      "profile": "প্ৰফাইল",
      "user": "ব্যৱহাৰকাৰী",
      "courses": "কোৰ্ছ",
      "hours": "ঘণ্টা",
      "rating": "5.0",
      "changePreferences": "পছন্দ সলনি কৰক",
      "rewards": "পুৰস্কাৰ",
      "notification": "সুচনা",
      "privacy policy": "গোপনীয়তা নীতি",
      "logout": "লগ আউট",
    },
    9: {
      "profile": "ପ୍ରୋଫାଇଲ",
      "user": "ଉପଯୋଗକର୍ତ୍ତା",
      "courses": "କୋର୍ସ",
      "hours": "ଘଣ୍ଟା",
      "rating": "5.0",
      "changePreferences": "ପସନ୍ଦ ବଦଳାନ୍ତୁ",
      "rewards": "ପୁରସ୍କାର",
      "notification": "ସୂଚନା",
      "privacy policy": "ଗୋପନୀୟତା ନୀତି",
      "logout": "ଲଗ ଆଉଟ",
    },
    10: {
      "profile": "प्रोफाइल",
      "user": "वापरकर्ता",
      "courses": "कोर्सेस",
      "hours": "तास",
      "rating": "5.0",
      "changePreferences": "प्राधान्य बदला",
      "rewards": "बक्षीस",
      "notification": "सूचना",
      "privacy policy": "गोपनीयता धोरण",
      "logout": "लॉग आउट",
    },
    11: {
      "profile": "சுயவிவரம்",
      "user": "பயனர்",
      "courses": "பாடநெறிகள்",
      "hours": "மணித்தியாலங்கள்",
      "rating": "5.0",
      "changePreferences": "விருப்பங்களை மாற்று",
      "rewards": "பரிசுகள்",
      "notification": "அறிவிப்பு",
      "privacy policy": "தனியுரிமைக் கொள்கை",
      "logout": "வெளியேறு",
    },
    12: {
      "profile": "ప్రొఫైల్",
      "user": "వినియోగదారు",
      "courses": "కోర్సులు",
      "hours": "గంటలు",
      "rating": "5.0",
      "changePreferences": "అభిరుచులు మార్చు",
      "rewards": "బహుమతులు",
      "notification": "నోటిఫికేషన్",
      "privacy policy": "గోప్యతా విధానం",
      "logout": "లాగ్ అవుట్",
    },
    13: {
      "profile": "ಪ್ರೊಫೈಲ್",
      "user": "ಬಳಕೆದಾರ",
      "courses": "ಕೋರ್ಸುಗಳು",
      "hours": "ಗಂಟೆಗಳು",
      "rating": "5.0",
      "changePreferences": "ಆಸಕ್ತಿಗಳನ್ನು ಬದಲಾಯಿಸಿ",
      "rewards": "ಪ್ರಶಂಸೆ",
      "notification": "ಅಧಿಸೂಚನೆ",
      "privacy policy": "ಗೋಪ್ಯತಾ ನೀತಿ",
      "logout": "ಲಾಗ್ ಔಟ್",
    },
    14: {
      "profile": "പ്രൊഫൈല്‍",
      "user": "ഉപയോക്താവ്",
      "courses": "കോഴ്സുകൾ",
      "hours": "മണിക്കൂറുകൾ",
      "rating": "5.0",
      "changePreferences": "പ്രധാന്യം മാറ്റുക",
      "rewards": "പ്രതിഫലം",
      "notification": "അറിയിപ്പ്",
      "privacy policy": "സ്വകാര്യത നയം",
      "logout": "ലോഗ്ഔട്ട്",
    },
    15: {
      "profile": "Profile",
      "user": "User",
      "courses": "courses",
      "hours": "hours",
      "rating": "5.0",
      "changePreferences": "Change Preferences",
      "rewards": "Rewards",
      "notification": "Notification",
      "privacy policy": "Privacy Policy",
      "autoApply": "Auto Apply",
      "autoApplyDescription": "Enable auto-apply for jobs with resume",
      "myCourses": "My Courses",
      "logout": "Log Out",
    },
  };
  String t(String key) {
    return translations[widget.languageIndex]?[key] ??
        translations[15]![key] ??
        key;
  }

  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (userId.isEmpty) {
      debugPrint("User is not authenticated.");
      return;
    }
    final DatabaseReference userRef =
        FirebaseDatabase.instance.ref().child('users').child(userId);
    final DataSnapshot snapshot = await userRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      setState(() {
        coinBalance =
            data['coins'] != null ? int.parse(data['coins'].toString()) : 0;
      });
    } else {
      setState(() {
        coinBalance = 0;
      });
      await userRef.set({'coins': 0});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          t("profile"),
          style: const TextStyle(
            fontSize: 20.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: Column(
          children: [
            _buildProfile(),
            const SizedBox(height: 20),
            _buildSection1(),
            const SizedBox(height: 20),
            _buildSection2(),
            const SizedBox(height: 20),
            _buildAutoApplySection(),
            const SizedBox(height: 20),
            _buildSection3(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      children: [
        CustomImage(
          user?.photoURL ?? "assets/images/default_profile.png",
          width: 70,
          height: 70,
          radius: 20,
        ),
        const SizedBox(height: 10),
        Text(
          user?.displayName ?? t("user"),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFFD1D1D1),
          ),
        ),
        const SizedBox(height: 20),
        FutureBuilder<Map<String, dynamic>?>(
          future: GamificationService().getUserStats(user?.uid ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF5BC0EB).withOpacity(0.3),
                  ),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF5BC0EB)),
                    ),
                  ),
                ),
              );
            }

            // Always show clickable gamification header, even if no stats yet
            final userStats = snapshot.data ??
                {
                  'level': 1,
                  'totalPoints': 0,
                  'currentStreak': 0,
                };

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GamificationDashboard(),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF5BC0EB).withOpacity(0.3),
                  ),
                ),
                child: GamificationHeader(userStats: userStats),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecord() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SettingBox(
            title: "0 ${t("courses")}",
            icon: "assets/icons/work.svg",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SettingBox(
            title: "0 ${t("hours")}",
            icon: "assets/icons/time.svg",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SettingBox(
            title: t("rating"),
            icon: "assets/icons/star.svg",
          ),
        ),
      ],
    );
  }

  // Section 1: Contains "Change Preferences".
  Widget _buildSection1() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          SettingItem(
            title: t("changePreferences"),
            leadingIcon: "assets/icons/setting.svg",
            bgIconColor: iconColor,
            onTap: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final currentUserId = user.uid;
                final dbRef = FirebaseDatabase.instance
                    .ref()
                    .child('surveyResponses')
                    .child(currentUserId);
                await dbRef.remove();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const QuestionScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Section 2: Contains "Notification" and "Privacy".
  Widget _buildSection2() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          SettingItem(
            title: t("notification"),
            leadingIcon: "assets/icons/bell.svg",
            bgIconColor: iconColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      NotificationScreen(languageIndex: widget.languageIndex),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          SettingItem(
            title: t("privacy policy"),
            leadingIcon: "assets/icons/shield.svg",
            bgIconColor: iconColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => InAppWebViewScreen(
                    url:
                        "https://www.termsfeed.com/live/27cdd66b-ca31-4f83-81df-1d2a173b3315",
                    title: t("privacy policy"),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Auto Apply Section
  Widget _buildAutoApplySection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          SettingItem(
            title: t("autoApply"),
            leadingIcon: "assets/icons/work.svg",
            bgIconColor: iconColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      AutoApplyScreen(languageIndex: widget.languageIndex),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          SettingItem(
            title: "Auto Apply History",
            leadingIcon: "assets/icons/time.svg",
            bgIconColor: iconColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AutoApplyHistoryPage(),
                ),
              );
            },
          ),
          SettingItem(
            title: "Interview History",
            leadingIcon: "assets/icons/work.svg",
            bgIconColor: iconColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => InterviewHistoryScreen(
                      languageIndex: widget.languageIndex),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Section 3: Log Out.
  Widget _buildSection3() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(5),
      ),
      child: SettingItem(
        title: t("logout"),
        leadingIcon: "assets/icons/logout.svg",
        bgIconColor: iconColor,
        onTap: () async {
          await FirebaseAuth.instance.signOut();
          await _googleSignIn.signOut();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const StartScreen(),
              ),
            );
          }
        },
      ),
    );
  }
}

class InterviewHistoryScreen extends StatefulWidget {
  final int languageIndex;
  const InterviewHistoryScreen({Key? key, required this.languageIndex})
      : super(key: key);

  @override
  _InterviewHistoryScreenState createState() => _InterviewHistoryScreenState();
}

class _InterviewHistoryScreenState extends State<InterviewHistoryScreen> {
  List<Map<String, dynamic>> _interviewSessions = [];
  List<Map<String, dynamic>> _filteredSessions = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  final Map<int, Map<String, String>> translations = {
    15: {
      "interviewHistory": "Interview History",
      "noInterviews": "No interview history yet",
      "searchInterviews": "Search interviews...",
      "question": "Question",
      "yourAnswer": "Your Answer",
      "feedback": "Feedback",
      "score": "Score",
      "interviewType": "Interview Type",
      "career": "Career",
      "date": "Date",
      "duration": "Duration",
      "timeTaken": "Time Taken",
      "loading": "Loading...",
      "technical": "Technical",
      "hr": "HR",
      "hiringManager": "Hiring Manager",
      "questions": "Questions",
      "totalScore": "Total Score",
      "averageScore": "Average Score",
    },
  };

  String t(String key) {
    return translations[widget.languageIndex]?[key] ??
        translations[15]![key] ??
        key;
  }

  @override
  void initState() {
    super.initState();
    _loadInterviewHistory();
    _searchController.addListener(_filterSessions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInterviewHistory() async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (userId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final DatabaseReference interviewRef =
          FirebaseDatabase.instance.ref().child('interviewResponses');

      final DataSnapshot snapshot = await interviewRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map;
        List<Map<String, dynamic>> sessions = [];

        data.forEach((key, value) {
          if (value is Map && value['userId'] == userId) {
            final interview = {
              'id': key,
              'question': value['question'] ?? '',
              'answer': value['answer'] ?? '',
              'feedback': value['feedback'] ?? '',
              'score': value['score'] ?? 0,
              'career': value['career'] ?? '',
              'jobTitle':
                  value['jobTitle'] ?? _extractJobTitle(value['career'] ?? ''),
              'interviewType': value['interviewType'] ?? '',
              'timestamp': value['timestamp'] ?? '',
              'questionNumber': value['questionNumber'] ?? 0,
            };

            // Each interview is treated as an individual session
            final dateTime = DateTime.parse(interview['timestamp']);
            final jobTitle = interview['jobTitle'] as String;
            final interviewType = interview['interviewType'] as String;

            // Create individual session for each interview
            sessions.add({
              'sessionKey': key, // Use the unique Firebase key as session key
              'career': jobTitle,
              'interviewType': interviewType,
              'date': dateTime,
              'duration': const Duration(
                  minutes: 1), // Default duration for individual interviews
              'questions': [interview], // Each session has one question
              'totalScore': interview['score'] ?? 0,
              'averageScore': interview['score'] ?? 0,
              'questionCount': 1,
            });
          }
        });

        // Sort sessions by date (most recent first)
        sessions.sort(
            (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

        setState(() {
          _interviewSessions = sessions;
          _filteredSessions = sessions;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading interview history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterSessions() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredSessions = _interviewSessions;
      });
    } else {
      setState(() {
        _filteredSessions = _interviewSessions.where((session) {
          final career = (session['career'] as String).toLowerCase();
          final interviewType =
              (session['interviewType'] as String).toLowerCase();
          return career.contains(query) || interviewType.contains(query);
        }).toList();
      });
    }
  }

  String _formatInterviewType(String type) {
    switch (type.toLowerCase()) {
      case 'technical':
        return t("technical");
      case 'hr':
        return t("hr");
      case 'hiring_manager':
        return t("hiringManager");
      default:
        return type;
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.orange;
    return Colors.red;
  }

  String _extractJobTitle(String career) {
    if (career.isEmpty) return 'Unknown Job';

    // Handle JSON format (from questionnaire answers)
    try {
      final jsonData = jsonDecode(career);
      if (jsonData is Map && jsonData.containsKey('jobTitle')) {
        return jsonData['jobTitle'] ?? 'Unknown Job';
      }
    } catch (e) {
      // Not JSON, continue with string parsing
    }

    // Handle formatted string like "Web Developer: Create amazing websites..."
    if (career.contains(':')) {
      final parts = career.split(':');
      if (parts.length >= 2) {
        final jobTitle = parts[0].trim();

        // Clean up common prefixes that might appear
        if (jobTitle.toLowerCase().startsWith('i want to be a') ||
            jobTitle.toLowerCase().startsWith('i want to become')) {
          return jobTitle.substring(jobTitle.indexOf('a') + 1).trim();
        }

        // Check if this looks like a job title followed by description
        // Job titles are typically 1-4 words, not too long
        final titleWords = jobTitle.split(' ');
        if (titleWords.length <= 4 && jobTitle.length <= 50) {
          return jobTitle;
        }
      }
    }

    // If no special format detected, return the career as is
    // but limit length for display
    if (career.length > 30) {
      return career.substring(0, 27) + '...';
    }

    return career;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          t("interviewHistory"),
          style: const TextStyle(
            fontSize: 20.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: t("searchInterviews"),
                hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF5BC0EB)),
                filled: true,
                fillColor: const Color(0xFF1F1F1F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF5BC0EB)),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF5BC0EB)),
                    ),
                  )
                : _filteredSessions.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? t("noInterviews")
                              : "No matching interviews found",
                          style: const TextStyle(
                            fontSize: 18.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredSessions.length,
                        itemBuilder: (context, index) {
                          final session = _filteredSessions[index];
                          return _buildSessionCard(session);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: Key(session['sessionKey'] ?? session['id']),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 28,
          ),
        ),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1F1F1F),
                title: const Text(
                  'Delete Interview Session',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  'Are you sure you want to delete this entire interview session? This action cannot be undone.',
                  style: TextStyle(color: Color(0xFFD1D1D1)),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Color(0xFF5BC0EB)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (direction) {
          _deleteInterviewSession(session);
        },
        child: Card(
          color: const Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade800),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InterviewDetailScreen(
                    session: session,
                    languageIndex: widget.languageIndex,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session['career'] ?? 'Unknown Job',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getScoreColor(session['averageScore'] ?? 0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${session['averageScore'] ?? 0}/10',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Details Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          Icons.calendar_today,
                          _formatDate(session['date']),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFFB0B0B0),
          size: 16,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _deleteInterviewSession(Map<String, dynamic> session) async {
    try {
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
      if (userId.isEmpty) {
        debugPrint("User not authenticated, cannot delete interview session.");
        return;
      }

      // Delete the interview record from Firebase
      final sessionKey = session['sessionKey'] ?? session['id'];
      if (sessionKey != null) {
        final DatabaseReference interviewRef = FirebaseDatabase.instance
            .ref()
            .child('interviewResponses')
            .child(sessionKey);
        await interviewRef.remove();

        debugPrint("Interview session deleted successfully: $sessionKey");

        // Update the UI by removing the session from the list
        setState(() {
          _interviewSessions
              .removeWhere((s) => (s['sessionKey'] ?? s['id']) == sessionKey);
          _filteredSessions = List.from(_interviewSessions);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interview session deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting interview session: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete interview session: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class InterviewDetailScreen extends StatefulWidget {
  final Map<String, dynamic> session;
  final int languageIndex;

  const InterviewDetailScreen({
    Key? key,
    required this.session,
    required this.languageIndex,
  }) : super(key: key);

  @override
  _InterviewDetailScreenState createState() => _InterviewDetailScreenState();
}

class CorrectAnswerService {
  static final CorrectAnswerService _instance =
      CorrectAnswerService._internal();
  factory CorrectAnswerService() => _instance;
  CorrectAnswerService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<String?> getStoredCorrectAnswer(String questionId) async {
    try {
      final snapshot =
          await _database.child('correctAnswers').child(questionId).get();

      if (snapshot.exists) {
        final data = snapshot.value as Map;
        return data['answer'] as String?;
      }
    } catch (e) {
      debugPrint('Error getting stored correct answer: $e');
    }
    return null;
  }

  Future<void> storeCorrectAnswer(String questionId, String answer,
      String question, String career, String interviewType) async {
    try {
      await _database.child('correctAnswers').child(questionId).set({
        'answer': answer,
        'question': question,
        'career': career,
        'interviewType': interviewType,
        'timestamp': DateTime.now().toIso8601String(),
      });
      debugPrint(
          'Correct answer stored successfully for question: $questionId');
    } catch (e) {
      debugPrint('Error storing correct answer: $e');
    }
  }
}

class _InterviewDetailScreenState extends State<InterviewDetailScreen> {
  final Map<int, Map<String, String>> translations = {
    15: {
      "question": "Question",
      "yourAnswer": "Your Answer",
      "feedback": "Feedback",
      "score": "Score",
      "timeTaken": "Time Taken",
      "date": "Date",
      "noFeedback": "No feedback provided",
      "noAnswer": "No answer provided",
      "correctAnswer": "Correct Answer",
      "getCorrectAnswer": "Get Correct Answer",
      "loading": "Loading...",
      "error": "Error",
      "searchQuestions": "Search questions...",
      "noMatchingQuestions": "No matching questions found",
    },
  };

  String t(String key) {
    return translations[widget.languageIndex]?[key] ??
        translations[15]![key] ??
        key;
  }

  Map<String, String> _correctAnswers = {};
  Map<String, bool> _loadingStates = {};
  final TextEditingController _questionSearchController =
      TextEditingController();
  List<Map<String, dynamic>> _filteredQuestions = [];
  List<Map<String, dynamic>> _allQuestions = [];

  @override
  void initState() {
    super.initState();
    _allQuestions = List<Map<String, dynamic>>.from(
        widget.session['questions'] as List<Map<String, dynamic>>);
    _filteredQuestions = List<Map<String, dynamic>>.from(_allQuestions);
    _questionSearchController.addListener(_filterQuestions);
    _loadAllCorrectAnswers();
  }

  @override
  void dispose() {
    _questionSearchController.dispose();
    super.dispose();
  }

  void _filterQuestions() {
    final query = _questionSearchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredQuestions = List<Map<String, dynamic>>.from(_allQuestions);
      });
    } else {
      setState(() {
        _filteredQuestions = _allQuestions.where((question) {
          final questionText = (question['question'] as String).toLowerCase();
          final answerText = (question['answer'] as String).toLowerCase();
          final feedbackText =
              (question['feedback'] as String?)?.toLowerCase() ?? '';
          return questionText.contains(query) ||
              answerText.contains(query) ||
              feedbackText.contains(query);
        }).toList();
      });
    }
  }

  Future<String> _getCorrectAnswer(
      String question, String career, String interviewType) async {
    try {
      // Load API key from asset.
      String apiKey;
      try {
        apiKey = await rootBundle.loadString('assets/gemini.key');
        if (apiKey.trim().isEmpty) {
          throw Exception("API key is empty");
        }
      } catch (e) {
        debugPrint("Error loading API key: $e");
        throw Exception("Failed to load Gemini API key");
      }

      final endpoint =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?alt=json&key=$apiKey";

      // Create system instruction for getting correct answer
      String systemInstruction = '''
You are an expert interviewer providing the ideal answer for a job interview question.
Provide a comprehensive, well-structured answer that demonstrates deep knowledge and expertise.
For technical questions, include:
- Clear explanation of concepts
- Code examples where appropriate
- Best practices and industry standards
- Time/space complexity analysis for algorithms

For HR questions, include:
- STAR method responses (Situation, Task, Action, Result)
- Specific examples and metrics
- Leadership and soft skills demonstration

Format the answer professionally as if the candidate is speaking directly to the interviewer.
Make it detailed but concise, showing both technical depth and communication skills.
''';

      final payload = jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': systemInstruction}
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text':
                    'Provide the ideal answer for this $interviewType interview question for a $career position:\n\nQuestion: $question\n\nPlease give a comprehensive, professional answer that would impress interviewers.'
              }
            ],
          },
        ],
        'safetySettings': [
          {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
          {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_NONE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_NONE'
          },
        ],
        'generationConfig': {
          'candidateCount': 1,
          'temperature': 0.7,
          'topP': 0.8,
        },
      });

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        final text = jsonResp['candidates']?[0]?['content']?['parts']?[0]
            ?['text'] as String?;
        if (text != null && text.isNotEmpty) {
          return text;
        } else {
          throw Exception("Empty response from Gemini API");
        }
      } else {
        throw Exception("Failed to get correct answer: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error getting correct answer: $e");
      throw Exception("Failed to get correct answer. Please try again.");
    }
  }

  Future<void> _loadAllCorrectAnswers() async {
    for (final question in _allQuestions) {
      final questionId = question['id'];
      final storedAnswer =
          await CorrectAnswerService().getStoredCorrectAnswer(questionId);

      if (storedAnswer != null) {
        setState(() {
          _correctAnswers[questionId] = storedAnswer;
        });
      } else {
        // If not stored, fetch and store it
        await _fetchCorrectAnswer(question, widget.session['career'],
            widget.session['interviewType']);
      }
    }
  }

  Future<void> _fetchCorrectAnswer(Map<String, dynamic> question, String career,
      String interviewType) async {
    final questionId = question['id'];
    setState(() {
      _loadingStates[questionId] = true;
    });

    try {
      final correctAnswer =
          await _getCorrectAnswer(question['question'], career, interviewType);

      // Store the answer in Firebase
      await CorrectAnswerService().storeCorrectAnswer(
        questionId,
        correctAnswer,
        question['question'],
        career,
        interviewType,
      );

      setState(() {
        _correctAnswers[questionId] = correctAnswer;
        _loadingStates[questionId] = false;
      });
    } catch (e) {
      debugPrint("Error fetching correct answer: $e");
      setState(() {
        _loadingStates[questionId] = false;
      });
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get correct answer: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  String _calculateTimeTaken(int index, List<Map<String, dynamic>> questions) {
    if (index >= questions.length - 1) {
      return "Last question";
    }

    try {
      final currentTime = DateTime.parse(questions[index]['timestamp']);
      final nextTime = DateTime.parse(questions[index + 1]['timestamp']);
      final duration = nextTime.difference(currentTime);

      if (duration.inHours > 0) {
        return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
      } else if (duration.inMinutes > 0) {
        return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
      } else {
        return '${duration.inSeconds}s';
      }
    } catch (e) {
      return "Unknown";
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.orange;
    return Colors.red;
  }

  Future<void> _deleteInterviewQuestion(Map<String, dynamic> question) async {
    try {
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
      if (userId.isEmpty) {
        debugPrint("User not authenticated, cannot delete interview question.");
        return;
      }

      // Delete the interview question from Firebase
      final questionId = question['id'];
      if (questionId != null) {
        final DatabaseReference questionRef = FirebaseDatabase.instance
            .ref()
            .child('interviewResponses')
            .child(questionId);
        await questionRef.remove();

        debugPrint("Interview question deleted successfully: $questionId");

        // Update the UI by removing the question from the list
        setState(() {
          _allQuestions.removeWhere((q) => q['id'] == questionId);
          _filteredQuestions = List<Map<String, dynamic>>.from(_allQuestions);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interview question deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting interview question: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete interview question: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.session['career'] ?? '',
          style: const TextStyle(
            fontSize: 18.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _questionSearchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: t("searchQuestions"),
                hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF5BC0EB)),
                filled: true,
                fillColor: const Color(0xFF1F1F1F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF5BC0EB)),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _filteredQuestions.isEmpty &&
                    _questionSearchController.text.isNotEmpty
                ? Center(
                    child: Text(
                      t("noMatchingQuestions"),
                      style: const TextStyle(
                        fontSize: 18.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredQuestions.length,
                    itemBuilder: (context, index) {
                      final question = _filteredQuestions[index];
                      final originalIndex = _allQuestions.indexOf(question);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Dismissible(
                          key: Key(question['id'] ?? 'question_$index'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: const Color(0xFF1F1F1F),
                                  title: const Text(
                                    'Delete Interview Question',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to delete this interview question? This action cannot be undone.',
                                    style: TextStyle(color: Color(0xFFD1D1D1)),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text(
                                        'Cancel',
                                        style:
                                            TextStyle(color: Color(0xFF5BC0EB)),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) {
                            _deleteInterviewQuestion(question);
                          },
                          child: Card(
                            color: const Color(0xFF1F1F1F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade800),
                            ),
                            child: InkWell(
                              onTap: () {
                                _showQuestionDetailDialog(context, question,
                                    originalIndex, _allQuestions);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Question preview
                                    Text(
                                      question['question'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    const SizedBox(height: 12),

                                    // Score
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getScoreColor(
                                            question['score'] ?? 0),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${question['score'] ?? 0}/10',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Timestamp
                                    Text(
                                      _formatDateTime(
                                          question['timestamp'] ?? ''),
                                      style: const TextStyle(
                                        color: Color(0xFFB0B0B0),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showQuestionDetailDialog(
      BuildContext context,
      Map<String, dynamic> question,
      int index,
      List<Map<String, dynamic>> questions) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with score
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t("question"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getScoreColor(question['score'] ?? 0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${question['score'] ?? 0}/10',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Question
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      question['question'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Answer
                  Text(
                    t("yourAnswer"),
                    style: const TextStyle(
                      color: Color(0xFF5BC0EB),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      question['answer'] ?? t("noAnswer"),
                      style: const TextStyle(
                        color: Color(0xFFD1D1D1),
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Feedback
                  if (question['feedback'] != null &&
                      question['feedback'].toString().isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t("feedback"),
                          style: const TextStyle(
                            color: Color(0xFF5BC0EB),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            question['feedback'] ?? t("noFeedback"),
                            style: const TextStyle(
                              color: Color(0xFFD1D1D1),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Time details
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t("date"),
                              style: const TextStyle(
                                color: Color(0xFFB0B0B0),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDateTime(question['timestamp'] ?? ''),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t("timeTaken"),
                              style: const TextStyle(
                                color: Color(0xFFB0B0B0),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _calculateTimeTaken(index, questions),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Get Correct Answer Button or Display
                  if (_correctAnswers.containsKey(question['id']))
                    // Show the stored answer directly
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          t("correctAnswer"),
                          style: const TextStyle(
                            color: Color(0xFF5BC0EB),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade600),
                          ),
                          child: Text(
                            _correctAnswers[question['id']] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // Show button to get answer
                    Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loadingStates[question['id']] == true
                            ? null
                            : () => _fetchCorrectAnswer(
                                question,
                                widget.session['career'],
                                widget.session['interviewType']),
                        icon: _loadingStates[question['id']] == true
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.lightbulb_outline, size: 18),
                        label: Text(
                          _loadingStates[question['id']] == true
                              ? t("loading")
                              : t("getCorrectAnswer"),
                          style: const TextStyle(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5BC0EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Close button
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Color(0xFF5BC0EB),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AutoApplyScreen extends StatefulWidget {
  final int languageIndex;
  const AutoApplyScreen({Key? key, required this.languageIndex})
      : super(key: key);

  @override
  _AutoApplyScreenState createState() => _AutoApplyScreenState();
}

class _AutoApplyScreenState extends State<AutoApplyScreen> {
  bool _autoApplyEnabled = false;
  String? _resumePath;
  List<String> _successfulApplications = [];

  final Map<int, Map<String, String>> translations = {
    15: {
      "autoApply": "Auto Apply",
      "enableAutoApply": "Enable Auto Apply",
      "uploadResume": "Upload Resume",
      "resumeUploaded": "Resume Uploaded",
      "successfulApplications": "Successful Applications",
      "noApplications": "No successful applications yet",
      "toggleDescription":
          "Automatically apply to jobs using your resume and AI-generated answers",
    },
  };

  String t(String key) {
    return translations[widget.languageIndex]?[key] ??
        translations[15]![key] ??
        key;
  }

  @override
  void initState() {
    super.initState();
    _loadAutoApplySettings();
  }

  Future<void> _loadAutoApplySettings() async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (userId.isEmpty) return;

    final DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(userId)
        .child('autoApply');
    final DataSnapshot snapshot = await userRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      setState(() {
        _autoApplyEnabled = data['enabled'] ?? false;
        _resumePath = data['resumePath'];
        _successfulApplications =
            List<String>.from(data['successfulApplications'] ?? []);
      });
    }
  }

  Future<void> _saveAutoApplySettings() async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (userId.isEmpty) return;

    final DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(userId)
        .child('autoApply');
    await userRef.set({
      'enabled': _autoApplyEnabled,
      'resumePath': _resumePath,
      'successfulApplications': _successfulApplications,
    });
  }

  Future<void> _uploadResume() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

        if (userId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated')),
          );
          return;
        }

        // Check if file has valid data - improved validation
        bool isValidFile = false;
        Uint8List? fileData;

        // First, try to use file.path if available (more reliable)
        if (file.path != null && file.path!.isNotEmpty) {
          try {
            final fileObj = File(file.path!);
            if (await fileObj.exists()) {
              fileData = await fileObj.readAsBytes();
              if (fileData.isNotEmpty) {
                isValidFile = true;
              }
            }
          } catch (e) {
            debugPrint('Error reading file from path: $e');
          }
        }

        // If path didn't work, try using bytes directly
        if (!isValidFile && file.bytes != null && file.bytes!.isNotEmpty) {
          fileData = file.bytes;
          isValidFile = true;
        }

        // Additional check: ensure file size is reasonable (> 0 bytes)
        if (!isValidFile ||
            fileData == null ||
            fileData.isEmpty ||
            file.size == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Selected file is empty or invalid. Please select a valid PDF/DOC file.')),
          );
          return;
        }

        // Check file size (max 10MB)
        if (file.size > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'File size too large. Please select a file smaller than 10MB.')),
          );
          return;
        }

        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading resume...')),
        );

        // Store resume data directly in Firebase Realtime Database
        String fileName = '${userId}_resume.${file.extension ?? 'pdf'}';

        // Convert file data to base64 for storage
        String base64Data = base64Encode(fileData);

        // Parse resume data and store it
        await _parseAndStoreResumeData(base64Data, fileName);

        setState(() {
          _resumePath = fileName; // Store filename instead of download URL
        });

        await _saveAutoApplySettings();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Resume uploaded and parsed successfully')),
        );
      }
    } catch (e) {
      debugPrint('Resume upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading resume: ${e.toString()}')),
      );
    }
  }

  Future<void> _parseAndStoreResumeData(
      String downloadUrl, String fileName) async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
      if (userId.isEmpty) return;

      // For now, we'll store basic metadata. In a real implementation,
      // you would use a service like Google Cloud Vision API or similar
      // to extract text from PDF/DOC files
      Map<String, dynamic> resumeData = {
        'fileName': fileName,
        'downloadUrl': downloadUrl,
        'uploadedAt': DateTime.now().toIso8601String(),
        'fileSize': 0, // You could get this from the file
        'parsed': false, // Set to true when actual parsing is implemented
        'extractedText': '', // This would contain the parsed text
        'skills': [], // Extracted skills
        'experience': [], // Extracted experience
        'education': [], // Extracted education
      };

      // Store resume data in Firebase Database
      DatabaseReference resumeRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('resumeData');

      await resumeRef.set(resumeData);

      debugPrint('Resume data stored successfully');
    } catch (e) {
      debugPrint('Error storing resume data: $e');
      // Don't throw error here as the upload was successful
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          t("autoApply"),
          style: const TextStyle(
            fontSize: 20.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle Section
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t("enableAutoApply"),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Switch(
                        value: _autoApplyEnabled,
                        onChanged: (value) {
                          setState(() {
                            _autoApplyEnabled = value;
                          });
                          _saveAutoApplySettings();
                        },
                        activeColor: const Color(0xFF5BC0EB),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t("toggleDescription"),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB0B0B0),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Resume Upload Section
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t("uploadResume"),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _uploadResume,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5BC0EB),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(_resumePath != null
                        ? t("resumeUploaded")
                        : t("uploadResume")),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Successful Applications Section
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t("successfulApplications"),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _successfulApplications.isEmpty
                      ? Text(
                          t("noApplications"),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFB0B0B0),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _successfulApplications.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                _successfulApplications[index],
                                style: const TextStyle(color: Colors.white),
                              ),
                              leading: const Icon(
                                Icons.check_circle,
                                color: Color(0xFF5BC0EB),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A simple CustomImage widget implementation.
class CustomImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final double radius;

  const CustomImage(
    this.imageUrl, {
    Key? key,
    required this.width,
    required this.height,
    this.radius = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey,
            child: const Icon(Icons.person, size: 40),
          );
        },
      ),
    );
  }
}

class SettingBox extends StatelessWidget {
  const SettingBox({
    Key? key,
    required this.title,
    required this.icon,
    this.color = const Color(0xFFFFFFFF),
  }) : super(key: key);

  final String title;
  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A2A2A).withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            icon,
            color: color,
            width: 22,
            height: 22,
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }
}

class SettingItem extends StatelessWidget {
  final String? leadingIcon;
  final Color leadingIconColor;
  final Color bgIconColor;
  final String title;
  final GestureTapCallback? onTap;
  final Widget? trailingWidget;

  const SettingItem({
    Key? key,
    required this.title,
    this.onTap,
    this.leadingIcon,
    this.leadingIconColor = const Color(0xFFFFFFFF),
    this.bgIconColor = const Color(0xFF5BC0EB),
    this.trailingWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: leadingIcon != null ? _buildItemWithPrefixIcon() : _buildItem(),
      ),
    );
  }

  Widget _buildPrefixIcon() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bgIconColor,
        shape: BoxShape.circle,
      ),
      child: SvgPicture.asset(
        leadingIcon!,
        color: leadingIconColor,
        width: 22,
        height: 22,
      ),
    );
  }

  Widget _buildItemWithPrefixIcon() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPrefixIcon(),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFFFFFFF),
            ),
          ),
        ),
        trailingWidget ??
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFB0B0B0),
              size: 17,
            )
      ],
    );
  }

  Widget _buildItem() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFFFFFFF),
            ),
          ),
        ),
        trailingWidget ??
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFB0B0B0),
              size: 17,
            )
      ],
    );
  }
}

class RewardsScreen extends StatelessWidget {
  final int languageIndex;
  RewardsScreen({Key? key, required this.languageIndex}) : super(key: key);

  final Map<int, Map<String, String>> translations = {
    0: {
      "rewards": "انعامات",
      "rewardsContent":
          "یہ وہ جگہ ہے جہاں آپ اپنے انعامات کا سراغ لگا سکتے ہیں۔ ہمارے انعامی سکے بلاکچین کے ذریعے محفوظ ہیں اور جلد ہی دوسرے پلیٹ فارمز پر مصنوعات خریدنے اور انہیں تبدیل کرنے کے لیے قابل تجارت بنائے جائیں گے۔",
    },
    1: {
      "rewards": "ਇਨਾਮ",
      "rewardsContent":
          "ਇੱਥੇ ਤੁਸੀਂ ਆਪਣੇ ਇਨਾਮਾਂ ਦੀ ਟਰੈਕਿੰਗ ਕਰ ਸਕਦੇ ਹੋ। ਸਾਡੇ ਇਨਾਮੀ ਸਿੱਕੇ ਬਲਾਕਚੇਨ ਦੁਆਰਾ ਬੈਕ ਕੀਤੇ ਗਏ ਹਨ ਅਤੇ ਜਲਦ ਹੀ ਉਨ੍ਹਾਂ ਨੂੰ ਹੋਰ ਪਲੇਟਫਾਰਮਾਂ 'ਤੇ ਉਤਪਾਦ ਖਰੀਦਣ ਅਤੇ ਬਦਲਣ ਲਈ ਵਪਾਰਯੋਗ ਬਣਾਇਆ ਜਾਵੇਗਾ।",
    },
    2: {
      "rewards": "इनाम",
      "rewardsContent":
          "यह वह जगह है जहां आप अपने इनामों को ट्रैक कर सकते हैं। हमारे इनामी सिक्के ब्लॉकचेन द्वारा समर्थित हैं और जल्द ही अन्य प्लेटफार्मों पर उत्पाद खरीदने और उन्हें बदलने के लिए व्यापार योग्य बनाए जाएंगे।",
    },
    3: {
      "rewards": "इनाम",
      "rewardsContent":
          "यह वह जगह है जहां आप अपने इनामों को ट्रैक कर सकते हैं। हमारे इनामी सिक्के ब्लॉकचेन द्वारा समर्थित हैं और जल्द ही अन्य प्लेटफार्मों पर उत्पाद खरीदने और उन्हें बदलने के लिए व्यापार योग्य बनाए जाएंगे।",
    },
    4: {
      "rewards": "इनाम",
      "rewardsContent":
          "ई जगह बा जहाँ रउआ आपन इनाम के ट्रैक कर सकेनी। हमार इनामी सिक्का ब्लॉकचेन से समर्थित बा अउर जल्दी ही ओह के अन्य प्लेटफार्म पर उत्पाद खरीदे आ बदले खातिर ट्रेडेबल बनावल जाई।",
    },
    5: {
      "rewards": "इनाम",
      "rewardsContent":
          "ई जगह बा जहाँ रउआ आपन इनाम ट्रैक कर सकेनी। हमनी के इनामी सिक्का ब्लॉकचेन से समर्थित बा अउर जल्दी ही अन्य प्लेटफार्म पर उत्पाद खरीदे आ बदले खातिर ट्रेडेबल बनावल जाई।",
    },
    6: {
      "rewards": "পুরস্কার",
      "rewardsContent":
          "এখানে আপনি আপনার পুরস্কার ট্র্যাক করতে পারেন। আমাদের পুরস্কার কয়েন ব্লকচেইনের মাধ্যমে সুরক্ষিত এবং শীঘ্রই অন্যান্য প্ল্যাটফর্মে পণ্য কেনার এবং পরিবর্তনের জন্য বিনিময়যোগ্য করা হবে।",
    },
    7: {
      "rewards": "ઇનામ",
      "rewardsContent":
          "આ તે જગ્યા છે જ્યાં તમે તમારા ઇનામોનું ટ્રેકિંગ કરી શકો છો. અમારા ઇનામી સિક્કા બ્લોકચેઇન દ્વારા સપોર્ટેડ છે અને ટૂંક સમયમાં અન્ય પ્લેટફોર્મ પર ઉત્પાદનો ખરીદવા અને તેમને બદલવા માટે વેપારી બનાવવામાં આવશે.",
    },
    8: {
      "rewards": "পুৰস্কাৰ",
      "rewardsContent":
          "এইটো সেই স্থান য'ত আপুনি আপোনাৰ পুৰস্কাৰ অনুসৰণ কৰিব পাৰে। আমাৰ পুৰস্কাৰ মুদ্ৰা ব্লকচেইন দ্বাৰা সমৰ্থিত আৰু শীঘ্ৰেই আন প্লেটফৰ্মত সামগ্ৰী কিনিবলৈ আৰু সলনি কৰিবলৈ ব্যৱসায়যোগ্য হ'ব।",
    },
    9: {
      "rewards": "ପୁରସ୍କାର",
      "rewardsContent":
          "ଏଠି ଆପଣ ଆପଣଙ୍କର ପୁରସ୍କାର ଟ୍ର୍ୟାକ୍ କରିପାରିବେ। ଆମର ପୁରସ୍କାର ସିକ୍କାଗୁଡ଼ିକ ବ୍ଲକଚେନ୍ ଦ୍ଵାରା ଦିଆଯାଇଛି ଏବଂ ଶୀଘ୍ର ଅନ୍ୟାନ୍ୟ ପ୍ଲାଟଫର୍ମରେ ପଦାର୍ଥ କ୍ରୟ ଏବଂ ପରିବର୍ତ୍ତନ ପାଇଁ ବ୍ୟବସାୟ ଯୋଗ୍ୟ ହେବ।",
    },
    10: {
      "rewards": "बक्षीस",
      "rewardsContent":
          "ही ती जागा आहे जिथे तुम्ही तुमच्या बक्षीसांचे ट्रॅकिंग करू शकता. आमची बक्षीस नाणी ब्लॉकचेनने समर्थित आहेत आणि लवकरच ती इतर प्लॅटफॉर्मवर उत्पादने खरेदी करण्यासाठी आणि एक्सचेंज करण्यासाठी व्यापारयोग्य केली जातील.",
    },
    11: {
      "rewards": "பரிசுகள்",
      "rewardsContent":
          "இது நீங்கள் உங்கள் பரிசுகளை கண்காணிக்கக்கூடிய இடம். எங்கள் பரிசு நாணயங்கள் பிளாக்செயினால் ஆதரிக்கப்படுகின்றன மற்றும் விரைவில் பிற தளங்களில் பொருட்களை வாங்கவும் பரிமாறவும் வணிகத்திற்காக மாற்றப்படும்.",
    },
    12: {
      "rewards": "బహుమతులు",
      "rewardsContent":
          "ఇది మీరు మీ బహుమతులను ట్రాక్ చేయగలిగే స్థలం. మా బహుమతుల నాణేలు బ్లాక్‌చైన్ ద్వారా మద్దతు పొందాయి మరియు త్వరలో ఇతర ప్లాట్‌ఫారమ్‌లపై ఉత్పత్తులను కొనుగోలు చేయడానికి మరియు మార్చడానికి ట్రేడబుల్‌గా మారతాయి.",
    },
    13: {
      "rewards": "ಪ್ರಶಂಸೆ",
      "rewardsContent":
          "ಇದು ನೀವು ನಿಮ್ಮ ಪ್ರಶಸ್ತಿಗಳನ್ನು ಹಿಂಬಾಲಿಸಬಹುದಾದ ಸ್ಥಳ. ನಮ್ಮ ಪ್ರಶಸ್ತಿ ನಾಣ್ಯಗಳು ಬ್ಲಾಕ್‌ಚೈನ್ ಮೂಲಕ ಬೆಂಬಲಿತವಾಗಿವೆ ಮತ್ತು ಬೇರೆ ಪ್ಲಾಟ್‌ಫಾರ್ಮ್‌ಗಳಲ್ಲಿ ಉತ್ಪನ್ನಗಳನ್ನು ಖರೀದಿಸಲು ಮತ್ತು ವಿನಿಮಯ ಮಾಡಲು ಶೀಘ್ರದಲ್ಲೇ ವ್ಯಾಪಾರಯೋಗ್ಯವಾಗುತ್ತವೆ.",
    },
    14: {
      "rewards": "പ്രതിഫലം",
      "rewardsContent":
          "ഇത് നിങ്ങൾക്ക് നിങ്ങളുടെ പ്രതിഫലങ്ങൾ ട്രാക്ക് ചെയ്യാൻ കഴിയുന്ന സ്ഥലം. ഞങ്ങളുടെ പ്രതിഫല നാണയങ്ങൾ ബ്ലോക്ക്ചെയിനിന്റെ പിന്തുണയോടെ ഉണ്ട്, എത്രയും വേഗം മറ്റ് പ്ലാറ്റ്ഫോമുകളിൽ ഉൽപ്പന്നങ്ങൾ വാങ്ങുന്നതിനും വിനിമയം നടത്തുന്നതിനുമായി വ്യാപാരയോഗ്യമാകും.",
    },
    15: {
      "rewards": "Rewards",
      "rewardsContent":
          "This is where you can track your rewards. Our reward coins are backed by blockchain and will soon be made tradable to buy products on other platforms and convert them.",
    },
  };

  String t(String key) {
    return translations[languageIndex]?[key] ?? translations[15]![key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t("rewards"),
          style: const TextStyle(
            fontSize: 20.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            t("rewardsContent"),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20.0,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationScreen extends StatefulWidget {
  final int languageIndex;
  const NotificationScreen({Key? key, required this.languageIndex})
      : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  final Map<int, Map<String, String>> translations = {
    0: {
      "notification": "اطلاع",
      "noNotifications": "کوئی اطلاع نہیں",
      "markAsRead": "پڑھیں ہوئی نشان زد کریں",
      "delete": "حذف کریں",
      "loading": "لوڈ ہو رہا ہے...",
    },
    1: {
      "notification": "ਸੂਚਨਾਵਾਂ",
      "noNotifications": "ਕੋਈ ਸੂਚਨਾ ਨਹੀਂ",
      "markAsRead": "ਪੜ੍ਹੀ ਹੋਈ ਮਾਰਕ ਕਰੋ",
      "delete": "ਮਿਟਾਓ",
      "loading": "ਲੋਡ ਹੋ ਰਿਹਾ ਹੈ...",
    },
    2: {
      "notification": "सूचनाएं",
      "noNotifications": "कोई सूचना नहीं",
      "markAsRead": "पढ़ी हुई मार्क करें",
      "delete": "हटाएं",
      "loading": "लोड हो रहा है...",
    },
    3: {
      "notification": "सूचनाएं",
      "noNotifications": "कोई सूचना नहीं",
      "markAsRead": "पढ़ी हुई मार्क करें",
      "delete": "हटाएं",
      "loading": "लोड हो रहा है...",
    },
    4: {
      "notification": "सूचनाएं",
      "noNotifications": "कोई सूचना नहीं",
      "markAsRead": "पढ़ी हुई मार्क करें",
      "delete": "हटाएं",
      "loading": "लोड हो रहा है...",
    },
    5: {
      "notification": "सूचना",
      "noNotifications": "कोनो सूचना ना",
      "markAsRead": "पढ़ल मार्क करीं",
      "delete": "मिटाईं",
      "loading": "लोड हो रहल बा...",
    },
    6: {
      "notification": "বিজ্ঞপ্তি",
      "noNotifications": "কোনো বিজ্ঞপ্তি নেই",
      "markAsRead": "পঠিত হিসেবে চিহ্নিত করুন",
      "delete": "মুছুন",
      "loading": "লোড হচ্ছে...",
    },
    7: {
      "notification": "સૂચના",
      "noNotifications": "કોઈ સૂચના નથી",
      "markAsRead": "વાંચેલી તરીકે માર્ક કરો",
      "delete": "કાઢી નાખો",
      "loading": "લોડ થઈ રહ્યું છે...",
    },
    8: {
      "notification": "সুচনা",
      "noNotifications": "কোনো সুচনা নাই",
      "markAsRead": "পঢ়া হিচাপে চিহ্নিত কৰক",
      "delete": "মচি পেলাওক",
      "loading": "লোড হৈ আছে...",
    },
    9: {
      "notification": "ସୂଚନା",
      "noNotifications": "କୌଣସି ସୂଚନା ନାହିଁ",
      "markAsRead": "ପଢିଥିବା ଭାବରେ ଚିହ୍ନଟ କରନ୍ତୁ",
      "delete": "ବିଲୋପ କରନ୍ତୁ",
      "loading": "ଲୋଡ୍ ହେଉଛି...",
    },
    10: {
      "notification": "सूचना",
      "noNotifications": "कोणतीही सूचना नाही",
      "markAsRead": "वाचलेली म्हणून मार्क करा",
      "delete": "हटवा",
      "loading": "लोड होत आहे...",
    },
    11: {
      "notification": "அறிவிப்பு",
      "noNotifications": "எந்த அறிவிப்பும் இல்லை",
      "markAsRead": "படித்ததாக குறிக்கவும்",
      "delete": "நீக்கு",
      "loading": "ஏற்றப்படுகிறது...",
    },
    12: {
      "notification": "నోటిఫికేషన్",
      "noNotifications": "ఎటువంటి నోటిఫికేషన్ లేదు",
      "markAsRead": "చదివినట్టు గుర్తించు",
      "delete": "తొలగించు",
      "loading": "లోడ్ అవుతోంది...",
    },
    13: {
      "notification": "ಅಧಿಸೂಚನೆ",
      "noNotifications": "ಯಾವುದೇ ಅಧಿಸೂಚನೆ ಇಲ್ಲ",
      "markAsRead": "ಓದಿದಂತೆ ಗುರುತಿಸಿ",
      "delete": "ಅಳಿಸಿ",
      "loading": "ಲೋಡ್ ಆಗುತ್ತಿದೆ...",
    },
    14: {
      "notification": "അറിയിപ്പ്",
      "noNotifications": "അറിയിപ്പുകളൊന്നുമില്ല",
      "markAsRead": "വായിച്ചതായി അടയാളപ്പെടുത്തുക",
      "delete": "ഇല്ലാതാക്കുക",
      "loading": "ലോഡ് ചെയ്യുന്നു...",
    },
    15: {
      "notification": "Notification",
      "noNotifications": "No notifications",
      "markAsRead": "Mark as read",
      "delete": "Delete",
      "loading": "Loading...",
    },
  };

  String t(String key) {
    return translations[widget.languageIndex]?[key] ??
        translations[15]![key] ??
        key;
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh notifications when screen comes back into focus
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      print('Loading notifications for user: $userId');
      try {
        final notifications =
            await _notificationService.getUserNotifications(userId);
        print('Loaded ${notifications.length} notifications');
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading notifications: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print('No user ID found');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _notificationService.markNotificationAsRead(userId, notificationId);
      await _loadNotifications(); // Refresh the list
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _notificationService.deleteNotification(userId, notificationId);
      await _loadNotifications(); // Refresh the list
    }
  }

  Future<void> _sendTestNotification() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _notificationService.sendNotificationToUser(
        userId,
        'Test Notification',
        'This is a test notification to verify the system is working!',
        data: {'type': 'test', 'testId': DateTime.now().toIso8601String()},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent!')),
      );
      await _loadNotifications(); // Refresh the list
    }
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          t("notification"),
          style: const TextStyle(
            fontSize: 20.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BC0EB)),
              ),
            )
          : _notifications.isEmpty
              ? Center(
                  child: Text(
                    t("noNotifications"),
                    style: const TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final isRead = notification['read'] ?? false;

                    return Dismissible(
                      key: Key(notification['id']),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _deleteNotification(notification['id']);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isRead
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFF1F1F1F),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isRead
                                ? Colors.grey[700]!
                                : const Color(0xFF5BC0EB),
                            width: isRead ? 1 : 2,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            notification['title'] ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                notification['body'] ?? '',
                                style: const TextStyle(
                                  color: Color(0xFFD1D1D1),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTimestamp(notification['timestamp']),
                                style: const TextStyle(
                                  color: Color(0xFFB0B0B0),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: !isRead
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    color: Color(0xFF5BC0EB),
                                  ),
                                  onPressed: () =>
                                      _markAsRead(notification['id']),
                                )
                              : null,
                          onTap: () {
                            if (!isRead) {
                              _markAsRead(notification['id']);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  final int languageIndex;
  PrivacyScreen({Key? key, required this.languageIndex}) : super(key: key);

  final Map<int, Map<String, String>> translations = {
    0: {
      "privacy": "رازداری",
      "privacyContent": "یہ رازداری کی سکرین ہے",
    },
    1: {
      "privacy": "ਗੋਪਨੀਯਤਾ",
      "privacyContent": "ਇਹ ਗੋਪਨੀਯਤਾ ਸਕ੍ਰੀਨ ਹੈ",
    },
    2: {
      "privacy": "নিজী",
      "privacyContent": "это непубличная экран",
    },
    3: {
      "privacy": "गोपनीयता",
      "privacyContent": "यह गोपनीयता स्क्रीन है",
    },
    4: {
      "privacy": "নিজী",
      "privacyContent": "ई निजी स्क्रीन है",
    },
    5: {
      "privacy": "নিজী",
      "privacyContent": "ई निजी स्क्रीन बा",
    },
    6: {
      "privacy": "গোপনীয়তা",
      "privacyContent": "এটি গোপনীয়তার স্ক্রিন",
    },
    7: {
      "privacy": "ગોપનીયતા",
      "privacyContent": "આ ગોપનીયતા સ્ક્રીન છે",
    },
    8: {
      "privacy": "গোপনীয়তা",
      "privacyContent": "এইটো গোপনীয়তাৰ স্ক্ৰিন",
    },
    9: {
      "privacy": "ଗୋପନୀୟତା",
      "privacyContent": "ଏହା ଗୋପନୀୟତା ସ୍କ୍ରିନ୍",
    },
    10: {
      "privacy": "গোপনীয়তা",
      "privacyContent": "ही गोपनीयता स्क्रीन आहे",
    },
    11: {
      "privacy": "தனியுரிமை",
      "privacyContent": "இது தனியுரிமை திரை",
    },
    12: {
      "privacy": "గోప్యత",
      "privacyContent": "ఇది గోప్యత స్క్రీన్",
    },
    13: {
      "privacy": "ಗೋಪ್ಯತೆ",
      "privacyContent": "ಇದು ಗೋಪ್ಯತೆ ಪರದೆಯಾಗಿದೆ",
    },
    14: {
      "privacy": "സ്വകാര്യത",
      "privacyContent": "ഇത് സ്വകാര്യതയുടെ സ്ക്രීനാണ്",
    },
    15: {
      "privacy": "Privacy",
      "privacyContent": "This is the Privacy Screen",
    },
  };

  String t(String key) {
    return translations[languageIndex]?[key] ?? translations[15]![key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t("privacy"),
          style: const TextStyle(
            fontSize: 20.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            t("privacyContent"),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20.0,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
