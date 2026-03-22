import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CreateStatusScreen extends StatefulWidget {
  const CreateStatusScreen({super.key});

  @override
  State<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends State<CreateStatusScreen> {
  final _contentController = TextEditingController();
  bool _isLoading = false;
  Color _selectedColor = const Color(0xFF0084FF);

  final List<Color> _colors = [
    const Color(0xFF0084FF),
    const Color(0xFF000000),
    const Color(0xFF128C7E),
    const Color(0xFFD32F2F),
    const Color(0xFF7B1FA2),
    const Color(0xFFE64A19),
    const Color(0xFF1565C0),
    const Color(0xFF2E7D32),
  ];

  Future<void> _postStatus() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kuch likho status mein!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final colorHex =
          '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';
      await ApiService.createStatus(
          _contentController.text.trim(), colorHex);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status post ho gaya! ✅')),
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
      backgroundColor: _selectedColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Status banao'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _postStatus,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('POST',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Kuch likho...',
                    hintStyle: TextStyle(color: Colors.white60),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black26,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _colors.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color
                            ? Colors.white
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
