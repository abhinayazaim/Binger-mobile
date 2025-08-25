import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserStatusAndNavigate();
  }

  Future<void> _checkUserStatusAndNavigate() async {
    try {
      // Show splash screen for minimum 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;

      // Add timeout to prevent hanging
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Use timeout to prevent infinite waiting
      final isLoggedIn = await Future.any([
        userProvider.checkLoginStatus(),
        Future.delayed(const Duration(seconds: 10), () => false), // 10 second timeout
      ]);

      if (!mounted) return;

      // Navigate based on login status
      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/landing');
      }
    } catch (e) {
      print('Error in splash screen: $e');
      
      if (!mounted) return;
      
      // On error, go to landing page as fallback
      Navigator.pushReplacementNamed(context, '/landing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if logo doesn't exist
                return Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(75),
                  ),
                  child: const Icon(
                    Icons.movie,
                    size: 80,
                    color: Colors.black,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              "Binger",
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Discover, track, and organize your movies & TV shows.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ],
        ),
      ),
    );
  }
}