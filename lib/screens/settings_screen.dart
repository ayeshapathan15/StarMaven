import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = 'English';
  bool _notifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text('Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: _language,
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(value: 'English', child: Text('English')),
                DropdownMenuItem<String>(value: 'Spanish', child: Text('Spanish')),
              ],
              onChanged: (String? v) => setState(() => _language = v ?? 'English'),
            ),
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            value: _notifications,
            onChanged: (bool v) => setState(() => _notifications = v),
          ),
          const SizedBox(height: 8),
          const Text('Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const ListTile(title: Text('Link Account'), trailing: Icon(Icons.chevron_right)),
          const ListTile(title: Text('Sync Data'), trailing: Icon(Icons.chevron_right)),
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
}


