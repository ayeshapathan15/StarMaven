import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/smart_grocery_data.dart';

class SmartUploadService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload smart grocery database
  static Future<void> uploadSmartGroceryDatabase() async {
    print('🚀 Uploading smart grocery database...');

    try {
      final groceryData = SmartGroceryData.getSmartGroceryData();

      for (var categoryEntry in groceryData.entries) {
        await _uploadCategory(categoryEntry.key, categoryEntry.value);
      }

      print('✅ Smart grocery database uploaded successfully!');
      print('📊 Total categories: ${groceryData.length}');
    } catch (e) {
      print('❌ Upload failed: $e');
      rethrow;
    }
  }

  static Future<void> _uploadCategory(
    String categoryId,
    Map<String, dynamic> categoryData,
  ) async {
    final categoryRef = _firestore
        .collection('grocery_categories')
        .doc(categoryId);

    await categoryRef.set({
      'name': categoryData['name'],
      'aliases': categoryData['aliases'],
      'questions': categoryData['questions'],
      'brands': categoryData['brands'],
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('  ✅ Uploaded category: $categoryId');
  }

  /// Add new product from OCR scan
  static Future<void> addProductFromOCR({
    required String categoryId,
    required String brandName,
    required String productType,
    required String variant,
    required double price,
    required double mrp,
  }) async {
    try {
      final categoryRef = _firestore
          .collection('grocery_categories')
          .doc(categoryId);

      await categoryRef.update({
        'brands.$brandName.types.$productType.variants.$variant': {
          'price': price,
          'mrp': mrp,
          'addedBy': 'ocr_scan',
          'addedAt': FieldValue.serverTimestamp(),
        },
      });

      print('✅ Added new product from OCR: $brandName $productType $variant');
    } catch (e) {
      print('❌ Failed to add product from OCR: $e');
    }
  }
}
