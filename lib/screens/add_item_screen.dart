import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/grocery_item.dart';
import '../providers/inventory_provider.dart';
import '../services/ocr_service.dart';
import '../services/voice_assistant_manager.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final OCRService _ocrService = OCRService();
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String? _lastOcrText;

  List<GroceryItem> _parseReceiptText(String text) {
    List<GroceryItem> items = [];
    List<String> lines = text.split('\n');
    
    for (String line in lines) {
      line = line.trim().toLowerCase();
      if (line.contains('milk') || line.contains('दूध')) {
        items.add(GroceryItem(name: 'Milk', quantity: 1, price: 0.0, category: 'dairy'));
      } else if (line.contains('sugar') || line.contains('चीनी') || line.contains('साखर')) {
        items.add(GroceryItem(name: 'Sugar', quantity: 1, price: 0.0, category: 'sweeteners'));
      } else if (line.contains('rice') || line.contains('चावल') || line.contains('तांदूळ')) {
        items.add(GroceryItem(name: 'Rice', quantity: 1, price: 0.0, category: 'grains'));
      } else if (line.contains('oil') || line.contains('तेल')) {
        items.add(GroceryItem(name: 'Oil', quantity: 1, price: 0.0, category: 'cooking'));
      } else if (line.contains('bread') || line.contains('पाव') || line.contains('ब्रेड')) {
        items.add(GroceryItem(name: 'Bread', quantity: 1, price: 0.0, category: 'bakery'));
      }
    }
    
    return items;
  }

  Future<void> _scanReceipt() async {
    setState(() {
      _isProcessing = true;
    });
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.camera);
      if (file == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Check if file exists and is valid
      final File imageFile = File(file.path);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found');
      }

      final String text = await _ocrService.extractTextFromImage(imageFile);
      if (text.isEmpty || text.startsWith('Error:') || text.startsWith('No text')) {
        throw Exception('No text extracted from image');
      }
      // Parse items from OCR text (simplified)
      final List<GroceryItem> items = _parseReceiptText(text);

      if (!mounted) return;

      context.read<InventoryProvider>().addItems(items);
      setState(() {
        _isProcessing = false;
        _lastOcrText = text;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            items.isEmpty
                ? 'No items found in receipt'
                : 'Added ${items.length} items from receipt',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });

      String errorMessage = 'OCR failed';
      if (e.toString().contains('tessdata')) {
        errorMessage = 'OCR configuration error. Please check app setup.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Camera permission required';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$errorMessage: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Item',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            'How would you like to add items?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),

          _optionTile(
            icon: Icons.receipt_long,
            title: 'Scan Receipt',
            trailing:
                _isProcessing
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : null,
            onTap: _isProcessing ? null : _scanReceipt,
          ),
          _optionTile(
            icon: Icons.image_outlined,
            title: 'Upload Image',
            onTap: () {},
          ),
          if (_lastOcrText != null) ...<Widget>[
            const SizedBox(height: 16),
            const Text(
              'Raw OCR text',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                _lastOcrText!,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ],
          const SizedBox(height: 80),
          
          // Voice Assistant Status (invisible but shows when active)
          StreamBuilder<bool>(
            stream: Stream.periodic(Duration(seconds: 1), (_) => VoiceAssistantManager.instance.isActive),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return Container(
                  padding: EdgeInsets.all(8),
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hearing, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Voice Assistant Active - Say "Hey Nova"',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),

    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            blurRadius: 10,
            color: Color(0x11000000),
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon),
        ),
        title: Text(title),
        trailing: trailing ?? const Icon(Icons.chevron_right),
      ),
    );
  }
}
