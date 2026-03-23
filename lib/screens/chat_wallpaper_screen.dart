import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatWallpaperScreen extends StatefulWidget {
  final String chatId;

  const ChatWallpaperScreen({super.key, required this.chatId});

  @override
  State<ChatWallpaperScreen> createState() => _ChatWallpaperScreenState();
}

class _ChatWallpaperScreenState extends State<ChatWallpaperScreen> {
  String _selectedWallpaper = 'default';

  final List<Map<String, dynamic>> _wallpapers = [
    {'id': 'default', 'color': 0xFFF0F2F5, 'name': 'Default'},
    {'id': 'blue', 'color': 0xFFE3F2FD, 'name': 'Light Blue'},
    {'id': 'green', 'color': 0xFFE8F5E9, 'name': 'Light Green'},
    {'id': 'purple', 'color': 0xFFF3E5F5, 'name': 'Purple'},
    {'id': 'orange', 'color': 0xFFFFF3E0, 'name': 'Orange'},
    {'id': 'pink', 'color': 0xFFFCE4EC, 'name': 'Pink'},
    {'id': 'dark', 'color': 0xFF212121, 'name': 'Dark'},
    {'id': 'navy', 'color': 0xFF1A237E, 'name': 'Navy'},
  ];

  @override
  void initState() {
    super.initState();
    _loadWallpaper();
  }

  Future<void> _loadWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedWallpaper =
          prefs.getString('wallpaper_${widget.chatId}') ?? 'default';
    });
  }

  Future<void> _saveWallpaper(String wallpaperId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wallpaper_${widget.chatId}', wallpaperId);
    setState(() => _selectedWallpaper = wallpaperId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallpaper set ho gaya! ✅')),
      );
      Navigator.pop(context, wallpaperId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0084FF),
        foregroundColor: Colors.white,
        title: const Text('Chat Wallpaper'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: _wallpapers.length,
        itemBuilder: (context, index) {
          final wallpaper = _wallpapers[index];
          final isSelected = _selectedWallpaper == wallpaper['id'];

          return GestureDetector(
            onTap: () => _saveWallpaper(wallpaper['id']),
            child: Container(
              decoration: BoxDecoration(
                color: Color(wallpaper['color']),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0084FF)
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    const Icon(Icons.check_circle,
                        color: Color(0xFF0084FF), size: 32),
                  Text(
                    wallpaper['name'],
                    style: TextStyle(
                      color: wallpaper['color'] == 0xFF212121 ||
                              wallpaper['color'] == 0xFF1A237E
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
