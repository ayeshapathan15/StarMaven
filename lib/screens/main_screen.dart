import 'package:flutter/material.dart';
import '../services/smart_upload_service.dart';
import 'ocr_screen.dart';
import 'voice_screen.dart';
import 'grocery_list_screen.dart'; // Add this import

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Updated with 3 screens including Grocery List
  final List<Widget> _screens = [
    const OCRScreen(),
    const VoiceScreen(),
    const GroceryListScreen(), // Add this
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'InvenTree',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Smart Grocery Assistant',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2C3E50),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'upload_data') {
                _showUploadDialog();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'upload_data',
                    child: Row(
                      children: [
                        Icon(Icons.cloud_upload, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Upload Grocery Database'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2C3E50),
          unselectedItemColor: Colors.grey[600],
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 0,
          // Updated with 3 tabs
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.document_scanner_outlined),
              activeIcon: Icon(Icons.document_scanner),
              label: 'OCR Scanner',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mic_none_outlined),
              activeIcon: Icon(Icons.mic),
              label: 'Voice Assistant',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'My List', // Add this new tab
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.cloud_upload, color: Colors.blue),
                SizedBox(width: 8),
                Text('Upload Grocery Database'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This will upload the smart grocery database with:'),
                SizedBox(height: 8),
                Text('• 10 categories (Oils, Dairy, Rice, etc.)'),
                Text('• 25+ brands with multiple variants'),
                Text('• Multilingual voice questions'),
                Text('• Smart conversation flow'),
                SizedBox(height: 12),
                Text(
                  '⚠️ This will take a few minutes',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  _performUpload();
                },
                child: const Text('Upload Database'),
              ),
            ],
          ),
    );
  }

  void _performUpload() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Uploading smart grocery database...'),
                Text('Please wait, this may take a few minutes'),
                SizedBox(height: 8),
                Text(
                  'Do not close the app',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ),
          ),
    );

    try {
      await SmartUploadService.uploadSmartGroceryDatabase();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('🎉 Smart grocery database uploaded successfully!'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Upload failed: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
