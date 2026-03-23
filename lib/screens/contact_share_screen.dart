import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ContactShareScreen extends StatefulWidget {
  final String receiverId;
  final String? groupId;

  const ContactShareScreen({
    super.key,
    required this.receiverId,
    this.groupId,
  });

  @override
  State<ContactShareScreen> createState() => _ContactShareScreenState();
}

class _ContactShareScreenState extends State<ContactShareScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _shareContact() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Naam aur phone daalo!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.shareContact(
        widget.receiverId,
        widget.groupId,
        _nameController.text.trim(),
        _phoneController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact share ho gaya! 👤')),
        );
        Navigator.pop(context);
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
        title: const Text('Contact Share karo'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _shareContact,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('SEND',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF0084FF),
              child: Icon(Icons.person, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Contact ka naam',
                prefixIcon:
                    const Icon(Icons.person, color: Color(0xFF0084FF)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF0084FF), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone number',
                prefixIcon:
                    const Icon(Icons.phone, color: Color(0xFF0084FF)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF0084FF), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _shareContact,
                icon: const Icon(Icons.share),
                label: const Text('Contact Share karo',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0084FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
