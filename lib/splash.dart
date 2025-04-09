import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'question_screen.dart';
import 'start_screen.dart';

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

    // Set up an AnimationController for 4 seconds.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Create a Tween for both fade and scale animation.
    _animation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start the animation.
    _controller.forward();

    // After 4 seconds of animation, navigate the user.
    Timer(const Duration(seconds: 4), () {
      navigateUser();
    });
  }

  Future<void> navigateUser() async {
    await Firebase.initializeApp();
    // Additional delay if needed
    await Future.delayed(const Duration(seconds: 2));
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
