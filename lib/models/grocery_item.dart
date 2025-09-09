class GroceryItem {
  final String name;
  final int quantity;
  final double price;
  final String category;

  const GroceryItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.category,
  });

  GroceryItem copyWith({
    String? name,
    int? quantity,
    double? price,
    String? category,
  }) {
    return GroceryItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      category: category ?? this.category,
    );
  }

  @override
  String toString() {
    return 'GroceryItem(name: ' + name + ', qty: ' + quantity.toString() + ', price: ' + price.toString() + ', category: ' + category + ')';
  }
}


