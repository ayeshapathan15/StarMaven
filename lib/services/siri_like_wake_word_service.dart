import 'dart:async';
import 'package:flutter/foundation.dart';
import 'voice_service.dart';
import 'voice_command_processor.dart';
import 'tts_service.dart';
import 'package:translator/translator.dart';

class SiriLikeWakeWordService {
  static SiriLikeWakeWordService? _instance;
  static SiriLikeWakeWordService get instance {
    _instance ??= SiriLikeWakeWordService._internal();
    return _instance!;
  }
  
  SiriLikeWakeWordService._internal();
  
  final VoiceService _voiceService = VoiceService();
  
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isProcessingCommand = false;
  Timer? _listeningTimer;
  
  StreamController<String> _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;
  
  bool get isListening => _isListening;
  bool get isProcessingCommand => _isProcessingCommand;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _voiceService.initialize();
      await TTSService.initialize();
      
      _isInitialized = true;
      debugPrint('✅ Siri-like wake word service initialized');
      
    } catch (e) {
      debugPrint('❌ Failed to initialize wake word service: $e');
      rethrow;
    }
  }

  Future<void> startBackgroundListening() async {
    if (!_isInitialized || _isListening) return;
    
    _isListening = true;
    _statusController.add('Listening for "Nova"...');
    
    _startContinuousListening();
  }

  void _startContinuousListening() {
    _listeningTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (!_isListening || _isProcessingCommand) return;
      
      try {
        if (!_voiceService.isListening) {
          await _voiceService.startListening(
            onResult: (text) {
              _checkForWakeWord(text);
            },
            onListeningComplete: () {
              // Automatically restart after completion
            },
            timeout: Duration(seconds: 2),
            language: _getLanguageCode(_detectedLanguage),
          );
        }
      } catch (e) {
        debugPrint('Listening cycle error: $e');
        await Future.delayed(Duration(seconds: 1));
      }
    });
  }

  final Map<String, List<String>> _wakeWords = {
    'en': ['hey nova', 'ok nova', 'nova', 'hey assistant', 'assistant'],
    'hi': ['हे नोवा', 'ओके नोवा', 'नोवा', 'असिस्टेंट', 'सहायक', 'hey nova', 'ok nova'],
    'mr': ['हे नोवा', 'ओके नोवा', 'नोवा', 'सहाय्यक', 'असिस्टंट', 'hey nova'],
    'kn': ['ಹೇ ನೋವಾ', 'ಓಕೆ ನೋವಾ', 'ನೋವಾ', 'ಸಹಾಯಕ', 'hey nova'],
    'ta': ['ஹே நோவா', 'ஓகே நோவா', 'நோவா', 'உதவியாளர்', 'hey nova'],
    'te': ['హే నోవా', 'ఓకే నోవా', 'నోవా', 'సహాయకుడు', 'hey nova'],
    'bn': ['হে নোভা', 'ওকে নোভা', 'নোভা', 'সহায়ক', 'hey nova'],
    'gu': ['હે નોવા', 'ઓકે નોવા', 'નોવા', 'સહાયક', 'hey nova'],
  };
  
  String _detectedLanguage = 'en';
  final GoogleTranslator _translator = GoogleTranslator();

  void _checkForWakeWord(String text) {
    if (_isProcessingCommand) return;
    
    String lowerText = text.toLowerCase().trim();
    
    for (String lang in _wakeWords.keys) {
      for (String wakeWord in _wakeWords[lang]!) {
        if (lowerText.contains(wakeWord.toLowerCase())) {
          _detectedLanguage = lang;
          _onWakeWordDetected();
          return;
        }
      }
    }
  }

  void _onWakeWordDetected() async {
    if (_isProcessingCommand) return;
    
    _isProcessingCommand = true;
    _statusController.add('Wake word detected! Listening for command...');
    
    // Stop background listening
    await _voiceService.stopListening();
    _listeningTimer?.cancel();
    
    // Quick acknowledgment in detected language
    String response = await _getLocalizedResponse('Yes?');
    await TTSService.speak(response, _getLanguageName(_detectedLanguage));
    
    // Wait briefly then listen for command
    await Future.delayed(Duration(milliseconds: 800));
    
    try {
      String command = '';
      
      await _voiceService.startListening(
        onResult: (text) {
          command = text;
        },
        onListeningComplete: () async {
          if (command.isNotEmpty) {
            await _processCommand(command);
          } else {
            String response = await _getLocalizedResponse('I didn\'t hear anything');
            await TTSService.speak(response, _getLanguageName(_detectedLanguage));
          }
          _resumeBackgroundListening();
        },
        timeout: Duration(seconds: 8),
        language: _getLanguageCode(_detectedLanguage),
      );
      
    } catch (e) {
      debugPrint('Error in command listening: $e');
      String response = await _getLocalizedResponse('Sorry, there was an error');
      await TTSService.speak(response, _getLanguageName(_detectedLanguage));
      _resumeBackgroundListening();
    }
  }

  Future<void> _processCommand(String command) async {
    try {
      _statusController.add('Processing: "$command"');
      
      // Process command with multilingual support
      VoiceCommandResult result = await VoiceCommandProcessor.processCommand(command);
      
      String responseMessage = result.message;
      
      // Translate response to detected language if needed
      if (_detectedLanguage != 'en' && result.success) {
        try {
          var translation = await _translator.translate(responseMessage, to: _detectedLanguage);
          responseMessage = translation.text;
        } catch (e) {
          // Use English response if translation fails
        }
      }
      
      if (result.success) {
        await TTSService.speak(responseMessage, _getLanguageName(_detectedLanguage));
        _statusController.add('✅ $responseMessage');
      } else {
        await TTSService.speak(responseMessage, _getLanguageName(_detectedLanguage));
        _statusController.add('❌ $responseMessage');
      }
      
    } catch (e) {
      debugPrint('Command processing error: $e');
      String response = await _getLocalizedResponse('Sorry, I couldn\'t process that');
      await TTSService.speak(response, _getLanguageName(_detectedLanguage));
      _statusController.add('Error processing command');
    }
  }

  void _resumeBackgroundListening() async {
    await Future.delayed(Duration(milliseconds: 1000));
    _isProcessingCommand = false;
    
    if (_isListening) {
      _statusController.add('Listening for "Nova"...');
      _startContinuousListening();
    }
  }

  Future<void> stopBackgroundListening() async {
    _isListening = false;
    _isProcessingCommand = false;
    
    _listeningTimer?.cancel();
    await _voiceService.stopListening();
    
    _statusController.add('Stopped listening');
  }

  Future<void> manualTrigger() async {
    if (!_isProcessingCommand) {
      _onWakeWordDetected();
    }
  }

  String getStatus() {
    if (_isProcessingCommand) return 'Processing command...';
    if (_isListening) return 'Listening for "Nova"...';
    return 'Stopped';
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
    };
    return names[lang] ?? 'english';
  }
  
  Future<String> _getLocalizedResponse(String text) async {
    if (_detectedLanguage == 'en') return text;
    
    try {
      var translation = await _translator.translate(text, to: _detectedLanguage);
      return translation.text;
    } catch (e) {
      return text;
    }
  }

  Future<void> dispose() async {
    await stopBackgroundListening();
    await _statusController.close();
    _voiceService.dispose();
    _instance = null;
  }
}