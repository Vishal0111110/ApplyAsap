/*
import 'package:adaptive_theme/adaptive_theme.dart';
import 'question_screen.dart';
import 'package:flutter/material.dart';
import 'user_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  Widget build(BuildContext context) {
    //final clrSchm = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(
        child: Column(children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(175)),
            child: Builder(builder: (context) {
              return Stack(alignment: Alignment.center, children: [
                Container(
                  // color: const Color(0xFF2A2A2A),
                  child: Image.asset(
                    'assets/images/building_an_app.png',
                    width: 600,
                    fit: BoxFit.cover,
                    color: Colors.white,
                    colorBlendMode: BlendMode.difference,
                  ),
                ),
              ]);
            }),
          ),
          const SizedBox(height: 80),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome to',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                Text('Apply Asap!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text("First, Let's get to know more about yourself!!",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ]),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(vertical: 46, horizontal: 16),
        width: double.infinity,
        child: proceedButton(context),
      ),
    );
  }

  Widget proceedButton(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        /*
        onPressed: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const QuestionScreen(),
            transitionDuration: const Duration(seconds: 0),
            reverseTransitionDuration: const Duration(seconds: 0),
          ),
        ),*/
        onPressed: () async {
          try {
            final user = await UserController.loginWithGoogle();
            if (user != null && mounted) {
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => QuestionScreen()));
            }
          } on FirebaseAuthException catch (error) {
            print(error.message);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
              error.message ?? "Something went wrong",
            )));
          } catch (error) {
            print(error);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
              error.toString(),
            )));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5BC0EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text('Proceed',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
    );
  }
}

class ThemeSelectionPage extends StatelessWidget {
  const ThemeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final clrSchm = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Padding(
        padding: const EdgeInsets.only(left: 30, right: 30, top: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<AdaptiveThemeMode?>(
              valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
              builder: (_, mode, child) {
                return Text(
                  'App Theme',
                  style: TextStyle(
                    color: mode?.isLight ?? true
                        ? clrSchm.onBackground
                        : clrSchm.background,
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<AdaptiveThemeMode?>(
              valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
              builder: (_, mode, child) {
                return GestureDetector(
                  onTap: () {
                    AdaptiveTheme.of(context).setLight();
                  },
                  child: Container(
                    width: 100,
                    height: 150,
                    decoration: BoxDecoration(
                      color: clrSchm.primaryContainer,
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      border: Border.all(
                        color: mode?.isLight ?? false
                            ? clrSchm.primary
                            : clrSchm.primaryContainer,
                        width: 7,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<AdaptiveThemeMode?>(
              valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
              builder: (_, mode, child) {
                return GestureDetector(
                  onTap: () {
                    AdaptiveTheme.of(context).setDark();
                  },
                  child: Container(
                    width: 100,
                    height: 150,
                    decoration: BoxDecoration(
                      color: clrSchm.primaryContainer,
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      border: Border.all(
                        color: mode?.isDark ?? false
                            ? clrSchm.primary
                            : clrSchm.primaryContainer,
                        width: 7,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
*/
import 'package:adaptive_theme/adaptive_theme.dart';
import 'question_screen.dart';
import 'package:flutter/material.dart';
import 'user_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:google_sign_in/google_sign_in.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // The user canceled the sign-in
      return null;
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
    await googleUser.authentication;

    // Create a new credential
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google [UserCredential]
    final UserCredential userCredential =
    await _auth.signInWithCredential(credential);

    return userCredential.user;
  }

  @override
  Widget build(BuildContext context) {
    //final clrSchm = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(
        child: Column(children: [
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(175)),
            child: Builder(builder: (context) {
              return Stack(alignment: Alignment.center, children: [
                Container(
                  // color: const Color(0xFF2A2A2A),
                  child: Image.asset(
                    'assets/images/building_an_app.png',
                    width: 600,
                    fit: BoxFit.cover,
                    color: Colors.white,
                    colorBlendMode: BlendMode.difference,
                  ),
                ),
              ]);
            }),
          ),
          const SizedBox(height: 80),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome to',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                Text('Apply Asap!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text("First, Let's get to know more about yourself!!",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ]),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(vertical: 46, horizontal: 16),
        width: double.infinity,
        child: proceedButton(context),
      ),
    );
  }

  Widget proceedButton(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        /*
        onPressed: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const QuestionScreen(),
            transitionDuration: const Duration(seconds: 0),
            reverseTransitionDuration: const Duration(seconds: 0),
          ),
        ),*/
        onPressed: () async {
          try {
            final user = await signInWithGoogle();
            if (user != null && mounted) {
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => QuestionScreen()));
            }
          } on FirebaseAuthException catch (error) {
            print(error.message);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  error.message ?? "Something went wrong",
                )));
          } catch (error) {
            print(error);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  error.toString(),
                )));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5BC0EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text('Proceed',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
    );
  }
}

class ThemeSelectionPage extends StatelessWidget {
  const ThemeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final clrSchm = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Padding(
        padding: const EdgeInsets.only(left: 30, right: 30, top: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<AdaptiveThemeMode?>(
              valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
              builder: (_, mode, child) {
                return Text(
                  'App Theme',
                  style: TextStyle(
                    color: mode?.isLight ?? true
                        ? clrSchm.onBackground
                        : clrSchm.background,
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<AdaptiveThemeMode?>(
              valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
              builder: (_, mode, child) {
                return GestureDetector(
                  onTap: () {
                    AdaptiveTheme.of(context).setLight();
                  },
                  child: Container(
                    width: 100,
                    height: 150,
                    decoration: BoxDecoration(
                      color: clrSchm.primaryContainer,
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      border: Border.all(
                        color: mode?.isLight ?? false
                            ? clrSchm.primary
                            : clrSchm.primaryContainer,
                        width: 7,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<AdaptiveThemeMode?>(
              valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
              builder: (_, mode, child) {
                return GestureDetector(
                  onTap: () {
                    AdaptiveTheme.of(context).setDark();
                  },
                  child: Container(
                    width: 100,
                    height: 150,
                    decoration: BoxDecoration(
                      color: clrSchm.primaryContainer,
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      border: Border.all(
                        color: mode?.isDark ?? false
                            ? clrSchm.primary
                            : clrSchm.primaryContainer,
                        width: 7,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

