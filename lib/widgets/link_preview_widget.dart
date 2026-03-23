import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LinkPreviewWidget extends StatefulWidget {
  final String url;
  final bool isMe;

  const LinkPreviewWidget({super.key, required this.url, required this.isMe});

  @override
  State<LinkPreviewWidget> createState() => _LinkPreviewWidgetState();
}

class _LinkPreviewWidgetState extends State<LinkPreviewWidget> {
  Map<String, dynamic>? _preview;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final response = await ApiService.getLinkPreview(widget.url);
      setState(() {
        _preview = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF0084FF)),
        ),
      );
    }

    if (_preview == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: widget.isMe
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: widget.isMe ? Colors.white : const Color(0xFF0084FF),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_preview!['image'] != null && _preview!['image'].isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: Image.network(
                _preview!['image'],
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_preview!['siteName'] != null)
                  Text(
                    _preview!['siteName'],
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.isMe
                          ? Colors.white60
                          : const Color(0xFF0084FF),
                    ),
                  ),
                if (_preview!['title'] != null)
                  Text(
                    _preview!['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: widget.isMe ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (_preview!['description'] != null)
                  Text(
                    _preview!['description'],
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.isMe ? Colors.white70 : Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
