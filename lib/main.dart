import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/main_screen.dart';
import 'screens/main_screen_with_voice.dart';
import 'screens/auth_screen.dart';
import 'services/tts_service.dart';
import 'services/voice_assistant_manager.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize TTS Service
  await TTSService.initialize();

  runApp(const InvenTreeApp());
}

class InvenTreeApp extends StatefulWidget {
  const InvenTreeApp({super.key});

  @override
  State<InvenTreeApp> createState() => _InvenTreeAppState();
}

class _InvenTreeAppState extends State<InvenTreeApp> {
  @override
  void initState() {
    super.initState();
    // Initialize voice assistant after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VoiceAssistantManager.instance.initialize(context);
    });
  }

  @override
  void dispose() {
    VoiceAssistantManager.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InvenTree - Smart Grocery Assistant',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        primaryColor: const Color(0xFF2C3E50),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2C3E50),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C3E50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        // FIXED: Use CardThemeData instead of CardTheme
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const MainScreenWithVoiceAssistant();
          } else {
            return const AuthScreen();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
