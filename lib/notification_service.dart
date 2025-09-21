import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'main.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Notification preferences
  bool _communityNotifications = true;
  bool _feedNotifications = true;
  bool _likeNotifications = true;
  bool _commentNotifications = true;
  bool _newPostNotifications = true;

  // Getters for preferences
  bool get communityNotifications => _communityNotifications;
  bool get feedNotifications => _feedNotifications;
  bool get likeNotifications => _likeNotifications;
  bool get commentNotifications => _commentNotifications;
  bool get newPostNotifications => _newPostNotifications;

  Future<void> initialize() async {
    print('🔄 Initializing notification service...');

    // Initialize local notifications
    await initializeLocalNotifications();

    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted permission');
    } else {
      print('❌ User declined or has not accepted permission');
    }

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('✅ FCM Token obtained: ${token.substring(0, 20)}...');
      await _saveTokenToDatabase(token);
    } else {
      print('❌ Failed to get FCM token');
    }

    // Handle token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...');
      _saveTokenToDatabase(newToken);
    });

    // Load user preferences
    await _loadNotificationPreferences();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background messages are handled in main.dart
    print('✅ Notification service initialized successfully');
  }

  static Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Local notification tapped: ${response.payload}');
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print('✅ Local notifications initialized');
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _dbRef.child('users').child(userId).child('fcmToken').set(token);
    }
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _communityNotifications = prefs.getBool('community_notifications') ?? true;
    _feedNotifications = prefs.getBool('feed_notifications') ?? true;
    _likeNotifications = prefs.getBool('like_notifications') ?? true;
    _commentNotifications = prefs.getBool('comment_notifications') ?? true;
    _newPostNotifications = prefs.getBool('new_post_notifications') ?? true;
  }

  Future<void> updateNotificationPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    switch (key) {
      case 'community_notifications':
        _communityNotifications = value;
        break;
      case 'feed_notifications':
        _feedNotifications = value;
        break;
      case 'like_notifications':
        _likeNotifications = value;
        break;
      case 'comment_notifications':
        _commentNotifications = value;
        break;
      case 'new_post_notifications':
        _newPostNotifications = value;
        break;
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    final title = message.data['title'] ?? 'Notification';
    final body = message.data['body'] ?? 'You have a new notification';

    // Show local notification for WhatsApp-style popup
    await showLocalNotification(
      title,
      body,
      message.data,
    );

    // Store the notification in the database for display in the profile panel
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _storeNotificationInDatabase(
        userId,
        title,
        body,
        message.data,
      );
    }
  }

  static Future<void> showLocalNotification(
      String title, String body, Map<String, dynamic>? data) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title,
      body,
      platformChannelSpecifics,
      payload: data != null ? jsonEncode(data) : null,
    );

    print('✅ Local notification shown: $title');
  }

  Future<void> sendNotificationToUser(String userId, String title, String body,
      {Map<String, dynamic>? data}) async {
    try {
      print(
          '📨 sendNotificationToUser called for user: $userId, title: $title');

      // Store notification in database for profile panel display
      await _storeNotificationInDatabase(userId, title, body, data);
      print('✅ Notification stored successfully for user: $userId');

      // Send FCM notification
      await _sendActualFCMNotification(userId, title, body, data);
      print('📱 FCM notification sent for user: $userId');
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  Future<void> _sendActualFCMNotification(String userId, String title,
      String body, Map<String, dynamic>? data) async {
    try {
      print('🔍 Getting FCM token for user: $userId');

      // Get the user's FCM token
      final userSnapshot =
          await _dbRef.child('users').child(userId).child('fcmToken').get();
      if (!userSnapshot.exists) {
        print('❌ No FCM token found for user: $userId');
        return;
      }

      String? token = userSnapshot.value as String?;
      if (token == null || token.isEmpty) {
        print('❌ FCM token is null or empty for user: $userId');
        return;
      }

      print('✅ Found FCM token for user: $userId (length: ${token.length})');
      print('📤 Sending FCM notification to user: $userId');

      // Send FCM notification using HTTP v1 API
      await _sendFCMHttpV1Notification(token, title, body, data);

      print('✅ FCM notification sent successfully to user: $userId');
    } catch (e) {
      print('❌ Error sending FCM notification: $e');
      // Fallback: still store in database even if FCM fails
    }
  }

  Future<String> _getAccessToken() async {
    try {
      // Load Firebase service account credentials from environment variables
      final Map<String, dynamic> serviceAccountJson = {
        "type": dotenv.env['FIREBASE_TYPE'] ?? "service_account",
        "project_id": dotenv.env['FIREBASE_PROJECT_ID'],
        "private_key_id": dotenv.env['FIREBASE_PRIVATE_KEY_ID'],
        "private_key":
            (dotenv.env['FIREBASE_PRIVATE_KEY'] ?? '').replaceAll('\\n', '\n'),
        "client_email": dotenv.env['FIREBASE_CLIENT_EMAIL'],
        "client_id": dotenv.env['FIREBASE_CLIENT_ID'],
        "auth_uri": dotenv.env['FIREBASE_AUTH_URI'],
        "token_uri": dotenv.env['FIREBASE_TOKEN_URI'],
        "auth_provider_x509_cert_url":
            dotenv.env['FIREBASE_AUTH_PROVIDER_X509_CERT_URL'],
        "client_x509_cert_url": dotenv.env['FIREBASE_CLIENT_X509_CERT_URL'],
        "universe_domain": dotenv.env['FIREBASE_UNIVERSE_DOMAIN'],
      };

      // Validate that required fields are present
      final requiredFields = ['project_id', 'private_key', 'client_email'];
      for (final field in requiredFields) {
        if (serviceAccountJson[field] == null ||
            serviceAccountJson[field].isEmpty) {
          throw Exception(
              'Missing required Firebase environment variable: FIREBASE_${field.toUpperCase()}');
        }
      }

      final accountCredentials =
          auth.ServiceAccountCredentials.fromJson(serviceAccountJson);
      final client = await auth.clientViaServiceAccount(accountCredentials,
          ['https://www.googleapis.com/auth/firebase.messaging']);
      final accessToken = client.credentials.accessToken.data;
      client.close();
      return accessToken;
    } catch (e) {
      print('Error getting access token: $e');
      throw Exception('Failed to get access token');
    }
  }

  Future<void> _sendFCMHttpV1Notification(String token, String title,
      String body, Map<String, dynamic>? data) async {
    try {
      final String accessToken = await _getAccessToken();

      final Map<String, dynamic> message = {
        'message': {
          'token': token,
          'data': {
            'title': title,
            'body': body,
            if (data != null) ...data,
          },
        },
      };

      final response = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/random-1128d/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('✅ FCM notification sent successfully');
        print('📨 FCM Response: ${response.body}');
      } else {
        print('❌ Failed to send FCM notification: ${response.statusCode}');
        print('❌ FCM Error Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending FCM notification: $e');
    }
  }

  Future<void> _sendFCMNotification(String token, String title, String body,
      Map<String, dynamic>? data) async {
    try {
      // For client-side FCM sending, we'll use a simple HTTP request
      // Note: In production, this should be done server-side for security
      final Map<String, dynamic> message = {
        'to': token,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data ?? {},
      };

      // Since we can't make HTTP requests directly from client without server key,
      // we'll store the notification request in database for a server function to process
      await _dbRef.child('fcm_queue').push().set({
        'token': token,
        'title': title,
        'body': body,
        'data': data ?? {},
        'timestamp': DateTime.now().toIso8601String(),
        'processed': false,
      });

      print('FCM notification queued for token: ${token.substring(0, 20)}...');
    } catch (e) {
      print('Error queuing FCM notification: $e');
    }
  }

  Future<void> _storeNotificationInDatabase(String userId, String title,
      String body, Map<String, dynamic>? data) async {
    final notificationRef =
        _dbRef.child('fcm_notifications').child(userId).push();
    await notificationRef.set({
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
      'data': data ?? {},
    });
  }

  // Notification sending methods for different events
  Future<void> sendCommunityCreationNotification(
      String communityName, String creatorId) async {
    if (!_communityNotifications) return;

    // Get all users except the creator
    final usersSnapshot = await _dbRef.child('users').get();
    if (usersSnapshot.exists) {
      final users = Map<String, dynamic>.from(usersSnapshot.value as Map);
      for (var userId in users.keys) {
        if (userId != creatorId) {
          await sendNotificationToUser(userId, 'New Community Created!',
              '$communityName community has been created. Join now!', data: {
            'type': 'community_created',
            'communityName': communityName
          });
        }
      }
    }
  }

  Future<void> sendCommunityMessageNotification(
      String communityId,
      String communityName,
      String senderId,
      String senderName,
      String message) async {
    if (!_communityNotifications) return;

    try {
      // Get community members
      final communitySnapshot = await _dbRef
          .child('communities')
          .child(communityId)
          .child('members')
          .get();
      if (communitySnapshot.exists) {
        final members =
            Map<String, dynamic>.from(communitySnapshot.value as Map);
        print('Found ${members.length} members in community $communityId');

        for (var userId in members.keys) {
          if (userId != senderId) {
            print('Sending community message notification to user: $userId');
            await sendNotificationToUser(userId, 'Message in $communityName',
                '$senderName: ${message.length > 30 ? message.substring(0, 30) + '...' : message}',
                data: {
                  'type': 'community_message',
                  'communityId': communityId,
                  'communityName': communityName,
                  'senderId': senderId,
                  'senderName': senderName,
                  'message': message
                });
          }
        }
      } else {
        print('No members found for community: $communityId');
      }
    } catch (e) {
      print('Error sending community message notification: $e');
    }
  }

  Future<void> sendFeedMessageNotification(
      String postId, String senderId, String senderName, String message) async {
    print(
        '🔥 sendFeedMessageNotification called with postId: $postId, senderId: $senderId');

    if (!_feedNotifications) {
      print('❌ Feed notifications are disabled');
      return;
    }

    try {
      // Get all users except the sender
      final usersSnapshot = await _dbRef.child('users').get();
      if (usersSnapshot.exists) {
        final users = Map<String, dynamic>.from(usersSnapshot.value as Map);
        print('✅ Found ${users.length} users for feed notification');

        for (var userId in users.keys) {
          if (userId != senderId) {
            print('📤 Sending feed post notification to user: $userId');
            await sendNotificationToUser(userId, '📱 New Post in Feed',
                '$senderName shared: ${message.length > 45 ? message.substring(0, 45) + '...' : message}',
                data: {
                  'type': 'feed_post',
                  'postId': postId,
                  'senderId': senderId,
                  'senderName': senderName,
                  'message': message
                });
            // Also, store the notification in the database for each user
            await _storeNotificationInDatabase(
                userId,
                '📱 New Post in Feed',
                '$senderName shared: ${message.length > 45 ? message.substring(0, 45) + '...' : message}',
                {
                  'type': 'feed_post',
                  'postId': postId,
                  'senderId': senderId,
                  'senderName': senderName,
                  'message': message
                });
          } else {
            print('⏭️ Skipping sender: $senderId');
          }
        }
      } else {
        print('❌ No users found for feed notification');
      }
    } catch (e) {
      print('❌ Error sending feed message notification: $e');
    }
  }

  Future<void> sendLikeNotification(String postId, String likerId,
      String likerName, String postAuthorId) async {
    if (!_likeNotifications || likerId == postAuthorId) return;

    await sendNotificationToUser(
        postAuthorId, '👍 Post Liked', '$likerName liked your post', data: {
      'type': 'like',
      'postId': postId,
      'likerId': likerId,
      'likerName': likerName
    });
  }

  Future<void> sendCommentNotification(String postId, String commenterId,
      String commenterName, String postAuthorId, String comment) async {
    if (!_commentNotifications || commenterId == postAuthorId) return;

    await sendNotificationToUser(postAuthorId, '💬 New Comment',
        '$commenterName: ${comment.length > 35 ? comment.substring(0, 35) + '...' : comment}',
        data: {
          'type': 'comment',
          'postId': postId,
          'commenterId': commenterId,
          'commenterName': commenterName,
          'comment': comment
        });
  }

  Future<void> sendNewPostNotification(
      String postId, String authorId, String content) async {
    if (!_newPostNotifications) return;

    // Get all users except the author
    final usersSnapshot = await _dbRef.child('users').get();
    if (usersSnapshot.exists) {
      final users = Map<String, dynamic>.from(usersSnapshot.value as Map);
      for (var userId in users.keys) {
        if (userId != authorId) {
          await sendNotificationToUser(userId, 'New Post in Feed',
              'Check out the latest post in the feed',
              data: {'type': 'new_post', 'postId': postId, 'content': content});
        }
      }
    }
  }

  // Gamification Notification Methods
  Future<void> sendStreakReminderNotification(
      String userId, int currentStreak) async {
    await sendNotificationToUser(userId, '🔥 Don\'t Break Your Streak!',
        'You\'re on a $currentStreak-day streak! Keep it going by completing a question today.',
        data: {'type': 'streak_reminder', 'currentStreak': currentStreak});
  }

  Future<void> sendStreakBrokenNotification(
      String userId, int previousStreak) async {
    await sendNotificationToUser(userId, '💔 Streak Broken',
        'Your ${previousStreak}-day streak has been broken. Start a new streak today!',
        data: {'type': 'streak_broken', 'previousStreak': previousStreak});
  }

  Future<void> sendWeeklyChallengeReminderNotification(
      String userId, String challengeName, int progress, int target) async {
    await sendNotificationToUser(userId, '⏰ Weekly Challenge Reminder',
        '$challengeName: $progress/$target completed. Complete it before the week ends!',
        data: {
          'type': 'weekly_challenge_reminder',
          'challengeName': challengeName,
          'progress': progress,
          'target': target
        });
  }

  Future<void> sendMonthlyChallengeReminderNotification(
      String userId, String challengeName, int progress, int target) async {
    await sendNotificationToUser(userId, '📅 Monthly Challenge Reminder',
        '$challengeName: $progress/$target completed. Keep pushing towards your goal!',
        data: {
          'type': 'monthly_challenge_reminder',
          'challengeName': challengeName,
          'progress': progress,
          'target': target
        });
  }

  Future<void> sendChallengeCompletedNotification(
      String userId, String challengeName, int reward) async {
    await sendNotificationToUser(userId, '🎉 Challenge Completed!',
        'Congratulations! You completed "$challengeName" and earned $reward coins!',
        data: {
          'type': 'challenge_completed',
          'challengeName': challengeName,
          'reward': reward
        });
  }

  Future<void> sendAchievementNotification(
      String userId, String achievementName) async {
    await sendNotificationToUser(userId, '🏆 Achievement Unlocked!',
        'Congratulations! You unlocked: $achievementName',
        data: {'type': 'achievement', 'achievementName': achievementName});
  }

  Future<void> sendLevelUpNotification(String userId, int newLevel) async {
    await sendNotificationToUser(userId, '⬆️ Level Up!',
        'Congratulations! You\'ve reached Level $newLevel!',
        data: {'type': 'level_up', 'newLevel': newLevel});
  }

  Future<void> sendPointsEarnedNotification(
      String userId, int points, String reason) async {
    await sendNotificationToUser(
        userId, '💰 Points Earned!', 'You earned $points points for: $reason',
        data: {'type': 'points_earned', 'points': points, 'reason': reason});
  }

  // Friend Challenge Notification Methods
  Future<void> sendFriendChallengeNotification(
      String friendId, String challengeTitle, String creatorId) async {
    try {
      // Get creator's display name
      final currentUser = FirebaseAuth.instance.currentUser;
      final creatorName = currentUser?.displayName ?? 'Your friend';

      await sendNotificationToUser(friendId, '🎯 Friend Challenge!',
          '$creatorName challenged you to: "$challengeTitle"',
          data: {
            'type': 'friend_challenge',
            'challengeTitle': challengeTitle,
            'creatorId': creatorId,
            'creatorName': creatorName
          });
    } catch (e) {
      print('Error sending friend challenge notification: $e');
    }
  }

  Future<void> sendFriendChallengeProgressNotification(String opponentId,
      String challengeTitle, String userName, int progress, int target) async {
    try {
      await sendNotificationToUser(opponentId, '📈 Challenge Progress!',
          '$userName made progress in "$challengeTitle": $progress/$target',
          data: {
            'type': 'friend_challenge_progress',
            'challengeTitle': challengeTitle,
            'userName': userName,
            'progress': progress,
            'target': target
          });
    } catch (e) {
      print('Error sending friend challenge progress notification: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    final notificationsSnapshot =
        await _dbRef.child('fcm_notifications').child(userId).get();
    if (!notificationsSnapshot.exists) return [];

    final notifications =
        Map<String, dynamic>.from(notificationsSnapshot.value as Map);
    final notificationList = notifications.entries.map((entry) {
      final notification = Map<String, dynamic>.from(entry.value);
      notification['id'] = entry.key;
      return notification;
    }).toList();

    // Sort by timestamp (newest first)
    notificationList.sort((a, b) {
      final timeA = DateTime.parse(a['timestamp']);
      final timeB = DateTime.parse(b['timestamp']);
      return timeB.compareTo(timeA);
    });

    return notificationList;
  }

  Future<void> markNotificationAsRead(
      String userId, String notificationId) async {
    await _dbRef
        .child('fcm_notifications')
        .child(userId)
        .child(notificationId)
        .child('read')
        .set(true);
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    await _dbRef
        .child('fcm_notifications')
        .child(userId)
        .child(notificationId)
        .remove();
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final notifications = await getUserNotifications(userId);
    return notifications
        .where((notification) => !(notification['read'] ?? false))
        .length;
  }

  // Test method to verify notification setup
  Future<void> testNotificationSetup() async {
    print('🧪 Testing notification setup...');

    // Test FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('✅ FCM Token available: ${token.substring(0, 20)}...');
    } else {
      print('❌ No FCM token available');
    }

    // Test local notification
    await showLocalNotification(
      'Test Notification',
      'This is a test notification to verify the setup is working',
      {'type': 'test', 'timestamp': DateTime.now().toIso8601String()},
    );

    print('✅ Test notification sent');
  }
}
