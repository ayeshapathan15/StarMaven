import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TTSService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;
  static bool _isSpeaking = false;

  // Language codes for TTS
  static const Map<String, String> _languageCodes = {
    'english': 'en-IN',
    'hindi': 'hi-IN',
    'marathi': 'mr-IN',
  };

  /// Initialize TTS with callbacks to track speaking state
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage('en-IN');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(0.8);
      await _flutterTts.setPitch(1.0);

      // Set up callbacks to track speaking state
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('TTS started speaking');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('TTS completed speaking');
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS error: $msg');
      });

      _isInitialized = true;
      debugPrint('✅ TTS Service initialized successfully');
    } catch (e) {
      debugPrint('❌ TTS initialization error: $e');
    }
  }

  /// Speak text in specified language
  static Future<void> speak(String text, String language) async {
    if (!_isInitialized) await initialize();

    try {
      // Set language for TTS
      String languageCode = _languageCodes[language] ?? 'en-IN';
      await _flutterTts.setLanguage(languageCode);

      // Speak the text
      await _flutterTts.speak(text);
      debugPrint('🎤 TTS Speaking ($language): $text');
    } catch (e) {
      debugPrint('❌ TTS speaking error: $e');
    }
  }

  /// Stop current speech
  static Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('❌ TTS stop error: $e');
    }
  }

  /// Check if TTS is currently speaking (using our manual tracking)
  static Future<bool> isSpeaking() async {
    return _isSpeaking;
  }

  /// Dispose TTS resources
  static void dispose() {
    _flutterTts.stop();
    _isSpeaking = false;
  }
}
