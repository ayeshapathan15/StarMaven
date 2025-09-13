import 'package:flutter/material.dart';
import '../services/voice_assistant_manager.dart';
import '../services/enhanced_voice_assistant.dart';

class VoiceAssistantTest extends StatefulWidget {
  const VoiceAssistantTest({Key? key}) : super(key: key);

  @override
  State<VoiceAssistantTest> createState() => _VoiceAssistantTestState();
}

class _VoiceAssistantTestState extends State<VoiceAssistantTest> {
  String _status = 'Initializing...';
  String _lastMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeAndListen();
  }

  void _initializeAndListen() {
    // Listen to voice assistant state changes
    EnhancedVoiceAssistant.instance.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _status = state.status;
          _lastMessage = state.message;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mic,
                  color: VoiceAssistantManager.instance.isActive 
                      ? Colors.green 
                      : Colors.grey,
                ),
                SizedBox(width: 8),
                Text(
                  'Voice Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            Text(
              'Status: $_status',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            if (_lastMessage.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Last: $_lastMessage',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
            
            SizedBox(height: 16),
            
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await VoiceAssistantManager.instance.manualTrigger();
                  },
                  icon: Icon(Icons.mic, size: 16),
                  label: Text('Test Voice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                SizedBox(width: 12),
                
                Text(
                  VoiceAssistantManager.instance.isActive 
                      ? '🟢 Active' 
                      : '🔴 Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            Text(
              'Try saying: "Hey Nova, add sugar"',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}