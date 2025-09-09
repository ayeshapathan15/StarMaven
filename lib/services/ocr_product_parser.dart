class OCRProductParser {
  static Map<String, dynamic> parseProductData(String text) {
    String productName = 'Unknown Product';
    String brand = 'Unknown Brand';
    String type = 'Unknown Type';
    String quantity = '1 unit';
    double price = 0;
    double mrp = 0;
    String category = 'others';

    // Convert to lowercase for easier parsing
    String lowerText = text.toLowerCase();
    List<String> lines = text.split('\n');

    // Parse Price (₹, Rs, INR patterns)
    RegExp priceRegex = RegExp(
      r'(?:₹|rs\.?|inr)\s*(\d+(?:\.\d{2})?)',
      caseSensitive: false,
    );
    Iterable<RegExpMatch> priceMatches = priceRegex.allMatches(text);

    if (priceMatches.isNotEmpty) {
      price = double.tryParse(priceMatches.first.group(1)!) ?? 0;
      mrp = price + (price * 0.15); // Assume 15% markup
    }

    // Parse Quantity (ml, kg, g, L patterns)
    RegExp quantityRegex = RegExp(
      r'(\d+(?:\.\d+)?)\s*(ml|kg|g|l|ltr|litre)',
      caseSensitive: false,
    );
    Iterable<RegExpMatch> quantityMatches = quantityRegex.allMatches(text);

    if (quantityMatches.isNotEmpty) {
      quantity =
          '${quantityMatches.first.group(1)}${quantityMatches.first.group(2)!.toLowerCase()}';
    }

    // Parse Brand (common brands)
    List<String> knownBrands = [
      'amul',
      'tata',
      'britannia',
      'parle',
      'nestle',
      'maggi',
      'fortune',
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
    ];

    for (String brandName in knownBrands) {
      if (lowerText.contains(brandName)) {
        brand = _capitalizeFirst(brandName);
        break;
      }
    }

    // Parse Product Name (first substantial line that's not a brand)
    for (String line in lines) {
      String cleanLine = line.trim();
      if (cleanLine.length > 3 &&
          !cleanLine.toLowerCase().contains(brand.toLowerCase()) &&
          !priceRegex.hasMatch(cleanLine) &&
          !quantityRegex.hasMatch(cleanLine)) {
        productName = cleanLine;
        break;
      }
    }

    // Parse Category based on keywords
    Map<String, List<String>> categoryKeywords = {
      'oils': ['oil', 'ghee', 'butter', 'margarine'],
      'dairy': ['milk', 'curd', 'yogurt', 'cheese', 'paneer', 'lassi'],
      'rice': ['rice', 'basmati', 'atta', 'flour', 'maida', 'rava', 'sooji'],
      'spices': [
        'masala',
        'spice',
        'turmeric',
        'haldi',
        'chili',
        'mirchi',
        'jeera',
        'dhania',
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
      ],
      'snacks': ['biscuit', 'cookie', 'chips', 'namkeen', 'mixture', 'bhujia'],
      'beverages': ['tea', 'coffee', 'juice', 'drink', 'cola', 'pepsi', 'coke'],
      'personal_care': [
        'soap',
        'shampoo',
        'toothpaste',
        'cream',
        'lotion',
        'powder',
      ],
      'household': [
        'detergent',
        'cleaner',
        'dishwash',
        'toilet',
        'tissue',
        'napkin',
      ],
    };

    for (var categoryEntry in categoryKeywords.entries) {
      for (String keyword in categoryEntry.value) {
        if (lowerText.contains(keyword)) {
          category = categoryEntry.key;
          type = _capitalizeFirst(keyword);
          break;
        }
      }
      if (category != 'others') break;
    }

    // If product name is still unknown, try to construct from available data
    if (productName == 'Unknown Product' &&
        brand != 'Unknown Brand' &&
        type != 'Unknown Type') {
      productName = '$brand $type $quantity';
    }

    return {
      'productName': productName,
      'brand': brand,
      'type': type,
      'quantity': quantity,
      'price': price,
      'mrp': mrp,
      'category': category,
    };
  }

  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
