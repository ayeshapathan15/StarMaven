import 'package:flutter/material.dart';

class SuggestionsScreen extends StatelessWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggestions', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text('Weekly Essentials', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ..._buildSuggestionRows(const <_Suggestion>[
            _Suggestion('Organic Milk', '1 Gallon'),
            _Suggestion('Eggs', '1 Dozen'),
            _Suggestion('Bread', 'Whole Wheat'),
          ]),
          const SizedBox(height: 16),
          const Text('Based on Last Purchase', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ..._buildSuggestionRows(const <_Suggestion>[
            _Suggestion('Avocados', '3 Pieces'),
            _Suggestion('Bananas', '1 Bunch'),
          ]),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF34D399),
        onPressed: () {},
        child: const Icon(Icons.mic, color: Colors.white),
      ),
    );
  }

  List<Widget> _buildSuggestionRows(List<_Suggestion> items) {
    return items
        .map(
          (e) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(e.subtitle, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Add')),
                    ],
                  ),
                ),
                Container(
                  width: 96,
                  height: 72,
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                )
              ],
            ),
          ),
        )
        .toList();
  }
}

class _Suggestion {
  final String title;
  final String subtitle;
  const _Suggestion(this.title, this.subtitle);
}


