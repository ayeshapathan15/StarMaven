import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/tts_service.dart';
import '../services/multi_image_ocr_parser.dart';

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  final ImagePicker _picker = ImagePicker();
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  List<File> _capturedImages = [];
  bool _isProcessing = false;
  String _combinedText = '';
  Map<String, dynamic>? _parsedProduct;
  int _currentPhotoStep = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  final List<String> _photoSteps = [
    'Front of the product',
    'Back of the product',
    'Side/Ingredients panel',
  ];

  @override
  void dispose() {
    textRecognizer.close();
    super.dispose();
  }

  Future<void> _startMultiPhotoCapture() async {
    setState(() {
      _capturedImages.clear();
      _combinedText = '';
      _parsedProduct = null;
      _currentPhotoStep = 0;
      _isProcessing = false;
    });

    await _captureNextPhoto();
  }

  Future<void> _captureNextPhoto() async {
    if (_currentPhotoStep >= _photoSteps.length) {
      await _processAllImages();
      return;
    }

    // Show instruction dialog
    bool? shouldCapture = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Photo ${_currentPhotoStep + 1} of ${_photoSteps.length}',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStepIcon(_currentPhotoStep),
                  size: 64,
                  color: const Color(0xFF2C3E50),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please capture: ${_photoSteps[_currentPhotoStep]}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Make sure the text is clear and readable',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              if (_currentPhotoStep > 0)
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Skip This Photo'),
                ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Take Photo'),
              ),
            ],
          ),
    );

    if (shouldCapture == true) {
      await _capturePhoto();
    } else {
      _currentPhotoStep++;
      await _captureNextPhoto();
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile != null) {
        setState(() {
          _capturedImages.add(File(pickedFile.path));
        });

        // Show captured image and ask for next photo
        bool? continueCapture = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Photo ${_currentPhotoStep + 1} Captured!'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(pickedFile.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentPhotoStep < _photoSteps.length - 1
                          ? 'Ready for next photo?'
                          : 'Ready to process all images?',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      _capturedImages.removeLast(); // Remove last added image
                      Navigator.pop(context, false);
                    },
                    child: const Text('Retake'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      _currentPhotoStep < _photoSteps.length - 1
                          ? 'Next Photo'
                          : 'Process Images',
                    ),
                  ),
                ],
              ),
        );

        if (continueCapture == true) {
          _currentPhotoStep++;
          await _captureNextPhoto();
        } else {
          await _capturePhoto(); // Retake current photo
        }
      }
    } catch (e) {
      _showSnackBar('Error capturing image: $e', isError: true);
    }
  }

  Future<void> _processAllImages() async {
    if (_capturedImages.isEmpty) {
      _showSnackBar('No images to process', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    _showSnackBar(
      'Processing ${_capturedImages.length} images...',
      isLoading: true,
    );

    String allText = '';

    try {
      // Process each image with horizontal parsing
      for (int i = 0; i < _capturedImages.length; i++) {
        String imageText = await MultiImageOCRParser.processImageHorizontally(
          _capturedImages[i],
        );

        allText += '=== IMAGE ${i + 1} (${_photoSteps[i]}) ===\n';
        allText += imageText;
        allText += '\n' + '=' * 50 + '\n\n';

        // Show progress
        _showSnackBar('Processed image ${i + 1} of ${_capturedImages.length}');
      }

      setState(() {
        _combinedText = allText;
      });

      // Parse combined text for product information
      Map<String, dynamic> productData =
          MultiImageOCRParser.parseMultiImageData(allText);

      setState(() {
        _parsedProduct = productData;
      });

      await _addProductToDatabase(productData);
    } catch (e) {
      _showSnackBar('OCR processing failed: $e', isError: true);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _addProductToDatabase(Map<String, dynamic> productData) async {
    if (_user == null) {
      _showSnackBar('Please login first', isError: true);
      return;
    }

    try {
      // Check if product exists in main database
      CollectionReference productsRef = _firestore.collection(
        'grocery_products',
      );

      QuerySnapshot existingProducts =
          await productsRef
              .where('productName', isEqualTo: productData['productName'])
              .where('brand', isEqualTo: productData['brand'])
              .where('type', isEqualTo: productData['type'])
              .limit(1)
              .get();

      String productId;

      if (existingProducts.docs.isEmpty) {
        // Add new product to main database
        DocumentReference newProduct = await productsRef.add({
          ...productData,
          'createdAt': FieldValue.serverTimestamp(),
          'scannedBy': _user!.uid,
          'verified': false,
          'imageCount': _capturedImages.length,
          'extractedFrom': _photoSteps.take(_capturedImages.length).toList(),
        });
        productId = newProduct.id;

        _showSnackBar('✅ New product added to database!', isSuccess: true);
      } else {
        productId = existingProducts.docs.first.id;
        _showSnackBar('📦 Product found in database!');
      }

      // Add to user's grocery list
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('grocery_list')
          .add({
            ...productData,
            'productId': productId,
            'addedAt': FieldValue.serverTimestamp(),
            'isCompleted': false,
            'addedBy': 'multi_image_ocr_scan',
            'sourceImages': _capturedImages.length,
          });

      // TTS confirmation
      await TTSService.speak(
        '${productData['productName']} has been added to your grocery list',
        'english',
      );

      _showSnackBar(
        '🛒 ${productData['productName']} added to your grocery list!',
        isSuccess: true,
      );
    } catch (e) {
      print('Error adding product: $e');
      _showSnackBar('Error adding product: $e', isError: true);
    }
  }

  void _showEditProductDialog() {
    if (_parsedProduct == null) return;

    TextEditingController nameController = TextEditingController(
      text: _parsedProduct!['productName'],
    );
    TextEditingController brandController = TextEditingController(
      text: _parsedProduct!['brand'],
    );
    TextEditingController typeController = TextEditingController(
      text: _parsedProduct!['type'],
    );
    TextEditingController quantityController = TextEditingController(
      text: _parsedProduct!['quantity'],
    );
    TextEditingController priceController = TextEditingController(
      text: _parsedProduct!['price'].toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Product Details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                    ),
                  ),
                  TextField(
                    controller: brandController,
                    decoration: const InputDecoration(labelText: 'Brand'),
                  ),
                  TextField(
                    controller: typeController,
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Map<String, dynamic> updatedProduct = {
                    'productName': nameController.text,
                    'brand': brandController.text,
                    'type': typeController.text,
                    'quantity': quantityController.text,
                    'price': double.tryParse(priceController.text) ?? 0,
                    'mrp': (double.tryParse(priceController.text) ?? 0) * 1.1,
                    'category': _parsedProduct!['category'],
                  };

                  setState(() => _parsedProduct = updatedProduct);
                  Navigator.pop(context);
                  _addProductToDatabase(updatedProduct);
                },
                child: const Text('Save & Add'),
              ),
            ],
          ),
    );
  }

  IconData _getStepIcon(int step) {
    switch (step) {
      case 0:
        return Icons.camera_front;
      case 1:
        return Icons.camera_rear;
      case 2:
        return Icons.list_alt;
      default:
        return Icons.camera_alt;
    }
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
    bool isLoading = false,
  }) {
    Color backgroundColor = const Color(0xFF2C3E50);
    if (isError) backgroundColor = Colors.red.shade600;
    if (isSuccess) backgroundColor = Colors.green.shade600;
    if (isLoading) backgroundColor = Colors.orange.shade600;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                isError
                    ? Icons.error
                    : isSuccess
                    ? Icons.check_circle
                    : Icons.info,
                color: Colors.white,
              ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(
          seconds:
              isError
                  ? 4
                  : isLoading
                  ? 2
                  : 3,
        ),
      ),
    );
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
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.document_scanner,
                        size: 48,
                        color:
                            _isProcessing
                                ? Colors.orange
                                : const Color(0xFF2C3E50),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isProcessing
                            ? 'Processing Images...'
                            : 'Multi-Image OCR Scanner',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isProcessing
                            ? 'Analyzing product details from ${_capturedImages.length} images...'
                            : 'Capture 2-3 photos for complete product information',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      if (_isProcessing) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Start Capture Button
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _startMultiPhotoCapture,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Start Multi-Photo Capture'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Content Area
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Captured Images Display
                      if (_capturedImages.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Captured Images (${_capturedImages.length}):',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),
                                  itemCount: _capturedImages.length,
                                  itemBuilder: (context, index) {
                                    return Column(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey[300]!,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.file(
                                                _capturedImages[index],
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          index < _photoSteps.length
                                              ? _photoSteps[index].split(' ')[0]
                                              : 'Extra',
                                          style: const TextStyle(fontSize: 12),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Parsed Product Details
                      if (_parsedProduct != null) ...[
                        Card(
                          elevation: 3,
                          color: Colors.green[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.shopping_cart,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Extracted Product Details:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: _showEditProductDialog,
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Edit Details',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  'Product',
                                  _parsedProduct!['productName'],
                                ),
                                _buildDetailRow(
                                  'Brand',
                                  _parsedProduct!['brand'],
                                ),
                                _buildDetailRow(
                                  'Type',
                                  _parsedProduct!['type'],
                                ),
                                _buildDetailRow(
                                  'Quantity',
                                  _parsedProduct!['quantity'],
                                ),
                                _buildDetailRow(
                                  'Price',
                                  '₹${_parsedProduct!['price']}',
                                ),
                                _buildDetailRow(
                                  'Category',
                                  _parsedProduct!['category'],
                                ),
                                if (_parsedProduct!['ingredients'] != null)
                                  _buildDetailRow(
                                    'Ingredients',
                                    _parsedProduct!['ingredients'],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Combined OCR Text Display
                      if (_combinedText.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.text_fields,
                                      color: Color(0xFF2C3E50),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Combined OCR Text:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Text(
                                      _combinedText,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Empty State
                      if (_capturedImages.isEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.camera_enhance_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Multi-Photo OCR Scanner',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Capture multiple angles of your product:\n• Front view with product name\n• Back view with ingredients/details\n• Side view with additional info',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
