import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';
import '../starred_messages_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await ApiService.getProfile();
      setState(() {
        _profile = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0084FF),
        foregroundColor: Colors.white,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    EditProfileScreen(profile: _profile ?? {}),
              ),
            ).then((_) => _loadProfile()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF0084FF)))
          : _profile == null
              ? const Center(child: Text('Profile load nahi hua!'))
              : ListView(
                  children: [
                    // Profile header
                    Container(
                      width: double.infinity,
                      color: const Color(0xFF0084FF),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfileScreen(
                                    profile: _profile ?? {}),
                              ),
                            ).then((_) => _loadProfile()),
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.white,
                                  backgroundImage:
                                      _profile!['avatar'] != null
                                          ? NetworkImage(
                                              'https://api.webzet.store${_profile!['avatar']}')
                                          : null,
                                  child: _profile!['avatar'] == null
                                      ? Text(
                                          _profile!['name'][0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                              fontSize: 40,
                                              color: Color(0xFF0084FF),
                                              fontWeight:
                                                  FontWeight.bold),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt,
                                        color: Color(0xFF0084FF),
                                        size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _profile!['name'],
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _profile!['phone'],
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _profile!['about'] ??
                                'Hey there! I am using NexChat',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Menu items
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.star,
                                color: Colors.amber),
                            title: const Text('Starred Messages'),
                            trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const StarredMessagesScreen()),
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.settings,
                                color: Color(0xFF0084FF)),
                            title: const Text('Settings'),
                            trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const SettingsScreen()),
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.logout,
                                color: Colors.red),
                            title: const Text('Logout',
                                style: TextStyle(color: Colors.red)),
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Logout karo?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _logout();
                                    },
                                    child: const Text('Logout',
                                        style: TextStyle(
                                            color: Colors.red)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // NexChat info
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.chat_bubble_rounded,
                              color: Color(0xFF0084FF), size: 32),
                          SizedBox(height: 8),
                          Text('NexChat v1.0.0',
                              style: TextStyle(color: Colors.grey)),
                          Text('Made with ❤️',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
    );
  }
}
