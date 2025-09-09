import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class MultiImageOCRParser {
  // Process image horizontally with proper text ordering
  static Future<String> processImageHorizontally(File imageFile) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await textRecognizer.processImage(inputImage);

    String combinedText = '';

    // Sort blocks by top-to-bottom position first
    List<TextBlock> sortedBlocks =
        recognizedText.blocks.toList()
          ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    for (TextBlock block in sortedBlocks) {
      // Sort lines within each block by top-to-bottom
      List<TextLine> sortedLines =
          block.lines.toList()
            ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

      for (TextLine line in sortedLines) {
        // Sort elements within each line by left-to-right
        List<TextElement> sortedElements =
            line.elements.toList()..sort(
              (a, b) => a.boundingBox.left.compareTo(b.boundingBox.left),
            );

        String lineText = '';
        for (TextElement element in sortedElements) {
          lineText += element.text + ' ';
        }
        combinedText += lineText.trim() + '\n';
      }
      combinedText += '\n'; // Add space between blocks
    }

    await textRecognizer.close();
    return combinedText;
  }

  static Map<String, dynamic> parseMultiImageData(String combinedText) {
    // Clean and normalize text
    String cleanText = _preprocessText(combinedText);

    // Smart extraction
    String productName = _extractProductName(cleanText);
    String brand = _extractBrand(cleanText);
    String quantity = _extractQuantity(cleanText);
    double price = _extractPrice(cleanText);
    double mrp = _extractMRP(cleanText) ?? price;
    String category = _determineCategory(cleanText);
    String type = _determineType(cleanText, category);
    String ingredients = _extractIngredients(cleanText);

    return {
      'productName': productName,
      'brand': brand,
      'type': type,
      'quantity': quantity,
      'price': price,
      'mrp': mrp,
      'category': category,
      'ingredients': ingredients.isNotEmpty ? ingredients : null,
    };
  }

  // Preprocess text to fix common OCR issues
  static String _preprocessText(String text) {
    String processed = text;

    // Remove image section headers
    processed = processed.replaceAll(
      RegExp(r'=== IMAGE \d+ \([^)]+\) ==='),
      '',
    );
    processed = processed.replaceAll(RegExp(r'=+'), '');

    // Normalize spaces and line breaks
    processed = processed.replaceAll(RegExp(r'\s+'), ' ');
    processed = processed.replaceAll(RegExp(r'\n+'), '\n');

    // Fix common OCR label-value separations
    Map<String, String> commonFixes = {
      r'net\s*weight\s*:?\s*(\d+\.?\d*)\s*([a-zA-Z]+)': 'net weight: \$1\$2',
      r'mrp\s*:?\s*₹?\s*(\d+\.?\d*)': 'mrp: ₹\$1',
      r'price\s*:?\s*₹?\s*(\d+\.?\d*)': 'price: ₹\$1',
      r'quantity\s*:?\s*(\d+\.?\d*)\s*([a-zA-Z]+)': 'quantity: \$1\$2',
    };

    for (var fix in commonFixes.entries) {
      processed = processed.replaceAllMapped(
        RegExp(fix.key, caseSensitive: false),
        (match) => fix.value.replaceAllMapped(
          RegExp(r'\$(\d+)'),
          (m) => match.group(int.parse(m.group(1)!)) ?? '',
        ),
      );
    }

    return processed.trim();
  }

  // Smart product name extraction
  static String _extractProductName(String text) {
    List<String> lines = text.split('\n');

    // Skip patterns that are NOT product names
    RegExp skipPatterns = RegExp(
      r'(net weight|weight|qty|quantity|mrp|price|rs|₹|ingredients|mfg|exp|best before|batch|manufactured|packed|date|\d+\s*(g|kg|ml|l|gm|ltr)|^\d+$)',
      caseSensitive: false,
    );

    String bestCandidate = 'Unknown Product';
    int bestScore = 0;

    for (String line in lines) {
      String trimmed = line.trim();

      // Skip short lines, number-only lines, or lines with skip patterns
      if (trimmed.length < 3 ||
          RegExp(r'^\d+\.?\d*$').hasMatch(trimmed) ||
          skipPatterns.hasMatch(trimmed)) {
        continue;
      }

      // Score potential product names
      int score = _scoreProductName(trimmed);

      if (score > bestScore) {
        bestScore = score;
        bestCandidate = trimmed;
      }
    }

    return bestCandidate;
  }

  static int _scoreProductName(String text) {
    int score = 0;
    List<String> words = text.split(' ');

    // Length scoring - product names are usually 2-6 words, 10-50 characters
    if (words.length >= 2 && words.length <= 6) score += 3;
    if (text.length >= 10 && text.length <= 50) score += 2;

    // Has uppercase letters (brand names often capitalized)
    if (RegExp(r'[A-Z]').hasMatch(text)) score += 2;

    // Doesn't start with number
    if (!RegExp(r'^\d').hasMatch(text)) score += 1;

    // Contains brand-like words
    if (RegExp(
      r'\b(premium|gold|fresh|pure|natural|special|extra|super)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      score += 1;
    }

    // Penalize if contains price/weight indicators
    if (RegExp(
      r'(₹|rs|kg|g|ml|l|price|mrp)',
      caseSensitive: false,
    ).hasMatch(text)) {
      score -= 3;
    }

    return score;
  }

  // Enhanced brand extraction
  static String _extractBrand(String text) {
    List<String> knownBrands = [
      'amul',
      'tata',
      'britannia',
      'parle',
      'nestle',
      'maggi',
      'fortune',
      'mother dairy',
      'aashirvaad',
      'pillsbury',
      'mdh',
      'everest',
      'red label',
      'brooke bond',
      'surf excel',
      'ariel',
      'tide',
      'vim',
      'dove',
      'lux',
      'pantene',
      'head shoulders',
      'colgate',
      'pepsodent',
      'close up',
      'oral b',
      'sensodyne',
      'patanjali',
      'dabur',
      'himalaya',
      'marico',
      'godrej',
      'wipro',
      'itc',
      'haldirams',
      'bikaji',
      'balaji',
      'lays',
      'kurkure',
      'bingo',
      'uncle chips',
      'saffola',
      'dhara',
      'sundrop',
      'gemini',
      'nandini',
      'catch',
      'kissan',
      'knorr',
      'lifebuoy',
      'fair lovely',
      'clinic plus',
      'dettol',
      'harpic',
      'hit',
      'good knight',
      'odomos',
      'mortein',
      'lizol',
      'colin',
      'domex',
    ];

    String lowerText = text.toLowerCase();

    // Look for exact brand matches with word boundaries
    for (String brand in knownBrands) {
      if (RegExp(r'\b' + RegExp.escape(brand) + r'\b').hasMatch(lowerText)) {
        return _capitalizeWords(brand);
      }
    }

    // If no known brand found, look for D-Mart house brands
    if (RegExp(
      r'\b(smart choice|d-?mart)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return 'D-Mart';
    }

    return 'Unknown Brand';
  }

  // Enhanced quantity extraction - focus on weight ending with g, kg, ml, l
  static String _extractQuantity(String text) {
    // Priority patterns - look for specific quantity indicators
    List<RegExp> quantityPatterns = [
      RegExp(
        r'net\s*wt\.?\s*:?\s*(\d+\.?\d*)\s*(g|kg|ml|l|gm|ltr|litre|gram)',
        caseSensitive: false,
      ),
      RegExp(
        r'net\s*weight\s*:?\s*(\d+\.?\d*)\s*(g|kg|ml|l|gm|ltr)',
        caseSensitive: false,
      ),
      RegExp(
        r'weight\s*:?\s*(\d+\.?\d*)\s*(g|kg|ml|l|gm|ltr)',
        caseSensitive: false,
      ),
      RegExp(
        r'qty\s*:?\s*(\d+\.?\d*)\s*(g|kg|ml|l|gm|ltr)',
        caseSensitive: false,
      ),
      RegExp(
        r'quantity\s*:?\s*(\d+\.?\d*)\s*(g|kg|ml|l|gm|ltr)',
        caseSensitive: false,
      ),
      RegExp(r'(\d+)\s*(g|kg|ml|l|gm|ltr|litre|gram)\b', caseSensitive: false),
    ];

    for (RegExp pattern in quantityPatterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        String quantity = match.group(1)!;
        String unit = match.group(2)!.toLowerCase();

        // Normalize units
        switch (unit) {
          case 'gm':
          case 'gram':
            unit = 'g';
            break;
          case 'ltr':
          case 'litre':
            unit = 'l';
            break;
        }

        // Return first valid quantity found
        return '$quantity$unit';
      }
    }

    return 'Unknown Quantity';
  }

  // Enhanced price extraction - look for ₹ symbol and .00 endings
  static double _extractPrice(String text) {
    // Priority patterns for price detection
    List<RegExp> pricePatterns = [
      RegExp(r'price\s*:?\s*₹\s*(\d+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'₹\s*(\d+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'rs\.?\s*(\d+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'inr\s*(\d+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'\b(\d+\.\d{2})\b'), // Numbers ending with .00, .50, etc.
    ];

    for (RegExp pattern in pricePatterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        double? price = double.tryParse(match.group(1)!);
        if (price != null && price > 0 && price < 10000) {
          // Reasonable price range
          return price;
        }
      }
    }

    return 0;
  }

  // Extract MRP specifically
  static double? _extractMRP(String text) {
    RegExp mrpPattern = RegExp(
      r'mrp\s*:?\s*₹?\s*(\d+(?:\.\d{2})?)',
      caseSensitive: false,
    );
    Match? match = mrpPattern.firstMatch(text);

    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  // Smart category determination
  static String _determineCategory(String text) {
    String lowerText = text.toLowerCase();

    Map<String, List<String>> categoryKeywords = {
      'oils': [
        'oil',
        'ghee',
        'butter',
        'margarine',
        'coconut oil',
        'mustard oil',
        'sunflower oil',
        'refined oil',
      ],
      'dairy': [
        'milk',
        'curd',
        'yogurt',
        'yoghurt',
        'cheese',
        'paneer',
        'lassi',
        'butter milk',
        'dairy',
      ],
      'rice': [
        'rice',
        'basmati',
        'jasmine rice',
        'brown rice',
        'atta',
        'flour',
        'maida',
        'rava',
        'sooji',
        'grain',
      ],
      'spices': [
        'masala',
        'spice',
        'turmeric',
        'haldi',
        'chili',
        'mirchi',
        'jeera',
        'dhania',
        'garam masala',
        'salt',
        'pepper',
      ],
      'pulses': [
        'dal',
        'lentil',
        'toor',
        'moong',
        'chana',
        'rajma',
        'urad',
        'masoor',
        'pulse',
        'gram',
      ],
      'snacks': [
        'biscuit',
        'cookie',
        'chips',
        'namkeen',
        'mixture',
        'bhujia',
        'snack',
        'wafer',
      ],
      'beverages': [
        'tea',
        'coffee',
        'juice',
        'drink',
        'cola',
        'pepsi',
        'coke',
        'beverage',
        'water',
      ],
      'personal_care': [
        'soap',
        'shampoo',
        'toothpaste',
        'cream',
        'lotion',
        'powder',
        'care',
        'detergent',
      ],
      'household': [
        'detergent',
        'cleaner',
        'dishwash',
        'toilet',
        'tissue',
        'napkin',
        'washing powder',
      ],
    };

    int maxMatches = 0;
    String bestCategory = 'others';

    for (var categoryEntry in categoryKeywords.entries) {
      int matches = 0;
      for (String keyword in categoryEntry.value) {
        if (RegExp(
          r'\b' + RegExp.escape(keyword) + r'\b',
        ).hasMatch(lowerText)) {
          matches++;
        }
      }
      if (matches > maxMatches) {
        maxMatches = matches;
        bestCategory = categoryEntry.key;
      }
    }

    return bestCategory;
  }

  // Smart type determination based on category
  static String _determineType(String text, String category) {
    String lowerText = text.toLowerCase();

    switch (category) {
      case 'oils':
        if (lowerText.contains('sunflower')) return 'Sunflower Oil';
        if (lowerText.contains('mustard')) return 'Mustard Oil';
        if (lowerText.contains('coconut')) return 'Coconut Oil';
        if (lowerText.contains('groundnut') || lowerText.contains('peanut'))
          return 'Groundnut Oil';
        if (lowerText.contains('soybean') || lowerText.contains('soya'))
          return 'Soybean Oil';
        if (lowerText.contains('ghee')) return 'Ghee';
        return 'Cooking Oil';

      case 'dairy':
        if (lowerText.contains('full cream')) return 'Full Cream Milk';
        if (lowerText.contains('toned')) return 'Toned Milk';
        if (lowerText.contains('skimmed')) return 'Skimmed Milk';
        if (lowerText.contains('paneer')) return 'Paneer';
        if (lowerText.contains('curd') || lowerText.contains('yogurt'))
          return 'Curd';
        if (lowerText.contains('milk')) return 'Milk';
        return 'Dairy Product';

      case 'spices':
        if (lowerText.contains('turmeric') || lowerText.contains('haldi'))
          return 'Turmeric Powder';
        if (lowerText.contains('chili') || lowerText.contains('mirchi'))
          return 'Chili Powder';
        if (lowerText.contains('garam masala')) return 'Garam Masala';
        if (lowerText.contains('salt')) return 'Salt';
        return 'Spice Powder';

      case 'rice':
        if (lowerText.contains('basmati')) return 'Basmati Rice';
        if (lowerText.contains('brown rice')) return 'Brown Rice';
        if (lowerText.contains('atta')) return 'Wheat Flour';
        if (lowerText.contains('rice')) return 'Rice';
        return 'Grain Product';

      default:
        return _capitalizeWords(category.replaceAll('_', ' '));
    }
  }

  // Extract ingredients if available
  static String _extractIngredients(String text) {
    String lowerText = text.toLowerCase();

    if (lowerText.contains('ingredients')) {
      RegExp ingredientsPattern = RegExp(
        r'ingredients\s*:?\s*([^.]*(?:\.[^.]*){0,3})',
        caseSensitive: false,
        multiLine: true,
      );

      Match? match = ingredientsPattern.firstMatch(text);
      if (match != null) {
        String ingredients = match.group(1)!.trim();
        ingredients = ingredients.replaceAll(RegExp(r'\s+'), ' ');

        // Limit length for display
        if (ingredients.length > 200) {
          ingredients = ingredients.substring(0, 200) + '...';
        }

        return ingredients.isNotEmpty ? ingredients : '';
      }
    }
    return '';
  }

  // Helper method to capitalize words
  static String _capitalizeWords(String text) {
    return text
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : word,
        )
        .join(' ');
  }
}
