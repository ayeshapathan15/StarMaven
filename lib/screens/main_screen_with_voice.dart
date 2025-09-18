import 'package:flutter/material.dart';
import 'main_screen.dart';
import '../services/voice_assistant_manager.dart';

class MainScreenWithVoiceAssistant extends StatefulWidget {
  const MainScreenWithVoiceAssistant({Key? key}) : super(key: key);

  @override
  State<MainScreenWithVoiceAssistant> createState() => _MainScreenWithVoiceAssistantState();
}

class _MainScreenWithVoiceAssistantState extends State<MainScreenWithVoiceAssistant> {
  @override
  Widget build(BuildContext context) {
    // Clean main screen - voice assistant works invisibly in background
    return const MainScreen();
  }
}