import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'register_screen.dart';

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
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A884),
        foregroundColor: Colors.white,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Logout karo?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _logout();
                    },
                    child: const Text('Logout', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A884)))
          : _profile == null
              ? const Center(child: Text('Profile load nahi hua!'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFF00A884),
                        backgroundImage: _profile!['avatar'] != null
                            ? NetworkImage('https://api.webzet.store${_profile!['avatar']}')
                            : null,
                        child: _profile!['avatar'] == null
                            ? Text(
                                _profile!['name'][0].toUpperCase(),
                                style: const TextStyle(fontSize: 40, color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(height: 24),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.person, color: Color(0xFF00A884)),
                                title: const Text('Naam', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                subtitle: Text(_profile!['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.phone, color: Color(0xFF00A884)),
                                title: const Text('Phone', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                subtitle: Text(_profile!['phone'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.info, color: Color(0xFF00A884)),
                                title: const Text('About', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                subtitle: Text(_profile!['about'] ?? 'Hey there! I am using NexChat',
                                    style: const TextStyle(fontSize: 16)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
