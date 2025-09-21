import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'question_screen.dart';
import 'start_screen.dart';
import 'gamification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();

    // Set up an AnimationController for 1.5 seconds.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Create a Tween for both fade and scale animation with a smoother curve.
    _animation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Start the animation.
    _controller.forward();

    // After 1.5 seconds, navigate the user.
    Timer(const Duration(milliseconds: 800), () {
      navigateUser();
    });
  }

  Future<void> navigateUser() async {
    await Firebase.initializeApp();

    // Check for daily login rewards if user is logged in
    if (currentUserId != null) {
      await GamificationService().checkAndAwardDailyLogin(currentUserId!);
    }

    // Check user status and navigate accordingly.
    if (currentUserId != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const QuestionScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StartScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Black background
      body: Center(
        // Combining fade and scale transitions for a subtle effect.
        child: FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: _animation,
            child: SizedBox(
              width: 165, // Adjust the width as needed
              height: 165, // Adjust the height as needed
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
