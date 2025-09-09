import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SmartConversationManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Process voice command and detect language
  static Future<Map<String, dynamic>> processVoiceCommand(
    String voiceInput,
  ) async {
    try {
      String cleanInput = voiceInput.toLowerCase().trim();

      // Detect language from input
      String detectedLanguage = _detectLanguage(cleanInput);

      // Check if it's an add command
      if (!_isAddCommand(cleanInput, detectedLanguage)) {
        return {
          'success': false,
          'response': _getLocalizedMessage('not_add_command', detectedLanguage),
          'language': detectedLanguage,
        };
      }

      // Find category from input
      String? categoryId = await _findCategoryFromInput(cleanInput);

      if (categoryId == null) {
        return {
          'success': false,
          'response': _getLocalizedMessage(
            'category_not_found',
            detectedLanguage,
          ),
          'language': detectedLanguage,
        };
      }

      // Fetch category data from database
      final categoryDoc =
          await _firestore
              .collection('grocery_categories')
              .doc(categoryId)
              .get();

      if (!categoryDoc.exists) {
        return {
          'success': false,
          'response': _getLocalizedMessage(
            'category_not_found',
            detectedLanguage,
          ),
          'language': detectedLanguage,
        };
      }

      Map<String, dynamic> categoryData = categoryDoc.data()!;

      // Extract available brands
      final brands = Map<String, dynamic>.from(categoryData['brands'] ?? {});
      List<Map<String, dynamic>> availableBrands = [];

      for (var brandEntry in brands.entries) {
        availableBrands.add({
          'key': brandEntry.key,
          'name': brandEntry.value['name'],
        });
      }

      String response = _getBrandSelectionMessage(
        categoryData['name'],
        availableBrands,
        detectedLanguage,
      );

      return {
        'success': true,
        'language': detectedLanguage,
        'category': categoryId,
        'categoryData': categoryData,
        'brands': availableBrands,
        'response': response,
      };
    } catch (e) {
      print('Error processing voice command: $e');
      return {
        'success': false,
        'response': 'Sorry, something went wrong. Please try again.',
        'language': 'english',
      };
    }
  }

  /// Process brand selection and return types - MISSING METHOD FIXED
  static Future<Map<String, dynamic>> processBrandSelection(
    String categoryId,
    String brandKey,
    Map<String, dynamic> categoryData,
  ) async {
    try {
      final brands = Map<String, dynamic>.from(categoryData['brands'] ?? {});
      final brandData = Map<String, dynamic>.from(brands[brandKey] ?? {});
      final types = Map<String, dynamic>.from(brandData['types'] ?? {});

      List<Map<String, dynamic>> availableTypes = [];

      for (var typeEntry in types.entries) {
        availableTypes.add({
          'key': typeEntry.key,
          'name': typeEntry.value['name'],
        });
      }

      String response = '';
      if (availableTypes.length == 1) {
        response = 'Only one type available. Moving to quantity selection.';
      } else {
        response = 'Please select the type:';
      }

      return {'success': true, 'types': availableTypes, 'response': response};
    } catch (e) {
      print('Error processing brand selection: $e');
      return {
        'success': false,
        'response': 'Error processing brand selection.',
      };
    }
  }

  /// Process type selection and return quantities
  static Future<Map<String, dynamic>> processTypeSelection(
    String categoryId,
    String brandKey,
    String typeKey,
    Map<String, dynamic> categoryData,
  ) async {
    try {
      final brands = Map<String, dynamic>.from(categoryData['brands'] ?? {});
      final brandData = Map<String, dynamic>.from(brands[brandKey] ?? {});
      final types = Map<String, dynamic>.from(brandData['types'] ?? {});
      final typeData = Map<String, dynamic>.from(types[typeKey] ?? {});
      final variants = Map<String, dynamic>.from(typeData['variants'] ?? {});

      List<Map<String, dynamic>> availableQuantities = [];

      for (var variantEntry in variants.entries) {
        availableQuantities.add({
          'key': variantEntry.key,
          'size': variantEntry.key,
          'price': variantEntry.value['price'],
          'mrp': variantEntry.value['mrp'],
        });
      }

      return {
        'success': true,
        'quantities': availableQuantities,
        'response': 'Please select the quantity:',
      };
    } catch (e) {
      print('Error processing type selection: $e');
      return {'success': false, 'response': 'Error processing type selection.'};
    }
  }

  /// Add item to user's grocery list
  static Future<Map<String, dynamic>> addToGroceryList({
    required String category,
    required String brand,
    required String type,
    required String quantity,
    required Map<String, dynamic> categoryData,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'success': false, 'response': 'Please login first.'};
      }

      final brands = Map<String, dynamic>.from(categoryData['brands'] ?? {});
      final brandData = Map<String, dynamic>.from(brands[brand] ?? {});
      final types = Map<String, dynamic>.from(brandData['types'] ?? {});
      final typeData = Map<String, dynamic>.from(types[type] ?? {});
      final variants = Map<String, dynamic>.from(typeData['variants'] ?? {});
      final variantData = Map<String, dynamic>.from(variants[quantity] ?? {});

      String productName = '${brandData['name']} ${typeData['name']} $quantity';

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('grocery_list')
          .add({
            'productName': productName,
            'category': category,
            'brand': brandData['name'],
            'type': typeData['name'],
            'quantity': quantity,
            'price': variantData['price'] ?? 0,
            'mrp': variantData['mrp'] ?? 0,
            'addedBy': 'voice_assistant',
            'addedAt': FieldValue.serverTimestamp(),
            'isCompleted': false,
          });

      return {
        'success': true,
        'response': '$productName has been added to your grocery list!',
      };
    } catch (e) {
      print('Error adding to grocery list: $e');
      return {
        'success': false,
        'response': 'Failed to add item to grocery list.',
      };
    }
  }

  /// Detect language from voice input
  static String _detectLanguage(String text) {
    // Marathi detection
    if (text.contains(
      RegExp(
        r'(add kara|tak|ghya|pahije|kiti|konata|kon sa|kart|मला|तू|तुम्हाला|आहे|हवे)',
      ),
    )) {
      return 'marathi';
    }

    // Hindi detection
    if (text.contains(RegExp(r'[\u0900-\u097F]')) ||
        text.contains(
          RegExp(
            r'(chahiye|dalo|kitna|kaun sa|koun|maine|tumhe|चाहिए|डालो|कितना|कौन)',
          ),
        )) {
      return 'hindi';
    }

    return 'english';
  }

  /// Check if input is an add command
  static bool _isAddCommand(String input, String language) {
    switch (language) {
      case 'marathi':
        return input.contains(RegExp(r'(add kara|tak|ghya|add kar|जोडा|टाका)'));
      case 'hindi':
        return input.contains(
          RegExp(r'(add|dalo|chahiye|jodo|जोड़|डालो|चाहिए)'),
        );
      default:
        return input.contains(RegExp(r'(add|need|want|get|buy)'));
    }
  }

  /// Find category from voice input
  static Future<String?> _findCategoryFromInput(String input) async {
    try {
      final categoriesSnapshot =
          await _firestore.collection('grocery_categories').get();

      for (var doc in categoriesSnapshot.docs) {
        final data = doc.data();
        final aliases = List<String>.from(data['aliases'] ?? []);

        for (String alias in aliases) {
          if (input.contains(alias.toLowerCase())) {
            return doc.id;
          }
        }
      }

      return null;
    } catch (e) {
      print('Error finding category: $e');
      return null;
    }
  }

  /// Get localized messages
  static String _getLocalizedMessage(String messageType, String language) {
    Map<String, Map<String, String>> messages = {
      'not_add_command': {
        'english': 'Please say "add [item]" or "I need [item]"',
        'hindi': 'कृपया "add [वस्तु]" या "[वस्तु] चाहिए" कहें',
        'marathi': 'कृपया "[वस्तू] add kara" किंवा "[वस्तू] हवे" बोला',
      },
      'category_not_found': {
        'english': 'Sorry, that product is not available in our database.',
        'hindi': 'माफ करें, वह उत्पाद हमारे डेटाबेस में उपलब्ध नहीं है।',
        'marathi': 'माफ करा, ते उत्पादन आमच्या डेटाबेसमध्ये उपलब्ध नाही.',
      },
    };

    return messages[messageType]?[language] ??
        messages[messageType]?['english'] ??
        'Sorry, I didn\'t understand.';
  }

  /// Get brand selection message
  static String _getBrandSelectionMessage(
    Map<String, dynamic> categoryName,
    List<Map<String, dynamic>> brands,
    String language,
  ) {
    String categoryNameText =
        categoryName[language] ?? categoryName['english'] ?? '';
    String brandsList = brands.map((b) => b['name']).join(', ');

    switch (language) {
      case 'marathi':
        return '$categoryNameText साठी ब्रँड निवडा. उपलब्ध ब्रँड: $brandsList';
      case 'hindi':
        return '$categoryNameText के लिए ब्रांड चुनें। उपलब्ध ब्रांड: $brandsList';
      default:
        return 'Select brand for $categoryNameText. Available brands: $brandsList';
    }
  }
}
