import 'dart:math';
import 'package:flutter/material.dart';
import '../services/enhanced_voice_assistant.dart';

class SiriOverlay extends StatefulWidget {
  final VoidCallback? onClose;
  
  const SiriOverlay({Key? key, this.onClose}) : super(key: key);

  @override
  State<SiriOverlay> createState() => _SiriOverlayState();
}

class _SiriOverlayState extends State<SiriOverlay>
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
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
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
          _pulseController.reset();
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
      child: GestureDetector(
        onTap: () {
          // Close on tap outside
          widget.onClose?.call();
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main Siri circle
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
                              color: _getGlowColor().withOpacity(0.8),
                              blurRadius: 50,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.95),
                            ),
                            child: Icon(
                              _getStatusIcon(),
                              size: 30,
                              color: _getGlowColor(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: 50),
                  
                  // Status text
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusMessage(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
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
      case 'WakeWordDetected':
      case 'ListeningForCommand':
        return [
          Colors.blue.withOpacity(0.9),
          Colors.cyan.withOpacity(0.7),
          Colors.transparent,
        ];
      case 'ProcessingCommand':
        return [
          Colors.purple.withOpacity(0.9),
          Colors.pink.withOpacity(0.7),
          Colors.transparent,
        ];
      case 'CommandSuccess':
        return [
          Colors.green.withOpacity(0.9),
          Colors.teal.withOpacity(0.7),
          Colors.transparent,
        ];
      case 'CommandFailed':
      case 'Error':
        return [
          Colors.red.withOpacity(0.9),
          Colors.orange.withOpacity(0.7),
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
      case 'WakeWordDetected':
      case 'ListeningForCommand':
        return Colors.blue;
      case 'ProcessingCommand':
        return Colors.purple;
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

  String _getStatusMessage() {
    if (_currentState == null) return 'Nova';
    
    switch (_currentState!.status) {
      case 'WakeWordDetected':
        return 'Yes?';
      case 'ListeningForCommand':
        return 'What can I help you with?';
      case 'CommandReceived':
        return 'Got it!';
      case 'ProcessingCommand':
        return 'Processing...';
      case 'CommandSuccess':
        return 'Done!';
      case 'CommandFailed':
        return 'Try again';
      case 'Error':
        return 'Sorry, try again';
      default:
        return _currentState!.message.isNotEmpty ? _currentState!.message : 'Nova';
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
    };
    return names[langCode] ?? 'English';
  }
}