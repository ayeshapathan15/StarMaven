import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/grocery_item.dart';
import '../providers/inventory_provider.dart';
import '../services/ocr_service.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final OcrService _ocrService = OcrService();
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String? _lastOcrText;

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
      if (text == null || text.isEmpty) {
        throw Exception('No text extracted from image');
      }
      final List<GroceryItem> items = _ocrService.parseReceiptText(text);

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
          _optionTile(icon: Icons.mic, title: 'Voice Input', onTap: () {}),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF34D399),
        onPressed: () {},
        child: const Icon(Icons.mic, color: Colors.white),
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
