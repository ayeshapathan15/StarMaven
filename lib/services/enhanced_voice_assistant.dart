import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:translator/translator.dart';
import 'voice_service.dart';
import 'tts_service.dart';
import 'voice_command_processor.dart';

class EnhancedVoiceAssistant {
  static EnhancedVoiceAssistant? _instance;
  static EnhancedVoiceAssistant get instance {
    _instance ??= EnhancedVoiceAssistant._internal();
    return _instance!;
  }
  
  EnhancedVoiceAssistant._internal();
  
  final VoiceService _voiceService = VoiceService();
  final GoogleTranslator _translator = GoogleTranslator();
  
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isProcessingCommand = false;
  bool _isAssistantActive = false;
  Timer? _listeningTimer;
  String _detectedLanguage = 'en';
  
  StreamController<AssistantState> _stateController = StreamController<AssistantState>.broadcast();
  Stream<AssistantState> get stateStream => _stateController.stream;
  
  // Wake words in multiple languages (Siri-like)
  final Map<String, List<String>> _wakeWords = {
    'en': ['hey siri', 'ok siri', 'siri', 'hey nova', 'ok nova', 'nova'],
    'hi': ['हे सिरी', 'ओके सिरी', 'सिरी', 'हे नोवा', 'ओके नोवा', 'नोवा', 'hey siri', 'ok siri'],
    'mr': ['हे सिरी', 'ओके सिरी', 'सिरी', 'हे नोवा', 'ओके नोवा', 'नोवा', 'hey siri'],
    'kn': ['ಹೇ ಸಿರಿ', 'ಓಕೆ ಸಿರಿ', 'ಸಿರಿ', 'ಹೇ ನೋವಾ', 'ಓಕೆ ನೋವಾ', 'ನೋವಾ', 'hey siri'],
    'ta': ['ஹே சிரி', 'ஓகே சிரி', 'சிரி', 'ஹே நோவா', 'ஓகே நோவா', 'நோவா', 'hey siri'],
    'te': ['హే సిరి', 'ఓకే సిరి', 'సిరి', 'హే నోవా', 'ఓకే నోవా', 'నోవా', 'hey siri'],
    'bn': ['হে সিরি', 'ওকে সিরি', 'সিরি', 'হে নোভা', 'ওকে নোভা', 'নোভা', 'hey siri'],
    'gu': ['હે સિરી', 'ઓકે સિરી', 'સિરી', 'હે નોવા', 'ઓકે નોવા', 'નોવા', 'hey siri'],
    'pa': ['ਹੇ ਸਿਰੀ', 'ਓਕੇ ਸਿਰੀ', 'ਸਿਰੀ', 'ਹੇ ਨੋਵਾ', 'ਓਕੇ ਨੋਵਾ', 'ਨੋਵਆ', 'hey siri'],
    'ml': ['ഹേ സിരി', 'ഓകെ സിരി', 'സിരി', 'ഹേ നോവ', 'ഓകെ നോവ', 'നോവ', 'hey siri'],
    'or': ['ହେ ସିରି', 'ଓକେ ସିରି', 'ସିରି', 'ହେ ନୋଭା', 'ଓକେ ନୋଭା', 'ନୋଭା', 'hey siri'],
    'as': ['হে সিরি', 'অকে সিরি', 'সিরি', 'হে নোভা', 'অকে নোভা', 'নোভা', 'hey siri'],
  };

  bool get isListening => _isListening;
  bool get isProcessingCommand => _isProcessingCommand;
  bool get isAssistantActive => _isAssistantActive;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Request permissions
      await _requestPermissions();
      
      // Initialize services
      await _voiceService.initialize();
      await TTSService.initialize();
      
      _isInitialized = true;
      _updateState('Initialized', 'Voice assistant ready');
      
    } catch (e) {
      _updateState('Error', 'Failed to initialize: $e');
      rethrow;
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.speech,
    ].request();
  }

  Future<void> startBackgroundListening() async {
    if (!_isInitialized || _isListening) return;
    
    _isListening = true;
    _updateState('Listening', 'Listening for wake word...');
    
    _startContinuousListening();
  }

  void _startContinuousListening() {
    _listeningTimer = Timer.periodic(Duration(milliseconds: 500), (timer) async {
      if (!_isListening || _isProcessingCommand || _isAssistantActive) return;
      
      try {
        if (!_voiceService.isListening) {
          await _voiceService.startListening(
            onResult: (text) {
              debugPrint('🎤 Heard: $text');
              _checkForWakeWord(text);
            },
            onListeningComplete: () {
              debugPrint('👂 Listening cycle complete');
            },
            timeout: Duration(seconds: 2),
            language: 'en_US',
          );
        }
      } catch (e) {
        debugPrint('❌ Listening error: $e');
        await Future.delayed(Duration(milliseconds: 200));
      }
    });
  }

  void _checkForWakeWord(String text) async {
    if (_isProcessingCommand || _isAssistantActive) return;
    
    String lowerText = text.toLowerCase().trim();
    debugPrint('🔍 Checking for wake words in: "$lowerText"');
    
    // Check wake words in all languages
    for (String lang in _wakeWords.keys) {
      for (String wakeWord in _wakeWords[lang]!) {
        if (lowerText.contains(wakeWord.toLowerCase())) {
          debugPrint('🎯 Wake word detected: "$wakeWord" in $lang');
          _detectedLanguage = lang;
          await _onWakeWordDetected();
          return;
        }
      }
    }
  }

  Future<void> _onWakeWordDetected() async {
    if (_isProcessingCommand || _isAssistantActive) return;
    
    _isProcessingCommand = true;
    _isAssistantActive = true;
    
    // Stop background listening
    await _voiceService.stopListening();
    _listeningTimer?.cancel();
    
    // Simple haptic feedback
    try {
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Haptic feedback not available: $e');
    }
    
    _updateState('WakeWordDetected', 'Wake word detected!');
    
    // Brief pause then start listening for command
    await Future.delayed(Duration(milliseconds: 500));
    
    // Listen for command immediately
    await _listenForCommand();
  }

  Future<void> _listenForCommand() async {
    try {
      _updateState('ListeningForCommand', 'What can I help you with?');
      
      String command = '';
      bool commandReceived = false;
      
      await _voiceService.startListening(
        onResult: (text) {
          command = text;
          if (text.isNotEmpty) {
            debugPrint('🎯 Command received: $text');
            _updateState('CommandReceived', 'Processing: "$text"');
          }
        },
        onListeningComplete: () {
          commandReceived = true;
        },
        timeout: Duration(seconds: 6),
        language: _getLanguageCode(_detectedLanguage),
      );
      
      // Wait for command completion
      int attempts = 0;
      while (!commandReceived && attempts < 60) {
        await Future.delayed(Duration(milliseconds: 100));
        attempts++;
      }
      
      if (command.isNotEmpty && command.trim().length > 1) {
        await _processCommand(command);
      } else {
        _updateState('CommandFailed', "I didn't hear anything");
        await _speakInDetectedLanguage("I didn't hear anything. Try saying 'Hey Nova' again.");
      }
      
    } catch (e) {
      debugPrint('❌ Command listening error: $e');
      _updateState('Error', 'Sorry, there was an error');
      await _speakInDetectedLanguage('Sorry, there was an error');
    } finally {
      _resumeBackgroundListening();
    }
  }

  Future<void> _processCommand(String command) async {
    try {
      _updateState('ProcessingCommand', 'Processing command...');
      
      // Translate command to English if needed (with timeout)
      String englishCommand = command;
      if (_detectedLanguage != 'en') {
        try {
          var translation = await _translator.translate(command, to: 'en').timeout(Duration(seconds: 1));
          englishCommand = translation.text;
        } catch (e) {
          // Continue with original command if translation fails or times out
        }
      }
      
      // Process the command
      VoiceCommandResult result = await VoiceCommandProcessor.processCommand(englishCommand);
      
      String responseMessage = result.message;
      
      // Translate response back to detected language if needed (with timeout)
      if (_detectedLanguage != 'en' && result.success) {
        try {
          var translation = await _translator.translate(responseMessage, to: _detectedLanguage).timeout(Duration(milliseconds: 800));
          responseMessage = translation.text;
        } catch (e) {
          // Use English response if translation fails or times out
        }
      }
      
      await _speakInDetectedLanguage(responseMessage);
      
      if (result.success) {
        _updateState('CommandSuccess', responseMessage);
        try {
          HapticFeedback.selectionClick();
        } catch (e) {
          // Ignore haptic errors
        }
      } else {
        _updateState('CommandFailed', responseMessage);
      }
      
    } catch (e) {
      await _speakInDetectedLanguage('Sorry, I couldn\'t process that command');
      _updateState('Error', 'Command processing failed');
    }
  }

  Future<void> _speakInDetectedLanguage(String text) async {
    String languageCode = _getLanguageCode(_detectedLanguage);
    await TTSService.speak(text, _getLanguageName(_detectedLanguage));
  }

  String _getLanguageCode(String lang) {
    final Map<String, String> codes = {
      'en': 'en_IN',
      'hi': 'hi_IN',
      'mr': 'mr_IN',
      'kn': 'kn_IN',
      'ta': 'ta_IN',
      'te': 'te_IN',
      'bn': 'bn_IN',
      'gu': 'gu_IN',
      'pa': 'pa_IN',
      'ml': 'ml_IN',
      'or': 'or_IN',
      'as': 'as_IN',
      'es': 'es_ES',
      'fr': 'fr_FR',
      'de': 'de_DE',
      'it': 'it_IT',
      'pt': 'pt_BR',
      'ru': 'ru_RU',
      'ja': 'ja_JP',
      'ko': 'ko_KR',
      'zh': 'zh_CN',
      'ar': 'ar_SA',
    };
    return codes[lang] ?? 'en_IN';
  }

  String _getLanguageName(String lang) {
    final Map<String, String> names = {
      'en': 'english',
      'hi': 'hindi',
      'mr': 'marathi',
      'kn': 'kannada',
      'ta': 'tamil',
      'te': 'telugu',
      'bn': 'bengali',
      'gu': 'gujarati',
      'pa': 'punjabi',
      'ml': 'malayalam',
      'or': 'odia',
      'as': 'assamese',
      'es': 'spanish',
      'fr': 'french',
      'de': 'german',
      'it': 'italian',
      'pt': 'portuguese',
      'ru': 'russian',
      'ja': 'japanese',
      'ko': 'korean',
      'zh': 'chinese',
      'ar': 'arabic',
    };
    return names[lang] ?? 'english';
  }

  void _resumeBackgroundListening() async {
    await Future.delayed(Duration(milliseconds: 1500));
    _isProcessingCommand = false;
    _isAssistantActive = false;
    
    if (_isListening) {
      _updateState('Listening', 'Listening for "Hey Nova"...');
      _startContinuousListening();
    }
  }

  Future<void> stopBackgroundListening() async {
    _isListening = false;
    _isProcessingCommand = false;
    _isAssistantActive = false;
    
    _listeningTimer?.cancel();
    await _voiceService.stopListening();
    
    _updateState('Stopped', 'Voice assistant stopped');
  }

  Future<void> manualTrigger() async {
    if (!_isProcessingCommand && !_isAssistantActive) {
      await _onWakeWordDetected();
    }
  }

  void _updateState(String status, String message) {
    _stateController.add(AssistantState(
      status: status,
      message: message,
      isListening: _isListening,
      isProcessingCommand: _isProcessingCommand,
      isAssistantActive: _isAssistantActive,
      detectedLanguage: _detectedLanguage,
    ));
  }

  Future<void> dispose() async {
    await stopBackgroundListening();
    await _stateController.close();
    _voiceService.dispose();
    _instance = null;
  }
}

class AssistantState {
  final String status;
  final String message;
  final bool isListening;
  final bool isProcessingCommand;
  final bool isAssistantActive;
  final String detectedLanguage;

  AssistantState({
    required this.status,
    required this.message,
    required this.isListening,
    required this.isProcessingCommand,
    required this.isAssistantActive,
    required this.detectedLanguage,
  });
}