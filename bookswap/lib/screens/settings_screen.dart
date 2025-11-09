import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationReminders = true;
  bool _emailUpdates = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Profile section
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(authProvider.user?.name ?? 'User'),
              subtitle: Text(authProvider.user?.email ?? ''),
            ),
          ),
          const SizedBox(height: 16),
          // Settings options
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Notification reminders'),
                  value: _notificationReminders,
                  onChanged: (value) {
                    setState(() {
                      _notificationReminders = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Email Updates'),
                  value: _emailUpdates,
                  onChanged: (value) {
                    setState(() {
                      _emailUpdates = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // About section
          Card(
            child: ListTile(
              title: const Text('About'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('About BookSwap'),
                    content: const Text(
                      'BookSwap is a marketplace for students to exchange textbooks. '
                      'Version 1.0.0\n\n'
                      'Connect with other students and swap your books easily!',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CLOSE'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Logout button
          Card(
            child: ListTile(
              title: const Center(
                child: Text('Log Out', style: TextStyle(color: Colors.red)),
              ),
              onTap: () {
                authProvider.signOut();
              },
            ),
          ),
        ],
      ),
    );
  }
}
