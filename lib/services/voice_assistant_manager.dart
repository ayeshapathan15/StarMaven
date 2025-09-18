import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'enhanced_voice_assistant.dart';
import '../widgets/siri_overlay.dart';

class VoiceAssistantManager {
  static VoiceAssistantManager? _instance;
  static VoiceAssistantManager get instance {
    _instance ??= VoiceAssistantManager._internal();
    return _instance!;
  }
  
  VoiceAssistantManager._internal();
  
  bool _isInitialized = false;
  OverlayEntry? _overlayEntry;
  BuildContext? _context;
  
  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;
    
    _context = context;
    
    // Initialize the enhanced voice assistant
    await EnhancedVoiceAssistant.instance.initialize();
    
    // Listen for authentication state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // User is logged in, start background listening
        _startBackgroundListening();
      } else {
        // User is logged out, stop background listening
        _stopBackgroundListening();
      }
    });
    
    _isInitialized = true;
  }
  
  Future<void> _startBackgroundListening() async {
    try {
      await EnhancedVoiceAssistant.instance.startBackgroundListening();
      
      // Listen for wake word detection to show popup
      EnhancedVoiceAssistant.instance.stateStream.listen((state) {
        if (state.status == 'WakeWordDetected' && _overlayEntry == null) {
          _showSiriPopup();
        } else if (state.status == 'ListeningForCommand' && _overlayEntry == null) {
          _showSiriPopup();
        } else if (state.status == 'CommandSuccess' || state.status == 'CommandFailed' || state.status == 'Error') {
          // Auto-hide popup after command completion
          Future.delayed(Duration(seconds: 2), () {
            _hideSiriPopup();
          });
        }
      });
      
    } catch (e) {
      debugPrint('Failed to start background listening: $e');
    }
  }
  
  Future<void> _stopBackgroundListening() async {
    await EnhancedVoiceAssistant.instance.stopBackgroundListening();
    _hideSiriPopup();
  }
  
  void _showSiriPopup() {
    if (_overlayEntry != null || _context == null) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => SiriOverlay(
        onClose: _hideSiriPopup,
      ),
    );
    
    Overlay.of(_context!).insert(_overlayEntry!);
  }
  
  void _hideSiriPopup() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }
  
  // Manual trigger for testing (shows popup and triggers assistant)
  Future<void> manualTrigger() async {
    if (!_isInitialized) return;
    
    _showSiriPopup();
    await EnhancedVoiceAssistant.instance.manualTrigger();
  }
  
  // Force show popup (for debugging)
  void showPopup() {
    _showSiriPopup();
  }
  
  // Force hide popup
  void hidePopup() {
    _hideSiriPopup();
  }
  
  // Check if user is logged in and assistant is active
  bool get isActive {
    return _isInitialized && 
           FirebaseAuth.instance.currentUser != null &&
           EnhancedVoiceAssistant.instance.isListening;
  }
  
  // Get current status
  String get status {
    if (!_isInitialized) return 'Not initialized';
    if (FirebaseAuth.instance.currentUser == null) return 'User not logged in';
    return EnhancedVoiceAssistant.instance.isListening ? 'Listening' : 'Stopped';
  }
  
  Future<void> dispose() async {
    await _stopBackgroundListening();
    await EnhancedVoiceAssistant.instance.dispose();
    _hideSiriPopup();
    _instance = null;
  }
}