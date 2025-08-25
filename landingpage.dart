import 'package:flutter/material.dart';

class LandingPageWidget extends StatefulWidget {
  const LandingPageWidget({super.key});

  @override
  _LandingPageWidgetState createState() => _LandingPageWidgetState();
}

class _LandingPageWidgetState extends State<LandingPageWidget> {
  final List<String> posterImages = [
    'assets/hawkeye_poster.jpg',
    'assets/thor_poster.jpg',
    'assets/wandavision_poster.jpg',
    'assets/godfather_poster.jpg',
    'assets/endgame_poster.jpg',
    'assets/spiderhead_poster.jpg',
    'assets/titanic_poster.jpg',
    'assets/blackphone_poster.jpg',
    'assets/mufasa_poster.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(), 
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, 
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.6, 
                ),
                itemCount: posterImages.length, 
                itemBuilder: (context, index) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[900], 
                    image: DecorationImage(
                      image: AssetImage(posterImages[index]), 
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo.png', 
                  width: 120,
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
              ],
            ),
          ),

          // "Get Started" Button
          Positioned(
            bottom: 50,
            left: 30,
            right: 30,
            child: GestureDetector(
              onTap: () {
                // Navigasi ke SignInWidget menggunakan Named Route
                Navigator.pushNamed(context, '/signin');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5C418),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text(
                  "Get Started",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
