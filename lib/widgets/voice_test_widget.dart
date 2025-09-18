import 'package:flutter/material.dart';
import '../services/voice_assistant_manager.dart';
import '../services/enhanced_voice_assistant.dart';

class VoiceTestWidget extends StatefulWidget {
  const VoiceTestWidget({Key? key}) : super(key: key);

  @override
  State<VoiceTestWidget> createState() => _VoiceTestWidgetState();
}

class _VoiceTestWidgetState extends State<VoiceTestWidget> {
  String _status = 'Not initialized';
  
  @override
  void initState() {
    super.initState();
    _listenToStatus();
  }
  
  void _listenToStatus() {
    EnhancedVoiceAssistant.instance.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _status = '${state.status}: ${state.message}';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Voice Assistant Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _status,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  VoiceAssistantManager.instance.manualTrigger();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  'Test Voice',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  VoiceAssistantManager.instance.showPopup();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  'Show Popup',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}