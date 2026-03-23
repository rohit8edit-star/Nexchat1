import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreatePollScreen extends StatefulWidget {
  final String? groupId;
  final String? channelId;

  const CreatePollScreen({super.key, this.groupId, this.channelId});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _isLoading = false;
  bool _isMultiple = false;

  void _addOption() {
    if (_optionControllers.length < 6) {
      setState(() => _optionControllers.add(TextEditingController()));
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() => _optionControllers.removeAt(index));
    }
  }

  Future<void> _createPoll() async {
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question daalo!')),
      );
      return;
    }

    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((o) => o.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kam se kam 2 options daalo!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.createPoll(
        _questionController.text.trim(),
        options,
        groupId: widget.groupId,
        channelId: widget.channelId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Poll ban gaya! 📊')),
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
        title: const Text('Poll Banao'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPoll,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('CREATE',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Question',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _questionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Apna question likho...',
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
            const Text('Options',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 12)),
            const SizedBox(height: 8),
            ...List.generate(_optionControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _optionControllers[index],
                        decoration: InputDecoration(
                          hintText: 'Option ${index + 1}',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF0084FF), width: 2),
                          ),
                        ),
                      ),
                    ),
                    if (_optionControllers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle,
                            color: Colors.red),
                        onPressed: () => _removeOption(index),
                      ),
                  ],
                ),
              );
            }),
            if (_optionControllers.length < 6)
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add, color: Color(0xFF0084FF)),
                label: const Text('Option add karo',
                    style: TextStyle(color: Color(0xFF0084FF))),
              ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Multiple choice allow karo'),
              subtitle:
                  const Text('Users multiple options choose kar sakte hain'),
              value: _isMultiple,
              onChanged: (value) => setState(() => _isMultiple = value),
              activeColor: const Color(0xFF0084FF),
            ),
          ],
        ),
      ),
    );
  }
}
