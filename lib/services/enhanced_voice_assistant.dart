import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
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
  
  // Wake words in multiple languages
  final Map<String, List<String>> _wakeWords = {
    'en': ['hey nova', 'ok nova', 'nova', 'hey assistant', 'assistant'],
    'hi': ['हे नोवा', 'ओके नोवा', 'नोवा', 'असिस्टेंट', 'सहायक', 'hey nova', 'ok nova'],
    'mr': ['हे नोवा', 'ओके नोवा', 'नोवा', 'सहाय्यक', 'असिस्टंट', 'hey nova'],
    'kn': ['ಹೇ ನೋವಾ', 'ಓಕೆ ನೋವಾ', 'ನೋವಾ', 'ಸಹಾಯಕ', 'hey nova'],
    'ta': ['ஹே நோவா', 'ஓகே நோவா', 'நோவா', 'உதவியாளர்', 'hey nova'],
    'te': ['హే నోవా', 'ఓకే నోవా', 'నోవా', 'సహాయకుడు', 'hey nova'],
    'bn': ['হে নোভা', 'ওকে নোভা', 'নোভা', 'সহায়ক', 'hey nova'],
    'gu': ['હે નોવા', 'ઓકે નોવા', 'નોવા', 'સહાયક', 'hey nova'],
    'pa': ['ਹੇ ਨੋਵਾ', 'ਓਕੇ ਨੋਵਾ', 'ਨੋਵਾ', 'ਸਹਾਇਕ', 'hey nova'],
    'ml': ['ഹേ നോവ', 'ഓകെ നോവ', 'നോവ', 'സഹായി', 'hey nova'],
    'or': ['ହେ ନୋଭା', 'ଓକେ ନୋଭା', 'ନୋଭା', 'ସହାୟକ', 'hey nova'],
    'as': ['হে নোভা', 'অকে নোভা', 'নোভা', 'সহায়ক', 'hey nova'],
    'es': ['hola nova', 'ok nova', 'nova', 'asistente'],
    'fr': ['salut nova', 'ok nova', 'nova', 'assistant'],
    'de': ['hallo nova', 'ok nova', 'nova', 'assistent'],
    'it': ['ciao nova', 'ok nova', 'nova', 'assistente'],
    'pt': ['oi nova', 'ok nova', 'nova', 'assistente'],
    'ru': ['привет нова', 'ок нова', 'нова', 'ассистент'],
    'ja': ['ヘイノヴァ', 'オーケーノヴァ', 'ノヴァ', 'アシスタント'],
    'ko': ['헤이 노바', '오케이 노바', '노바', '어시스턴트'],
    'zh': ['嘿诺瓦', '好的诺瓦', '诺瓦', '助手'],
    'ar': ['مرحبا نوفا', 'حسنا نوفا', 'نوفا', 'مساعد'],
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
    _listeningTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
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
            timeout: Duration(seconds: 3),
            language: 'en_US',
          );
        }
      } catch (e) {
        debugPrint('❌ Listening error: $e');
        await Future.delayed(Duration(milliseconds: 500));
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
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 150);
    }
    
    _updateState('WakeWordDetected', 'Wake word detected!');
    
    // Brief pause then start listening for command
    await Future.delayed(Duration(milliseconds: 300));
    
    // Listen for command immediately
    await _listenForCommand();
  }

  Future<void> _listenForCommand() async {
    try {
      _updateState('ListeningForCommand', 'Listening for your command...');
      
      String command = '';
      bool commandReceived = false;
      
      await _voiceService.startListening(
        onResult: (text) {
          command = text;
          if (text.isNotEmpty) {
            _updateState('CommandReceived', 'Processing: "$text"');
          }
        },
        onListeningComplete: () {
          commandReceived = true;
        },
        timeout: Duration(seconds: 8),
        language: _getLanguageCode(_detectedLanguage),
      );
      
      // Wait for command completion
      int attempts = 0;
      while (!commandReceived && attempts < 80) {
        await Future.delayed(Duration(milliseconds: 100));
        attempts++;
      }
      
      if (command.isNotEmpty) {
        await _processCommand(command);
      } else {
        await _speakInDetectedLanguage("I didn't hear anything");
      }
      
    } catch (e) {
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
        HapticFeedback.lightImpact();
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
    await Future.delayed(Duration(milliseconds: 1000));
    _isProcessingCommand = false;
    _isAssistantActive = false;
    
    if (_isListening) {
      _updateState('Listening', 'Listening for wake word...');
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