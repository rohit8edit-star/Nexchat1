import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  List<dynamic> _selectedMembers = [];
  File? _groupImage;
  bool _isLoading = false;

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    try {
      final response = await ApiService.searchUsers(query);
      setState(() => _searchResults = response.data);
    } catch (e) {}
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _groupImage = File(picked.path));
    }
  }

  Future<void> _createGroup() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group naam daalo!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.createGroup(
        _nameController.text.trim(),
        _descController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group ban gaya! 🎉')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0084FF),
        foregroundColor: Colors.white,
        title: const Text('Naya Group'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createGroup,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('CREATE',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Group info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF0084FF),
                    backgroundImage: _groupImage != null
                        ? FileImage(_groupImage!)
                        : null,
                    child: _groupImage == null
                        ? const Icon(Icons.camera_alt,
                            color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Group naam daalo',
                          border: UnderlineInputBorder(),
                        ),
                      ),
                      TextField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          hintText: 'Description (optional)',
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Selected members
          if (_selectedMembers.isNotEmpty)
            Container(
              height: 80,
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedMembers.length,
                itemBuilder: (context, index) {
                  final member = _selectedMembers[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF0084FF),
                              child: Text(
                                member['name'][0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => setState(() =>
                                    _selectedMembers.remove(member)),
                                child: const CircleAvatar(
                                  radius: 8,
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close,
                                      size: 10, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          member['name'].toString().split(' ')[0],
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Search
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Members search karo...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _searchUsers,
            ),
          ),

          // Search results
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                final isSelected = _selectedMembers
                    .any((m) => m['id'] == user['id']);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0084FF),
                    child: Text(user['name'][0].toUpperCase(),
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(user['name']),
                  subtitle: Text(user['phone']),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: Color(0xFF0084FF))
                      : const Icon(Icons.circle_outlined,
                          color: Colors.grey),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedMembers
                            .removeWhere((m) => m['id'] == user['id']);
                      } else {
                        _selectedMembers.add(user);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
