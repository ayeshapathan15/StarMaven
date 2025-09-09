import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final InventoryProvider provider = context.watch<InventoryProvider>();
    final List<String> categories = provider.categoryToItems.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: const <Widget>[Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.add))],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final String category = categories[index];
          final int count = provider.itemCountInCategory(category);
          return _categoryTile(category, count);
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF34D399),
        onPressed: () {},
        child: const Icon(Icons.mic, color: Colors.white),
      ),
    );
  }

  Widget _categoryTile(String title, int count) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const <BoxShadow>[
          BoxShadow(blurRadius: 10, color: Color(0x11000000), offset: Offset(0, 4)),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.local_grocery_store),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$count item${count == 1 ? '' : 's'}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}


