import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  bool get speechEnabled => _speechEnabled;
  bool get isListening => _isListening;

  /// Initialize speech recognition
  Future<void> initialize() async {
    try {
      _speechEnabled = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: ${error.errorMsg}');
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
        },
      );

      if (_speechEnabled) {
        debugPrint('✅ Speech recognition initialized successfully');
      } else {
        debugPrint('❌ Speech recognition not available');
      }
    } catch (e) {
      debugPrint('❌ Error initializing speech recognition: $e');
      _speechEnabled = false;
    }
  }

  /// Start listening for voice input with enhanced language support
  Future<void> startListening({
    required Function(String) onResult,
    required Function() onListeningComplete,
    String language = 'en_IN', // Default to Indian English
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!_speechEnabled) {
      throw Exception('Speech recognition not initialized');
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      _isListening = true;

      // Enhanced language support for multilingual input
      List<String> supportedLanguages = [
        'en_IN', // English (India)
        'hi_IN', // Hindi (India)
        'mr_IN', // Marathi (India)
      ];

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _isListening = false;
            onResult(result.recognizedWords);
            onListeningComplete();
          } else {
            // Provide interim results for better UX
            onResult(result.recognizedWords);
          }
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: language,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      debugPrint('🎤 Started listening in language: $language');
    } catch (e) {
      _isListening = false;
      debugPrint('❌ Error starting speech recognition: $e');
      rethrow;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      debugPrint('🛑 Stopped listening');
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
      debugPrint('❌ Cancelled listening');
    }
  }

  /// Get available languages
  Future<List<stt.LocaleName>> getAvailableLanguages() async {
    if (!_speechEnabled) return [];
    return await _speech.locales();
  }

  /// Check if device has microphone permission
  Future<bool> hasPermission() async {
    return await _speech.hasPermission;
  }

  /// Dispose resources
  void dispose() {
    if (_isListening) {
      _speech.cancel();
    }
  }
}
