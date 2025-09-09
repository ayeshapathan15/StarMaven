import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/voice_service.dart';
import '../services/smart_conversation_manager.dart';
import '../services/tts_service.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen>
    with TickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();

  String _voiceText = '';
  String _lastResponse = '';
  bool _isListening = false;
  bool _processingCommand = false;
  bool _isSpeaking = false;
  String _currentLanguage = 'english';

  // Radio Button Selection State
  String? _selectedCategory;
  String? _selectedBrand;
  String? _selectedType;
  String? _selectedQuantity;

  List<Map<String, dynamic>> _availableBrands = [];
  List<Map<String, dynamic>> _availableTypes = [];
  List<Map<String, dynamic>> _availableQuantities = [];

  bool _showBrandSelection = false;
  bool _showTypeSelection = false;
  bool _showQuantitySelection = false;
  bool _showAddButton = false;

  Map<String, dynamic>? _categoryData;

  late AnimationController _pulseController;
  late AnimationController _speakingController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _speakingAnimation;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _speakingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _speakingAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _speakingController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeServices() async {
    try {
      await _voiceService.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _showSnackBar('Error initializing voice service: $e', isError: true);
    }
  }

  Future<void> _startVoiceInput() async {
    if (!_voiceService.speechEnabled) {
      _showSnackBar('Speech recognition not available', isError: true);
      return;
    }

    if (_isListening) {
      await _stopVoiceInput();
      return;
    }

    await TTSService.stop();

    try {
      setState(() {
        _isListening = true;
        _voiceText = '';
        _processingCommand = false;
        _isSpeaking = false;
        _resetSelections();
      });

      _pulseController.repeat(reverse: true);
      _showSnackBar('🎤 Listening... Say "add [item]" or "[item] add kara"');

      await _voiceService.startListening(
        onResult: (recognizedWords) {
          setState(() {
            _voiceText = recognizedWords;
          });
        },
        onListeningComplete: () {
          _stopVoiceInput();
          if (_voiceText.isNotEmpty) {
            _processVoiceCommand();
          }
        },
        language: 'en_IN',
        timeout: const Duration(seconds: 30),
      );
    } catch (e) {
      _showSnackBar('Voice input failed: $e', isError: true);
      _stopVoiceInput();
    }
  }

  Future<void> _stopVoiceInput() async {
    await _voiceService.stopListening();
    _pulseController.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _processVoiceCommand() async {
    setState(() {
      _processingCommand = true;
    });

    try {
      final result = await SmartConversationManager.processVoiceCommand(
        _voiceText,
      );

      if (result['success'] == true) {
        _currentLanguage = result['language'] ?? 'english';
        _selectedCategory = result['category'];
        _categoryData = result['categoryData'];

        setState(() {
          _lastResponse = result['response'];
          _availableBrands = List<Map<String, dynamic>>.from(
            result['brands'] ?? [],
          );
          _showBrandSelection = true;
          _isSpeaking = true;
        });

        _speakingController.repeat(reverse: true);

        // Speak the response
        await TTSService.speak(result['response'], _currentLanguage);

        // Wait for TTS to finish
        while (await TTSService.isSpeaking()) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

        setState(() {
          _isSpeaking = false;
        });
        _speakingController.stop();
      } else {
        setState(() {
          _lastResponse =
              result['response'] ?? 'Sorry, I didn\'t understand that.';
        });
        await TTSService.speak(_lastResponse, 'english');
      }
    } catch (e) {
      setState(() {
        _lastResponse = 'Error: $e';
        _isSpeaking = false;
      });
      _speakingController.stop();
      _showSnackBar('❌ Error: $e', isError: true);
    } finally {
      setState(() {
        _processingCommand = false;
      });
    }
  }

  Future<void> _onBrandSelected(Map<String, dynamic> brand) async {
    setState(() {
      _selectedBrand = brand['key'];
      _showBrandSelection = false;
      _processingCommand = true;
    });

    try {
      final result = await SmartConversationManager.processBrandSelection(
        _selectedCategory!,
        _selectedBrand!,
        _categoryData!,
      );

      setState(() {
        _availableTypes = List<Map<String, dynamic>>.from(
          result['types'] ?? [],
        );
        _lastResponse = result['response'];
        _isSpeaking = true;
      });

      if (_availableTypes.length == 1) {
        // Only one type, auto-select and move to quantity
        _selectedType = _availableTypes[0]['key'];
        await _onTypeSelected(_availableTypes[0]);
      } else {
        // Multiple types, show selection
        setState(() {
          _showTypeSelection = true;
        });

        _speakingController.repeat(reverse: true);
        await TTSService.speak(result['response'], _currentLanguage);

        while (await TTSService.isSpeaking()) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

        setState(() {
          _isSpeaking = false;
        });
        _speakingController.stop();
      }
    } catch (e) {
      _showSnackBar('Error processing brand selection: $e', isError: true);
    } finally {
      setState(() {
        _processingCommand = false;
      });
    }
  }

  Future<void> _onTypeSelected(Map<String, dynamic> type) async {
    setState(() {
      _selectedType = type['key'];
      _showTypeSelection = false;
      _processingCommand = true;
    });

    try {
      final result = await SmartConversationManager.processTypeSelection(
        _selectedCategory!,
        _selectedBrand!,
        _selectedType!,
        _categoryData!,
      );

      setState(() {
        _availableQuantities = List<Map<String, dynamic>>.from(
          result['quantities'] ?? [],
        );
        _lastResponse = result['response'];
        _showQuantitySelection = true;
        _isSpeaking = true;
      });

      _speakingController.repeat(reverse: true);
      await TTSService.speak(result['response'], _currentLanguage);

      while (await TTSService.isSpeaking()) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      setState(() {
        _isSpeaking = false;
      });
      _speakingController.stop();
    } catch (e) {
      _showSnackBar('Error processing type selection: $e', isError: true);
    } finally {
      setState(() {
        _processingCommand = false;
      });
    }
  }

  void _onQuantitySelected(Map<String, dynamic> quantity) {
    setState(() {
      _selectedQuantity = quantity['key'];
      _showAddButton = true;
    });
  }

  Future<void> _addToGroceryList() async {
    if (_selectedCategory == null ||
        _selectedBrand == null ||
        _selectedType == null ||
        _selectedQuantity == null) {
      _showSnackBar('Please select all options first', isError: true);
      return;
    }

    try {
      setState(() {
        _processingCommand = true;
      });

      final result = await SmartConversationManager.addToGroceryList(
        category: _selectedCategory!,
        brand: _selectedBrand!,
        type: _selectedType!,
        quantity: _selectedQuantity!,
        categoryData: _categoryData!,
      );

      if (result['success'] == true) {
        setState(() {
          _lastResponse = result['response'];
          _isSpeaking = true;
        });

        _speakingController.repeat(reverse: true);
        await TTSService.speak(result['response'], _currentLanguage);

        while (await TTSService.isSpeaking()) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

        setState(() {
          _isSpeaking = false;
        });
        _speakingController.stop();

        _showSnackBar(
          '✅ Item added to grocery list successfully!',
          isSuccess: true,
        );
        _resetSelections();
      } else {
        _showSnackBar(
          result['response'] ?? 'Failed to add item',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error adding to grocery list: $e', isError: true);
    } finally {
      setState(() {
        _processingCommand = false;
      });
    }
  }

  void _resetSelections() {
    setState(() {
      _selectedCategory = null;
      _selectedBrand = null;
      _selectedType = null;
      _selectedQuantity = null;
      _availableBrands.clear();
      _availableTypes.clear();
      _availableQuantities.clear();
      _showBrandSelection = false;
      _showTypeSelection = false;
      _showQuantitySelection = false;
      _showAddButton = false;
      _categoryData = null;
    });
  }

  void _clearResults() {
    setState(() {
      _voiceText = '';
      _lastResponse = '';
    });
    _resetSelections();
    if (_isListening) {
      _stopVoiceInput();
    }
    TTSService.stop();
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    if (mounted) {
      Color backgroundColor = const Color(0xFF2C3E50);
      if (isError) backgroundColor = Colors.red.shade600;
      if (isSuccess) backgroundColor = Colors.green.shade600;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error
                    : isSuccess
                    ? Icons.check_circle
                    : Icons.info,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          duration: Duration(seconds: isError || isSuccess ? 4 : 2),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speakingController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                elevation: 4,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _speakingController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isSpeaking ? _speakingAnimation.value : 1.0,
                            child: Icon(
                              _isSpeaking
                                  ? Icons.volume_up_rounded
                                  : _isListening
                                  ? Icons.mic
                                  : Icons.mic_none_rounded,
                              size: 48,
                              color:
                                  _isSpeaking
                                      ? Colors.green
                                      : _isListening
                                      ? Colors.red
                                      : const Color(0xFF2C3E50),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isSpeaking
                            ? 'Speaking...'
                            : _processingCommand
                            ? 'Processing...'
                            : _isListening
                            ? 'Listening...'
                            : 'Smart Voice Assistant',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color:
                              _isListening
                                  ? Colors.red
                                  : const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSpeaking
                            ? 'I\'m speaking your response'
                            : _processingCommand
                            ? 'Understanding your request'
                            : _isListening
                            ? 'Say "add oil" / "tel add kara" / "तेल जोड़ें"'
                            : 'Tap mic to add groceries (English/Hindi/Marathi)',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      if (_processingCommand || _isSpeaking) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Voice Input Button
              Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isListening ? _pulseAnimation.value : 1.0,
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors:
                                _isListening
                                    ? [Colors.red.shade400, Colors.red.shade600]
                                    : [
                                      const Color(0xFF2C3E50),
                                      const Color(0xFF34495E),
                                    ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening
                                      ? Colors.red
                                      : const Color(0xFF2C3E50))
                                  .withOpacity(0.3),
                              blurRadius: _isListening ? 20 : 10,
                              spreadRadius: _isListening ? 5 : 2,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(60),
                            onTap:
                                _processingCommand || _isSpeaking
                                    ? null
                                    : _startVoiceInput,
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Expanded content area for selections
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Voice Text Display
                      if (_voiceText.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.record_voice_over,
                                      color: Color(0xFF2C3E50),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'You said:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Language: ${_currentLanguage.toUpperCase()}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _voiceText,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Assistant Response
                      if (_lastResponse.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _isSpeaking
                                          ? Icons.volume_up
                                          : Icons.assistant,
                                      color:
                                          _isSpeaking
                                              ? Colors.green
                                              : const Color(0xFF2C3E50),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isSpeaking
                                          ? 'Assistant speaking:'
                                          : 'Assistant response:',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        _isSpeaking
                                            ? Colors.green[50]
                                            : Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          _isSpeaking
                                              ? Colors.green[200]!
                                              : Colors.blue[200]!,
                                    ),
                                  ),
                                  child: Text(
                                    _lastResponse,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Brand Selection
                      if (_showBrandSelection &&
                          _availableBrands.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.branding_watermark,
                                      color: Color(0xFF2C3E50),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getLocalizedText('select_brand'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...(_availableBrands
                                    .map(
                                      (brand) => RadioListTile<String>(
                                        value: brand['key'],
                                        groupValue: _selectedBrand,
                                        title: Text(brand['name']),
                                        onChanged: (value) {
                                          if (value != null) {
                                            _onBrandSelected(brand);
                                          }
                                        },
                                      ),
                                    )
                                    .toList()),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Type Selection
                      if (_showTypeSelection && _availableTypes.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.category,
                                      color: Color(0xFF2C3E50),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getLocalizedText('select_type'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...(_availableTypes
                                    .map(
                                      (type) => RadioListTile<String>(
                                        value: type['key'],
                                        groupValue: _selectedType,
                                        title: Text(type['name']),
                                        onChanged: (value) {
                                          if (value != null) {
                                            _onTypeSelected(type);
                                          }
                                        },
                                      ),
                                    )
                                    .toList()),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Quantity Selection
                      if (_showQuantitySelection &&
                          _availableQuantities.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.format_list_numbered,
                                      color: Color(0xFF2C3E50),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getLocalizedText('select_quantity'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...(_availableQuantities
                                    .map(
                                      (quantity) => RadioListTile<String>(
                                        value: quantity['key'],
                                        groupValue: _selectedQuantity,
                                        title: Text(
                                          '${quantity['size']} - ₹${quantity['price']}',
                                        ),
                                        subtitle: Text(
                                          'MRP: ₹${quantity['mrp']}',
                                        ),
                                        onChanged: (value) {
                                          if (value != null) {
                                            _onQuantitySelected(quantity);
                                          }
                                        },
                                      ),
                                    )
                                    .toList()),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Add to List Button
                      if (_showAddButton) ...[
                        Card(
                          elevation: 4,
                          color: Colors.green[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  _getLocalizedText('ready_to_add'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (_selectedBrand != null &&
                                    _selectedType != null &&
                                    _selectedQuantity != null) ...[
                                  Text(
                                    '${_availableBrands.firstWhere((b) => b['key'] == _selectedBrand)['name']} - ${_availableTypes.firstWhere((t) => t['key'] == _selectedType)['name']} - ${_availableQuantities.firstWhere((q) => q['key'] == _selectedQuantity)['size']}',
                                    style: const TextStyle(fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _processingCommand
                                            ? null
                                            : _addToGroceryList,
                                    icon: const Icon(Icons.add_shopping_cart),
                                    label: Text(
                                      _getLocalizedText('add_to_list'),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _clearResults,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _voiceService.speechEnabled ? _startVoiceInput : null,
                      icon: Icon(_isListening ? Icons.stop : Icons.mic),
                      label: Text(_isListening ? 'Stop' : 'Start'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLocalizedText(String key) {
    Map<String, Map<String, String>> texts = {
      'select_brand': {
        'english': 'Select Brand',
        'hindi': 'ब्रांड चुनें',
        'marathi': 'ब्रँड निवडा',
      },
      'select_type': {
        'english': 'Select Type',
        'hindi': 'प्रकार चुनें',
        'marathi': 'प्रकार निवडा',
      },
      'select_quantity': {
        'english': 'Select Quantity',
        'hindi': 'मात्रा चुनें',
        'marathi': 'प्रमाण निवडा',
      },
      'ready_to_add': {
        'english': 'Ready to add to your list!',
        'hindi': 'आपकी सूची में जोड़ने के लिए तैयार!',
        'marathi': 'तुमच्या यादीत जोडण्यासाठी तयार!',
      },
      'add_to_list': {
        'english': 'Add to Grocery List',
        'hindi': 'सूची में जोड़ें',
        'marathi': 'यादीत जोडा',
      },
    };

    return texts[key]?[_currentLanguage] ?? texts[key]?['english'] ?? key;
  }
}
