import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'landingpage.dart';
import 'sign_in.dart';
import 'sign_up.dart';
import 'homepage.dart';
import 'searchpage.dart';
import 'listpage.dart';
import 'profile.dart';
import 'playlist_page.dart';
import 'tierlist_page.dart';
import 'splash_screen.dart';
import 'settings.dart';
import 'theme_provider.dart';
import 'user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(create: (context) => UserProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print('Error initializing Firebase: $e');
    
    // Show error screen instead of continuing without Firebase
    runApp(
      MaterialApp(
        home: FirebaseErrorScreen(error: e.toString()),
      ),
    );
  }
}

// Error screen to show when Firebase fails to initialize
class FirebaseErrorScreen extends StatelessWidget {
  final String error;
  
  const FirebaseErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 20),
              const Text(
                'Firebase Initialization Failed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                error,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Restart the app
                  main();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Binger App',
          theme: themeProvider.getTheme(),
          initialRoute: '/splash',
          onGenerateRoute: (RouteSettings settings) {
            try {
              switch (settings.name) {
                case '/splash':
                  return MaterialPageRoute(builder: (_) => const SplashScreen());
                case '/landing':
                  return MaterialPageRoute(builder: (_) => const LandingPageWidget());
                case '/signin':
                  return MaterialPageRoute(builder: (_) => const SigninWidget());
                case '/signup':
                  return MaterialPageRoute(builder: (_) => const SignupWidget());
                case '/home':
                  return MaterialPageRoute(builder: (_) => const Homepage());
                case '/search':
                  return MaterialPageRoute(builder: (_) => const SearchPage());
                case '/list':
                  return MaterialPageRoute(builder: (_) => const ListPage());
                case '/profile':
                  return MaterialPageRoute(builder: (_) => const ProfilePage());
                case '/playlist':
                  return MaterialPageRoute(builder: (_) => const PlaylistPage());
                case '/tierlist':
                  return MaterialPageRoute(builder: (_) => const TierlistPage());
                case '/settings':
                  return MaterialPageRoute(builder: (_) => const SettingsPage());
                default:
                  return MaterialPageRoute(builder: (_) => const SplashScreen());
              }
            } catch (e) {
              print('Error generating route for ${settings.name}: $e');
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Error')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Something went wrong'),
                        const SizedBox(height: 8),
                        Text('Route: ${settings.name}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/splash'),
                          child: const Text('Go to Home'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}