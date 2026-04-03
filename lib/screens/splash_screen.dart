import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 👈 Added for Initial Message

// --- NEW: Import AuthProvider instead of UserProvider ---
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'job_detail_screen.dart'; // 👈 Needed for routing
import 'notification_screen.dart'; // 👈 Needed for routing

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // 1. Check Authentication Status from SharedPreferences
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    // 2. Check for Terminated State Notification (Killed App click)
    RemoteMessage? initialMessage;
    try {
      initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    } catch (e) {
      debugPrint("Error fetching initial message: $e");
    }

    // 2. Wait a bit for the animation to look smooth
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

  //   // 3. Navigate based on token existence
  //   if (authProvider.isAuthenticated) {
  //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  //   } else {
  //     // If not logged in, send them to Register (which also has Google Login)
  //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  //   }
  // }

    if (authProvider.isAuthenticated) {
      // 🚀 SMART ROUTING: Check if user tapped a notification
      if (initialMessage != null) {
        String jobId = initialMessage.data['job_id']?.toString() ?? "";

        // Push Replacement with Home, then Push the detail screen on top
        // This ensures the back button works correctly.
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));

        if (jobId.isNotEmpty) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: jobId)));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
        }
      } else {
        // Normal Launch
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } else {
      // Not logged in -> Go to Login
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Color(0xFF3F51B5)], // Indigo to slightly lighter indigo
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Logo Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: const Icon(
                Icons.work_outline,
                size: 60,
                color: Colors.indigo,
              ),
            ),

            const SizedBox(height: 20),

            // 2. App Name
            const Text(
              "Government Job Portal",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 10),

            // 3. Tagline
            const Text(
              "Find your dream government career",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 50),

            // 4. Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}