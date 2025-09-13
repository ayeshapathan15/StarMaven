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
      RegExp(r'insert\s+(.+?)(?:\s+in\s+(?:the\s+)?list)?', caseSensitive: false),
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
    'ADD_KANNADA': [
      RegExp(r'(.+?)\s+(?:add\s+maadi|haaki|beku)', caseSensitive: false),
      RegExp(r'nanage\s+(.+?)\s+beku', caseSensitive: false),
      RegExp(r'(.+?)\s+list\s+alli\s+haaki', caseSensitive: false),
    ],
    'ADD_TAMIL': [
      RegExp(r'(.+?)\s+(?:add\s+pannu|podu|venum)', caseSensitive: false),
      RegExp(r'enakku\s+(.+?)\s+venum', caseSensitive: false),
      RegExp(r'(.+?)\s+list\s+la\s+podu', caseSensitive: false),
    ],
    'ADD_TELUGU': [
      RegExp(r'(.+?)\s+(?:add\s+cheyyi|petti|kavali)', caseSensitive: false),
      RegExp(r'naaku\s+(.+?)\s+kavali', caseSensitive: false),
      RegExp(r'(.+?)\s+list\s+lo\s+petti', caseSensitive: false),
    ],
    'ADD_BENGALI': [
      RegExp(r'(.+?)\s+(?:add\s+koro|dao|lagbe)', caseSensitive: false),
      RegExp(r'amar\s+(.+?)\s+lagbe', caseSensitive: false),
      RegExp(r'(.+?)\s+list\s+e\s+dao', caseSensitive: false),
    ],
    'ADD_GUJARATI': [
      RegExp(r'(.+?)\s+(?:add\s+karo|nakho|joiye)', caseSensitive: false),
      RegExp(r'mane\s+(.+?)\s+joiye', caseSensitive: false),
      RegExp(r'(.+?)\s+list\s+ma\s+nakho', caseSensitive: false),
    ],
  };

  // Multilingual grocery item dictionary
  static final Map<String, Map<String, dynamic>> _groceryItems = {
    'sugar': {
      'english': ['sugar', 'white sugar', 'brown sugar'],
      'hindi': ['चीनी', 'शक्कर', 'शकर', 'cheeni', 'shakkar'],
      'marathi': ['साखर', 'sakhar'],
      'kannada': ['ಸಕ್ಕರೆ', 'ಚೀನಿ', 'sakkare', 'cheeni'],
      'tamil': ['சர்க்கரை', 'வெள்ளை சர்க்கரை', 'sarkarai'],
      'telugu': ['పండి', 'సక్కర', 'pandi', 'sakkara'],
      'bengali': ['চিনি', 'খাঁড', 'chini', 'khand'],
      'gujarati': ['સક્કર', 'ખાંડ', 'sakkar', 'khand'],
      'category': 'sweeteners',
    },
    'milk': {
      'english': ['milk', 'dairy milk'],
      'hindi': ['दूध', 'दुग्ध', 'dudh', 'doodh'],
      'marathi': ['दूध', 'dudh'],
      'kannada': ['ಹಾಲು', 'haalu'],
      'tamil': ['பால்', 'paal'],
      'telugu': ['పాలు', 'paalu'],
      'bengali': ['দুধ', 'dudh'],
      'gujarati': ['દૂધ', 'dudh'],
      'category': 'dairy',
    },
    'rice': {
      'english': ['rice', 'basmati rice'],
      'hindi': ['चावल', 'भात', 'chawal', 'bhat'],
      'marathi': ['तांदूळ', 'भात', 'tandool', 'bhat'],
      'kannada': ['ಅಕ್ಕಿ', 'ಅನ್ನ', 'akki', 'anna'],
      'tamil': ['அரிசி', 'சோறு', 'arisi', 'choru'],
      'telugu': ['అరిసి', 'అన్నం', 'arisi', 'annam'],
      'bengali': ['চাল', 'ভাত', 'chal', 'bhat'],
      'gujarati': ['ચોખા', 'ભાત', 'chokha', 'bhat'],
      'category': 'grains',
    },
    'oil': {
      'english': ['oil', 'cooking oil', 'sunflower oil'],
      'hindi': ['तेल', 'खाना पकाने का तेल', 'tel'],
      'marathi': ['तेल', 'tel'],
      'kannada': ['ಎಣ್ಣೆ', 'enne'],
      'tamil': ['எண்ணெய்', 'ennai'],
      'telugu': ['నునె', 'nune'],
      'bengali': ['তেল', 'tel'],
      'gujarati': ['તેલ', 'tel'],
      'category': 'cooking',
    },
    'salt': {
      'english': ['salt', 'table salt'],
      'hindi': ['नमक', 'namak'],
      'marathi': ['मीठ', 'mith'],
      'kannada': ['ಉಪ್ಪು', 'uppu'],
      'tamil': ['உப்பு', 'uppu'],
      'telugu': ['ఉప్పు', 'uppu'],
      'bengali': ['লবণ', 'lobon'],
      'gujarati': ['મીઠું', 'mithun'],
      'category': 'spices',
    },
    'bread': {
      'english': ['bread', 'white bread', 'brown bread'],
      'hindi': ['ब्रेड', 'रोटी', 'bread', 'roti'],
      'marathi': ['पाव', 'ब्रेड', 'pav', 'bread'],
      'kannada': ['ರೋಟಿ', 'ಬ್ರೆಡ್', 'roti', 'bread'],
      'tamil': ['ரோட்டி', 'புரெட்', 'rotti', 'bread'],
      'telugu': ['రొట్టి', 'బ్రెడ్', 'rotti', 'bread'],
      'bengali': ['রুটি', 'ব্রেড', 'ruti', 'bread'],
      'gujarati': ['રોટલી', 'બ્રેડ', 'rotli', 'bread'],
      'category': 'bakery',
    },
    'flour': {
      'english': ['flour', 'wheat flour', 'all purpose flour'],
      'hindi': ['आटा', 'गेहूं का आटा', 'atta', 'maida'],
      'marathi': ['पीठ', 'गहू पीठ', 'peeth'],
      'kannada': ['ಹಿಟ್ಟು', 'ಗೋಧಿ ಹಿಟ್ಟು', 'hittu'],
      'tamil': ['மாவு', 'கோதுமை மாவு', 'maavu'],
      'telugu': ['పిండి', 'గోధుమ పిండి', 'pindi'],
      'bengali': ['আটা', 'গমের আটা', 'atta'],
      'gujarati': ['લોટ', 'ગહુંનું લોટ', 'lot'],
      'category': 'grains',
    },
    'onion': {
      'english': ['onion', 'onions', 'red onion'],
      'hindi': ['प्याज', 'pyaj', 'pyaaz'],
      'marathi': ['कांदा', 'kanda'],
      'kannada': ['ಈರುಳ್ಳಿ', 'eerulli'],
      'tamil': ['வெங்காயம்', 'vengayam'],
      'telugu': ['ఉల్లిపాయ', 'ullipaya'],
      'bengali': ['পেঁয়াজ', 'peyaj'],
      'gujarati': ['ડુંગળી', 'dungali'],
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

      // Check if it's a question first
      VoiceCommandResult? questionResult = _handleQuestion(cleanText, voiceText);
      if (questionResult != null) {
        return questionResult;
      }

      // Extract intent and item name for grocery commands
      VoiceCommandResult result = _extractIntentAndItem(cleanText, voiceText);

      if (result.intent == 'ADD_ITEM' && result.itemName.isNotEmpty) {
        // Add item to user's grocery list
        await _addToGroceryList(user.uid, result.itemName, voiceText);
        result.success = true;
        result.message = 'Added "${result.itemName}" to your grocery list!';
      } else {
        // Handle as general conversation
        return _handleGeneralConversation(cleanText, voiceText);
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
          
          // First try to find known grocery item
          String? normalizedItem = _findGroceryItem(itemText);
          
          if (normalizedItem != null) {
            return VoiceCommandResult(
              intent: 'ADD_ITEM',
              itemName: normalizedItem,
              originalText: originalText,
              success: false,
              message: '',
            );
          } else {
            // If not found in predefined list, add the item as-is (dynamic)
            String dynamicItemName = _capitalizeFirst(itemText);
            return VoiceCommandResult(
              intent: 'ADD_ITEM',
              itemName: dynamicItemName,
              originalText: originalText,
              success: false,
              message: '',
            );
          }
        }
      }
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
      for (String langKey in ['english', 'hindi', 'marathi', 'kannada', 'tamil', 'telugu', 'bengali', 'gujarati']) {
        if (itemData.containsKey(langKey)) {
          List<String> variants = List<String>.from(itemData[langKey]);
          for (String variant in variants) {
            if (text.contains(variant.toLowerCase())) {
              return itemKey; // Return the normalized English name
            }
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
      // Add new item with dynamic category detection
      String category = _detectCategory(itemName);
      
      await groceryList.add({
        'name': itemName,
        'originalCommand': originalCommand,
        'addedBy': 'voice',
        'addedAt': FieldValue.serverTimestamp(),
        'isCompleted': false,
        'quantity': '1',
        'category': category,
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

  /// Capitalize first letter of item name
  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  /// Detect category for any item
  static String _detectCategory(String itemName) {
    String lowerName = itemName.toLowerCase();
    
    // Check if it's a known item first
    for (String itemKey in _groceryItems.keys) {
      if (_groceryItems[itemKey]!.containsKey('category')) {
        for (String langKey in ['english', 'hindi', 'marathi', 'kannada', 'tamil', 'telugu', 'bengali', 'gujarati']) {
          if (_groceryItems[itemKey]!.containsKey(langKey)) {
            List<String> variants = List<String>.from(_groceryItems[itemKey]![langKey]);
            for (String variant in variants) {
              if (lowerName.contains(variant.toLowerCase())) {
                return _groceryItems[itemKey]!['category'];
              }
            }
          }
        }
      }
    }
    
    // Dynamic category detection based on common patterns
    if (lowerName.contains('chocolate') || lowerName.contains('candy') || lowerName.contains('sweet')) {
      return 'sweets';
    } else if (lowerName.contains('fruit') || lowerName.contains('apple') || lowerName.contains('banana')) {
      return 'fruits';
    } else if (lowerName.contains('vegetable') || lowerName.contains('tomato') || lowerName.contains('potato')) {
      return 'vegetables';
    } else if (lowerName.contains('meat') || lowerName.contains('chicken') || lowerName.contains('fish')) {
      return 'meat';
    } else if (lowerName.contains('drink') || lowerName.contains('juice') || lowerName.contains('water')) {
      return 'beverages';
    } else {
      return 'other';
    }
  }

  /// Handle questions and provide quick responses
  static VoiceCommandResult? _handleQuestion(String cleanText, String originalText) {
    // Time-related questions
    if (cleanText.contains('time') || cleanText.contains('what time')) {
      String currentTime = DateTime.now().toString().substring(11, 16);
      return VoiceCommandResult(
        intent: 'QUESTION',
        itemName: '',
        originalText: originalText,
        success: true,
        message: 'The current time is $currentTime',
      );
    }
    
    // Date-related questions
    if (cleanText.contains('date') || cleanText.contains('what day')) {
      String currentDate = DateTime.now().toString().substring(0, 10);
      return VoiceCommandResult(
        intent: 'QUESTION',
        itemName: '',
        originalText: originalText,
        success: true,
        message: 'Today is $currentDate',
      );
    }
    
    // Weather questions (mock response)
    if (cleanText.contains('weather') || cleanText.contains('temperature')) {
      return VoiceCommandResult(
        intent: 'QUESTION',
        itemName: '',
        originalText: originalText,
        success: true,
        message: 'I can\'t check weather right now, but you can check your weather app!',
      );
    }
    
    // App-related questions
    if (cleanText.contains('how are you') || cleanText.contains('hello') || cleanText.contains('hi')) {
      return VoiceCommandResult(
        intent: 'GREETING',
        itemName: '',
        originalText: originalText,
        success: true,
        message: 'Hello! I\'m your grocery assistant. I can help you add items to your list!',
      );
    }
    
    return null;
  }
  
  /// Handle general conversation
  static VoiceCommandResult _handleGeneralConversation(String cleanText, String originalText) {
    // Math questions
    if (cleanText.contains('plus') || cleanText.contains('add') && cleanText.contains('and')) {
      return VoiceCommandResult(
        intent: 'MATH',
        itemName: '',
        originalText: originalText,
        success: true,
        message: 'I can help with simple questions, but I\'m best at managing your grocery list!',
      );
    }
    
    // Default helpful response
    List<String> helpfulResponses = [
      'I\'m your grocery assistant! Try saying "add milk" or "add chocolate".',
      'I can help you add items to your grocery list. What would you like to add?',
      'I\'m here to help with your shopping list. Just say "add" followed by any item!',
      'I can answer simple questions and help manage your grocery list!',
    ];
    
    String randomResponse = helpfulResponses[DateTime.now().millisecond % helpfulResponses.length];
    
    return VoiceCommandResult(
      intent: 'CONVERSATION',
      itemName: '',
      originalText: originalText,
      success: true,
      message: randomResponse,
    );
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
