import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'splash.dart';
import 'notification_service.dart';
import 'gamification_service.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔄 Background message handler called');
  print('📨 Message ID: ${message.messageId}');
  print('📨 Message data: ${message.data}');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('✅ Firebase re-initialized in background');
  await NotificationService.initializeLocalNotifications();
  final title = message.data['title'] ?? 'Notification';
  final body = message.data['body'] ?? 'You have a new notification';
  await NotificationService.showLocalNotification(title, body, message.data);

  print('✅ Background message processing completed');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variables
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final notificationService = NotificationService();
  await notificationService.initialize();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.greenAccent,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: ColorScheme.fromSeed(seedColor: Colors.greenAccent)
            .onPrimaryContainer
            .withOpacity(0.3),
        body: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            width: min(720, screenSize.width),
            child: const SplashScreen(),
          ),
        ),
      ),
    );
  }
}
