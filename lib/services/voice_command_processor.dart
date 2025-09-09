import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VoiceCommandProcessor {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Multilingual patterns for voice commands
  static final Map<String, List<RegExp>> _intentPatterns = {
    'ADD_ENGLISH': [
      RegExp(r'add\s+(.+?)(?:\s+to\s+(?:the\s+)?list)?$', caseSensitive: false),
      RegExp(r'put\s+(.+?)\s+in\s+(?:the\s+)?list', caseSensitive: false),
      RegExp(r'i\s+need\s+(.+)', caseSensitive: false),
      RegExp(r'append\s+(.+)', caseSensitive: false),
      RegExp(
        r'insert\s+(.+?)(?:\s+in\s+(?:the\s+)?list)?',
        caseSensitive: false,
      ),
    ],
    'ADD_HINDI': [
      RegExp(r'(.+?)\s+(?:add\s+karo|dalo|chahiye)', caseSensitive: false),
      RegExp(r'(?:mujhe\s+)?(.+?)\s+chahiye', caseSensitive: false),
      RegExp(r'(.+?)\s+list\s+me(?:\s+dalo)?', caseSensitive: false),
      RegExp(r'(.+?)\s+add\s+karo', caseSensitive: false),
      RegExp(r'(.+?)\s+dalo', caseSensitive: false),
    ],
    'ADD_MARATHI': [
      RegExp(r'(.+?)\s+(?:tak|ghya)', caseSensitive: false),
      RegExp(r'(.+?)\s+list\s+madhe\s+tak', caseSensitive: false),
      RegExp(r'(.+?)\s+add\s+kara', caseSensitive: false),
      RegExp(r'mi\s+(.+?)\s+ghet(?:li|le)\s+aahe', caseSensitive: false),
      RegExp(r'(.+?)\s+tak\s+list\s+madhe', caseSensitive: false),
    ],
  };

  // Multilingual grocery item dictionary
  static final Map<String, Map<String, dynamic>> _groceryItems = {
    'sugar': {
      'english': ['sugar', 'white sugar', 'brown sugar'],
      'hindi': ['चीनी', 'शक्कर', 'शकर', 'cheeni', 'shakkar'],
      'marathi': ['साखर', 'sakhar'],
      'category': 'sweeteners',
    },
    'milk': {
      'english': ['milk', 'dairy milk'],
      'hindi': ['दूध', 'दुग्ध', 'dudh', 'doodh'],
      'marathi': ['दूध', 'dudh'],
      'category': 'dairy',
    },
    'rice': {
      'english': ['rice', 'basmati rice'],
      'hindi': ['चावल', 'भात', 'chawal', 'bhat'],
      'marathi': ['तांदूळ', 'भात', 'tandool', 'Tandur', 'bhat'],
      'category': 'grains',
    },
    'oil': {
      'english': ['oil', 'cooking oil', 'sunflower oil'],
      'hindi': ['तेल', 'खाना पकाने का तेल', 'tel'],
      'marathi': ['तेल', 'tel'],
      'category': 'cooking',
    },
    'salt': {
      'english': ['salt', 'table salt'],
      'hindi': ['नमक', 'namak'],
      'marathi': ['मीठ', 'mith'],
      'category': 'spices',
    },
    'bread': {
      'english': ['bread', 'white bread', 'brown bread'],
      'hindi': ['ब्रेड', 'रोटी', 'bread', 'roti'],
      'marathi': ['पाव', 'ब्रेड', 'pav', 'bread'],
      'category': 'bakery',
    },
    'flour': {
      'english': ['flour', 'wheat flour', 'all purpose flour'],
      'hindi': ['आटा', 'गेहूं का आटा', 'atta', 'maida'],
      'marathi': ['पीठ', 'गहू पीठ', 'peeth'],
      'category': 'grains',
    },
    'onion': {
      'english': ['onion', 'onions', 'red onion'],
      'hindi': ['प्याज', 'pyaj', 'pyaaz'],
      'marathi': ['कांदा', 'kanda'],
      'category': 'vegetables',
    },
  };

  /// Main function to process voice commands
  static Future<VoiceCommandResult> processCommand(String voiceText) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return VoiceCommandResult(
          intent: 'ERROR',
          itemName: '',
          originalText: voiceText,
          success: false,
          message: 'User not logged in. Please sign in first.',
        );
      }

      // Clean and normalize input
      String cleanText = _cleanInput(voiceText);

      // Extract intent and item name
      VoiceCommandResult result = _extractIntentAndItem(cleanText, voiceText);

      if (result.intent == 'ADD_ITEM' && result.itemName.isNotEmpty) {
        // Add item to user's grocery list
        await _addToGroceryList(user.uid, result.itemName, voiceText);
        result.success = true;
        result.message = 'Added "${result.itemName}" to your grocery list!';
      } else {
        result.success = false;
        result.message =
            'Sorry, I couldn\'t understand that command. Try saying "add sugar" or "साखर घ्या".';
      }

      return result;
    } catch (e) {
      return VoiceCommandResult(
        intent: 'ERROR',
        itemName: '',
        originalText: voiceText,
        success: false,
        message: 'Error processing command: ${e.toString()}',
      );
    }
  }

  /// Clean and normalize voice input
  static String _cleanInput(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s\u0900-\u097F]'), '');
  }

  /// Extract intent and item name from voice text
  static VoiceCommandResult _extractIntentAndItem(
    String cleanText,
    String originalText,
  ) {
    // Try all language patterns
    for (String patternType in _intentPatterns.keys) {
      for (RegExp pattern in _intentPatterns[patternType]!) {
        Match? match = pattern.firstMatch(cleanText);
        if (match != null && match.groupCount >= 1) {
          String itemText = match.group(1)!.trim();
          String? normalizedItem = _findGroceryItem(itemText);

          if (normalizedItem != null) {
            return VoiceCommandResult(
              intent: 'ADD_ITEM',
              itemName: normalizedItem,
              originalText: originalText,
              success: false, // Will be set to true after DB operation
              message: '',
            );
          }
        }
      }
    }

    // Fallback: check if any grocery item is directly mentioned
    String? fallbackItem = _findGroceryItem(cleanText);
    if (fallbackItem != null) {
      return VoiceCommandResult(
        intent: 'ADD_ITEM',
        itemName: fallbackItem,
        originalText: originalText,
        success: false,
        message: '',
      );
    }

    return VoiceCommandResult(
      intent: 'UNKNOWN',
      itemName: '',
      originalText: originalText,
      success: false,
      message: '',
    );
  }

  /// Find grocery item from text in any language
  static String? _findGroceryItem(String text) {
    for (String itemKey in _groceryItems.keys) {
      Map<String, dynamic> itemData = _groceryItems[itemKey]!;

      // Check in all language variants
      for (String langKey in ['english', 'hindi', 'marathi']) {
        List<String> variants = List<String>.from(itemData[langKey]);
        for (String variant in variants) {
          if (text.contains(variant.toLowerCase())) {
            return itemKey; // Return the normalized English name
          }
        }
      }
    }
    return null;
  }

  /// Add item to user's Firestore grocery list
  static Future<void> _addToGroceryList(
    String userId,
    String itemName,
    String originalCommand,
  ) async {
    CollectionReference groceryList = _firestore
        .collection('users')
        .doc(userId)
        .collection('grocery_list');

    // Check if item already exists
    QuerySnapshot existingItems =
        await groceryList
            .where('name', isEqualTo: itemName)
            .where('isCompleted', isEqualTo: false)
            .limit(1)
            .get();

    if (existingItems.docs.isEmpty) {
      // Add new item
      await groceryList.add({
        'name': itemName,
        'originalCommand': originalCommand,
        'addedBy': 'voice',
        'addedAt': FieldValue.serverTimestamp(),
        'isCompleted': false,
        'quantity': '1',
        'category': _groceryItems[itemName]?['category'] ?? 'other',
      });
    } else {
      // Update existing item timestamp
      DocumentSnapshot existingItem = existingItems.docs.first;
      await existingItem.reference.update({
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastCommand': originalCommand,
      });
    }
  }

  /// Get user's grocery list stream
  static Stream<List<GroceryItem>> getGroceryListStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('grocery_list')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => GroceryItem.fromFirestore(doc))
                  .toList(),
        );
  }
}

// Data Models
class VoiceCommandResult {
  final String intent;
  final String itemName;
  final String originalText;
  bool success;
  String message;

  VoiceCommandResult({
    required this.intent,
    required this.itemName,
    required this.originalText,
    this.success = false,
    this.message = '',
  });
}

class GroceryItem {
  final String id;
  final String name;
  final String originalCommand;
  final String addedBy;
  final DateTime? addedAt;
  final bool isCompleted;
  final String quantity;
  final String category;

  GroceryItem({
    required this.id,
    required this.name,
    required this.originalCommand,
    required this.addedBy,
    this.addedAt,
    required this.isCompleted,
    required this.quantity,
    required this.category,
  });

  factory GroceryItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GroceryItem(
      id: doc.id,
      name: data['name'] ?? '',
      originalCommand: data['originalCommand'] ?? '',
      addedBy: data['addedBy'] ?? 'manual',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate(),
      isCompleted: data['isCompleted'] ?? false,
      quantity: data['quantity'] ?? '1',
      category: data['category'] ?? 'other',
    );
  }
}
