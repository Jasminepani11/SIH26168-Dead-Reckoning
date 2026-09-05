import 'dart:async';

import 'package:flutter/material.dart';

import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF00E5FF),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.navigation_rounded,
                size: 48,
                color: Color(0xFF00E5FF),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'DRIFT',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'GPS-DENIED INTELLIGENT NAVIGATION',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),

            const SizedBox(height: 40),

            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}