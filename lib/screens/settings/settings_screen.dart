import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../starred_messages_screen.dart';
import '../../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _appLock = false;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _appLock = prefs.getBool('appLock') ?? false;
      _notifications = prefs.getBool('notifications') ?? true;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    setState(() => _darkMode = value);
    // Apply theme immediately
    NexChatApp.of(context)?.toggleTheme(value);
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    setState(() => _notifications = value);
  }

  Future<void> _setAppLock() async {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('App Lock PIN set karo'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '4 digit PIN',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.length == 4) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('appLock', true);
                await prefs.setString('appLockPin', pinController.text);
                setState(() => _appLock = true);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('App Lock set ho gaya! 🔒')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0084FF),
                foregroundColor: Colors.white),
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeAppLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('appLock', false);
    await prefs.remove('appLockPin');
    setState(() => _appLock = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App Lock remove ho gaya!')),
      );
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout karo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0084FF),
        foregroundColor: Colors.white,
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Notifications
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('NOTIFICATIONS',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications,
                color: Color(0xFF0084FF)),
            title: const Text('Notifications'),
            subtitle: const Text('Message notifications'),
            value: _notifications,
            onChanged: _toggleNotifications,
            activeColor: const Color(0xFF0084FF),
          ),
          const Divider(),

          // Appearance
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('APPEARANCE',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode,
                color: Color(0xFF0084FF)),
            title: const Text('Dark Mode'),
            subtitle: const Text('Dark theme enable karo'),
            value: _darkMode,
            onChanged: _toggleDarkMode,
            activeColor: const Color(0xFF0084FF),
          ),
          const Divider(),

          // Privacy
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('PRIVACY',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.lock, color: Color(0xFF0084FF)),
            title: const Text('App Lock'),
            subtitle: Text(_appLock ? 'PIN set hai 🔒' : 'PIN set nahi hai'),
            trailing: Switch(
              value: _appLock,
              onChanged: (value) =>
                  value ? _setAppLock() : _removeAppLock(),
              activeColor: const Color(0xFF0084FF),
            ),
          ),
          const Divider(),

          // Starred messages
          ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: const Text('Starred Messages'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const StarredMessagesScreen()),
            ),
          ),
          const Divider(),

          // About
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('ABOUT',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          const ListTile(
            leading: Icon(Icons.info, color: Color(0xFF0084FF)),
            title: Text('Version'),
            subtitle: Text('NexChat v1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.auto_awesome, color: Color(0xFF0084FF)),
            title: Text('Nex AI'),
            subtitle: Text('Powered by Llama 3.3 70B'),
          ),
          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout',
                style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
