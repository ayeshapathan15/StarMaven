import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/tts_service.dart';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Grocery List',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text(
              'All Items',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2C3E50),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear_all':
                  _showClearAllDialog();
                  break;
                case 'speak_list':
                  _speakGroceryList();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'speak_list',
                    child: Row(
                      children: [
                        Icon(Icons.volume_up, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Read My List'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Clear All Items'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Loading Indicator
          if (_isLoading) const LinearProgressIndicator(),

          // Grocery List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getGroceryListStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: _refreshList,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      return _buildGroceryItemCard(snapshot.data!.docs[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Summary Bottom Sheet
      bottomSheet: StreamBuilder<QuerySnapshot>(
        stream: _getGroceryListStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const SizedBox.shrink();
          }

          return _buildSummaryBar(snapshot.data!.docs);
        },
      ),
    );
  }

  Widget _buildGroceryItemCard(QueryDocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isCompleted = data['isCompleted'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Dismissible(
        key: Key(doc.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Colors.red,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          return await _showDeleteConfirmDialog();
        },
        onDismissed: (direction) {
          _deleteGroceryItem(doc.id);
        },
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: GestureDetector(
            onTap: () => _toggleCompletion(doc.id, !isCompleted),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? Colors.green : Colors.grey,
                  width: 2,
                ),
                color: isCompleted ? Colors.green : Colors.transparent,
              ),
              child:
                  isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
            ),
          ),
          title: Text(
            data['productName'] ?? 'Unknown Product',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? Colors.grey[600] : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.business, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    data['brand'] ?? 'Unknown Brand',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.category, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    data['type'] ?? 'Unknown Type',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.scale, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    data['quantity'] ?? 'Unknown Quantity',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(data['addedAt']),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${data['price'] ?? 0}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              if (data['mrp'] != null && data['mrp'] > (data['price'] ?? 0))
                Text(
                  '₹${data['mrp']}',
                  style: TextStyle(
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
          onTap: () => _showItemDetails(data),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 120,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Your grocery list is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Use the Voice Assistant to add items\nby saying "add milk" or "tel add kara"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate back to voice screen
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.mic),
              label: const Text('Add Items with Voice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C3E50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar(List<QueryDocumentSnapshot> docs) {
    int totalItems = docs.length;
    int completedItems =
        docs.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return data['isCompleted'] ?? false;
        }).length;

    double totalPrice = docs.fold(0.0, (sum, doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return sum + ((data['price'] ?? 0).toDouble());
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Items: $totalItems',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Completed: $completedItems',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total: ₹${totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              if (totalItems > 0)
                Text(
                  '${((completedItems / totalItems) * 100).toStringAsFixed(0)}% Complete',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getGroceryListStream() {
    if (_user == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('grocery_list')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  Future<void> _toggleCompletion(String docId, bool isCompleted) async {
    try {
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('grocery_list')
          .doc(docId)
          .update({'isCompleted': isCompleted});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCompleted
                ? 'Item marked as completed!'
                : 'Item marked as pending!',
          ),
          backgroundColor: isCompleted ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteGroceryItem(String docId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('grocery_list')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item deleted successfully!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showClearAllDialog() async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Items'),
            content: const Text(
              'Are you sure you want to delete all grocery items? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearAllItems();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _clearAllItems() async {
    try {
      setState(() {
        _isLoading = true;
      });

      QuerySnapshot allItems =
          await _firestore
              .collection('users')
              .doc(_user!.uid)
              .collection('grocery_list')
              .get();

      WriteBatch batch = _firestore.batch();
      for (QueryDocumentSnapshot doc in allItems.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All items cleared successfully!'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool?> _showDeleteConfirmDialog() async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Item'),
            content: const Text('Are you sure you want to delete this item?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showItemDetails(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.8,
            minChildSize: 0.4,
            expand: false,
            builder:
                (context, scrollController) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        data['productName'] ?? 'Unknown Product',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDetailRow(
                        'Brand',
                        data['brand'] ?? 'Unknown',
                        Icons.business,
                      ),
                      _buildDetailRow(
                        'Type',
                        data['type'] ?? 'Unknown',
                        Icons.category,
                      ),
                      _buildDetailRow(
                        'Quantity',
                        data['quantity'] ?? 'Unknown',
                        Icons.scale,
                      ),
                      _buildDetailRow(
                        'Category',
                        data['category'] ?? 'Unknown',
                        Icons.apps,
                      ),
                      _buildDetailRow(
                        'Price',
                        '₹${data['price'] ?? 0}',
                        Icons.currency_rupee,
                      ),
                      if (data['mrp'] != null)
                        _buildDetailRow(
                          'MRP',
                          '₹${data['mrp']}',
                          Icons.local_offer,
                        ),
                      _buildDetailRow(
                        'Added By',
                        data['addedBy'] ?? 'Unknown',
                        Icons.person,
                      ),
                      _buildDetailRow(
                        'Added At',
                        _formatTimestamp(data['addedAt']),
                        Icons.access_time,
                      ),
                      _buildDetailRow(
                        'Status',
                        (data['isCompleted'] ?? false)
                            ? 'Completed ✓'
                            : 'Pending',
                        Icons.check_circle,
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _speakGroceryList() async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('users')
              .doc(_user!.uid)
              .collection('grocery_list')
              .get();

      if (snapshot.docs.isEmpty) {
        await TTSService.speak('Your grocery list is empty', 'english');
        return;
      }

      List<String> items = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String status =
            (data['isCompleted'] ?? false) ? 'completed' : 'pending';
        items.add('${data['productName']}, $status');
      }

      String listText =
          'Your grocery list contains ${items.length} items. ${items.join('. ')}';
      await TTSService.speak(listText, 'english');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reading list: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshList() async {
    // Refresh is handled automatically by StreamBuilder
    await Future.delayed(const Duration(seconds: 1));
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      DateTime dateTime = timestamp.toDate();
      DateTime now = DateTime.now();

      if (now.difference(dateTime).inDays == 0) {
        return 'Today ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (now.difference(dateTime).inDays == 1) {
        return 'Yesterday';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
