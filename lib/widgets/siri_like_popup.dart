import 'dart:math';
import 'package:flutter/material.dart';
import '../services/enhanced_voice_assistant.dart';

class SiriLikePopup extends StatefulWidget {
  final VoidCallback? onClose;
  
  const SiriLikePopup({Key? key, this.onClose}) : super(key: key);

  @override
  State<SiriLikePopup> createState() => _SiriLikePopupState();
}

class _SiriLikePopupState extends State<SiriLikePopup>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  
  AssistantState? _currentState;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _scaleController.forward();
    
    // Listen to assistant state
    EnhancedVoiceAssistant.instance.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
        });
        
        if (state.isListening || state.isProcessingCommand) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Stack(
            children: [
              // Close button
              Positioned(
                top: 60,
                right: 20,
                child: IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Main voice assistant circle
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 200 * _pulseAnimation.value,
                          height: 200 * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: _getGradientColors(),
                              stops: [0.0, 0.7, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _getGlowColor().withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _getStatusIcon(),
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: 40),
                    
                    // Status text
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _currentState?.message ?? 'Voice Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Language indicator
                    if (_currentState?.detectedLanguage != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          _getLanguageDisplayName(_currentState!.detectedLanguage),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    
                    SizedBox(height: 60),
                    
                    // Manual trigger button
                    if (!(_currentState?.isProcessingCommand ?? false))
                      GestureDetector(
                        onTap: () async {
                          await EnhancedVoiceAssistant.instance.manualTrigger();
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors() {
    if (_currentState == null) {
      return [
        Colors.blue.withOpacity(0.8),
        Colors.purple.withOpacity(0.6),
        Colors.transparent,
      ];
    }
    
    switch (_currentState!.status) {
      case 'Listening':
        return [
          Colors.blue.withOpacity(0.8),
          Colors.cyan.withOpacity(0.6),
          Colors.transparent,
        ];
      case 'WakeWordDetected':
      case 'ListeningForCommand':
        return [
          Colors.green.withOpacity(0.8),
          Colors.lightGreen.withOpacity(0.6),
          Colors.transparent,
        ];
      case 'ProcessingCommand':
        return [
          Colors.orange.withOpacity(0.8),
          Colors.amber.withOpacity(0.6),
          Colors.transparent,
        ];
      case 'CommandSuccess':
        return [
          Colors.green.withOpacity(0.8),
          Colors.teal.withOpacity(0.6),
          Colors.transparent,
        ];
      case 'CommandFailed':
      case 'Error':
        return [
          Colors.red.withOpacity(0.8),
          Colors.pink.withOpacity(0.6),
          Colors.transparent,
        ];
      default:
        return [
          Colors.blue.withOpacity(0.8),
          Colors.purple.withOpacity(0.6),
          Colors.transparent,
        ];
    }
  }

  Color _getGlowColor() {
    if (_currentState == null) return Colors.blue;
    
    switch (_currentState!.status) {
      case 'Listening':
        return Colors.blue;
      case 'WakeWordDetected':
      case 'ListeningForCommand':
        return Colors.green;
      case 'ProcessingCommand':
        return Colors.orange;
      case 'CommandSuccess':
        return Colors.green;
      case 'CommandFailed':
      case 'Error':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon() {
    if (_currentState == null) return Icons.mic;
    
    switch (_currentState!.status) {
      case 'Listening':
        return Icons.hearing;
      case 'WakeWordDetected':
      case 'ListeningForCommand':
        return Icons.mic;
      case 'ProcessingCommand':
        return Icons.psychology;
      case 'CommandSuccess':
        return Icons.check_circle;
      case 'CommandFailed':
      case 'Error':
        return Icons.error;
      default:
        return Icons.mic;
    }
  }

  String _getLanguageDisplayName(String langCode) {
    final Map<String, String> names = {
      'en': 'English',
      'hi': 'हिंदी',
      'mr': 'मराठी',
      'kn': 'ಕನ್ನಡ',
      'ta': 'தமிழ்',
      'te': 'తెలుగు',
      'bn': 'বাংলা',
      'gu': 'ગુજરાતી',
      'pa': 'ਪੰਜਾਬੀ',
      'ml': 'മലയാളം',
      'or': 'ଓଡ଼ିଆ',
      'as': 'অসমীয়া',
      'es': 'Español',
      'fr': 'Français',
      'de': 'Deutsch',
      'it': 'Italiano',
      'pt': 'Português',
      'ru': 'Русский',
      'ja': '日本語',
      'ko': '한국어',
      'zh': '中文',
      'ar': 'العربية',
    };
    return names[langCode] ?? 'English';
  }
}