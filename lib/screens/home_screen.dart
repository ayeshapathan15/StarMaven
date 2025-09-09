import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ocr_service.dart';
import '../services/image_service.dart';
import '../services/voice_service.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final OCRService _ocrService = OCRService();
  final ImageService _imageService = ImageService();
  final VoiceService _voiceService = VoiceService();

  String _extractedText = '';
  String _voiceText = '';
  bool _isProcessing = false;
  bool _isListening = false;
  File? _selectedImage;
  double _confidence = 0.0;
  bool _ocrSuccess = false;

  late AnimationController _voiceAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _voiceAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeVoice();
    _setupAnimations();
  }

  void _setupAnimations() {
    _voiceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _voiceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _voiceAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _initializeVoice() async {
    try {
      await _voiceService.initialize();
    } catch (e) {
      _showSnackBar('Voice recognition not available: $e');
    }
  }

  Future<void> _processImageFromCamera() async {
    await _processImage(() => _imageService.captureImage(), 'camera');
  }

  Future<void> _processImageFromGallery() async {
    await _processImage(() => _imageService.selectFromGallery(), 'gallery');
  }

  Future<void> _startVoiceInput() async {
    if (!_voiceService.speechEnabled) {
      _showSnackBar(
        'Speech recognition not available. Please check permissions.',
      );
      return;
    }

    if (_isListening) {
      await _stopVoiceInput();
      return;
    }

    try {
      setState(() {
        _isListening = true;
        _voiceText = '';
      });

      _voiceAnimationController.repeat(reverse: true);
      _pulseAnimationController.repeat(reverse: true);
      _showSnackBar('🎤 Listening... Speak now!');

      await _voiceService.startListening(
        onResult: (recognizedWords) {
          setState(() {
            _voiceText = recognizedWords;
          });
        },
        onListeningComplete: () {
          _stopVoiceInput();
          if (_voiceText.isNotEmpty) {
            _processVoiceInput(_voiceText);
          }
        },
        language: 'en_IN',
      );
    } catch (e) {
      _showSnackBar('Voice input failed: $e');
      _stopVoiceInput();
    }
  }

  Future<void> _stopVoiceInput() async {
    await _voiceService.stopListening();
    _voiceAnimationController.stop();
    _pulseAnimationController.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _processVoiceInput(String voiceText) {
    if (voiceText.trim().isEmpty) {
      _showSnackBar('No voice input detected. Please try again.');
      return;
    }

    setState(() {
      _extractedText = voiceText.trim();
      _ocrSuccess = true;
      _confidence = 95.0;
      _selectedImage = null;
    });

    _showSnackBar('✅ Voice input processed successfully!');
  }

  Future<void> _processImage(
    Future<File?> Function() imageSource,
    String source,
  ) async {
    try {
      setState(() {
        _isProcessing = true;
        _extractedText = '';
        _voiceText = '';
        _selectedImage = null;
        _confidence = 0.0;
        _ocrSuccess = false;
      });

      _showSnackBar('📷 Selecting image from $source...');

      final File? imageFile = await imageSource();

      if (imageFile == null) {
        _showSnackBar('No image selected');
        return;
      }

      setState(() {
        _selectedImage = imageFile;
      });

      _showSnackBar('🔍 Processing image with AI OCR...');

      final Map<String, dynamic> result = await _ocrService
          .extractTextWithDetails(imageFile);

      setState(() {
        _extractedText = result['text'] as String;
        _ocrSuccess = result['success'] as bool;
        _confidence = (result['confidence'] as double?) ?? 0.0;
      });

      if (_ocrSuccess) {
        if (_extractedText.contains('No text detected')) {
          _showSnackBar(
            '⚠️ No text found. Try with better lighting or clearer text.',
          );
        } else {
          _showSnackBar('✅ Text extraction completed successfully!');
        }
      } else {
        _showSnackBar('❌ OCR failed: $_extractedText');
      }
    } catch (e) {
      setState(() {
        _extractedText = 'Error: ${e.toString()}';
        _ocrSuccess = false;
      });
      _showSnackBar('❌ Error: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_extractedText.isNotEmpty &&
        _ocrSuccess &&
        !_extractedText.contains('No text detected')) {
      Clipboard.setData(ClipboardData(text: _extractedText));
      _showSnackBar('📋 Text copied to clipboard!');
    } else {
      _showSnackBar('No text to copy');
    }
  }

  void _clearResults() {
    setState(() {
      _extractedText = '';
      _voiceText = '';
      _selectedImage = null;
      _confidence = 0.0;
      _ocrSuccess = false;
    });
    if (_isListening) {
      _stopVoiceInput();
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.indigo.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade600,
              Colors.indigo.shade800,
              Colors.purple.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildCustomAppBar(),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Section
                      _buildHeroSection(),
                      const SizedBox(height: 32),

                      // Action Buttons
                      _buildActionButtons(),
                      const SizedBox(height: 24),

                      // Processing/Voice Listening Status
                      if (_isProcessing) _buildProcessingCard(),
                      if (_isListening) _buildVoiceListeningCard(),

                      // Selected Image Preview
                      if (_selectedImage != null &&
                          !_isProcessing &&
                          !_isListening)
                        _buildImagePreview(),

                      // Results Section
                      if (_extractedText.isNotEmpty &&
                          !_isProcessing &&
                          !_isListening)
                        _buildResultsCard(),

                      const SizedBox(height: 24),

                      // Tips Section
                      _buildTipsCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart OCR Studio',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'AI-Powered Text & Voice Recognition',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          if (_extractedText.isNotEmpty || _voiceText.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _clearResults,
                tooltip: 'Clear results',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade400, Colors.purple.shade400],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Extract Text with AI Precision',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Advanced OCR & Speech Recognition\nPowered by Google ML Kit',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Image Processing Row
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.camera_alt,
                title: 'Capture',
                subtitle: 'Take Photo',
                color: Colors.blue,
                onTap:
                    (_isProcessing || _isListening)
                        ? null
                        : _processImageFromCamera,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.photo_library,
                title: 'Gallery',
                subtitle: 'Select Image',
                color: Colors.green,
                onTap:
                    (_isProcessing || _isListening)
                        ? null
                        : _processImageFromGallery,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Voice Input
        AnimatedBuilder(
          animation: _voiceAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isListening ? _voiceAnimation.value : 1.0,
              child: _buildVoiceActionCard(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceActionCard() {
    return GestureDetector(
      onTap: (_isProcessing) ? null : _startVoiceInput,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                _isListening
                    ? [Colors.red.shade400, Colors.red.shade600]
                    : [Colors.orange.shade400, Colors.deepOrange.shade500],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (_isListening ? Colors.red : Colors.orange).withOpacity(
                0.3,
              ),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow:
                        _isListening
                            ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(
                                  0.3 * _pulseAnimation.value,
                                ),
                                blurRadius: 20 * _pulseAnimation.value,
                                spreadRadius: 10 * _pulseAnimation.value,
                              ),
                            ]
                            : null,
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 28,
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isListening ? 'Stop Listening' : 'Voice Input',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isListening ? 'Tap to stop' : 'Speak to convert',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade600),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Processing Image...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI is analyzing your image with advanced OCR',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceListeningCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.red.shade100],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200, width: 2),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(
                    0.1 + (0.2 * _pulseAnimation.value),
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: Colors.red, size: 40),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Listening...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _voiceText.isEmpty
                ? 'Speak now! I can understand Hindi-English mix'
                : _voiceText,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Selected Image',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: Image.file(
              _selectedImage!,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (_ocrSuccess ? Colors.green : Colors.red)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _selectedImage != null ? Icons.image_search : Icons.mic,
                        color: _ocrSuccess ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedImage != null
                              ? 'OCR Results'
                              : 'Voice Results',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _ocrSuccess
                              ? 'Successfully extracted'
                              : 'Processing failed',
                          style: TextStyle(
                            fontSize: 12,
                            color: _ocrSuccess ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_ocrSuccess && !_extractedText.contains('No text detected'))
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.copy, color: Colors.green),
                      onPressed: _copyToClipboard,
                      tooltip: 'Copy to clipboard',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Text Display
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 120),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _ocrSuccess ? Colors.grey[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _ocrSuccess ? Colors.grey[200]! : Colors.red[200]!,
                  width: 1,
                ),
              ),
              child: SelectableText(
                _extractedText,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: _ocrSuccess ? Colors.black87 : Colors.red[800],
                  fontFamily: 'monospace',
                ),
              ),
            ),

            // Statistics
            if (_ocrSuccess &&
                !_extractedText.contains('No text detected') &&
                !_extractedText.contains('Error:'))
              Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade50, Colors.green.shade100],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        if (_confidence > 0 && _selectedImage != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.analytics,
                                color: Colors.green[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Confidence: ${_confidence.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        if (_confidence > 0 && _selectedImage != null)
                          const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Characters',
                              '${_extractedText.length}',
                              Icons.text_fields,
                            ),
                            _buildStatItem(
                              'Words',
                              '${_extractedText.split(' ').length}',
                              Icons.article,
                            ),
                            _buildStatItem(
                              'Lines',
                              '${_extractedText.split('\n').length}',
                              Icons.format_line_spacing,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Text'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green[700], size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb, color: Colors.amber),
              ),
              const SizedBox(width: 12),
              const Text(
                'Pro Tips for Best Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTip('🔍 OCR: Use good lighting and clear focus', Colors.blue),
          _buildTip('📱 OCR: Hold camera steady, avoid shadows', Colors.blue),
          _buildTip('🎤 Voice: Speak clearly at normal pace', Colors.orange),
          _buildTip(
            '🌐 Voice: Supports Hindi-English mix perfectly',
            Colors.orange,
          ),
          _buildTip(
            '🔇 Voice: Use in quiet environment for best accuracy',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String tip, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: 12, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(tip, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _voiceService.dispose();
    _voiceAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }
}
