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
    return Scaffold(
      body: Stack(
        children: [
          // Your existing main screen
          const MainScreen(),
          
          // Floating voice assistant button (optional - for manual trigger)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () async {
                await VoiceAssistantManager.instance.manualTrigger();
              },
              backgroundColor: Colors.blue.withOpacity(0.9),
              child: Icon(
                Icons.mic,
                color: Colors.white,
              ),
              heroTag: "voice_assistant_fab",
            ),
          ),
          
          // Status indicator (optional - shows if voice assistant is active)
          Positioned(
            top: 50,
            left: 20,
            child: StreamBuilder<String>(
              stream: Stream.periodic(Duration(seconds: 1), (_) => VoiceAssistantManager.instance.status),
              builder: (context, snapshot) {
                if (!VoiceAssistantManager.instance.isActive) {
                  return SizedBox.shrink();
                }
                
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hearing,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Voice Assistant Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}