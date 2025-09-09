import 'package:flutter/foundation.dart';
import '../models/grocery_item.dart';

class InventoryProvider extends ChangeNotifier {
  final Map<String, List<GroceryItem>> _categoryToItems = <String, List<GroceryItem>>{
    'Produce': <GroceryItem>[],
    'Dairy & Eggs': <GroceryItem>[],
    'Meat & Seafood': <GroceryItem>[],
    'Pantry': <GroceryItem>[],
    'Frozen': <GroceryItem>[],
    'Beverages': <GroceryItem>[],
  };

  Map<String, List<GroceryItem>> get categoryToItems => _categoryToItems;

  List<GroceryItem> allItems() {
    return _categoryToItems.values.expand((List<GroceryItem> e) => e).toList(growable: false);
  }

  void addItem(GroceryItem item) {
    final List<GroceryItem>? items = _categoryToItems[item.category];
    if (items != null) {
      items.add(item);
      notifyListeners();
    }
  }

  void addItems(List<GroceryItem> items) {
    for (final GroceryItem item in items) {
      addItem(item);
    }
  }

  int itemCountInCategory(String category) => _categoryToItems[category]?.length ?? 0;
}


