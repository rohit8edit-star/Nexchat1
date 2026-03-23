import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class GifPicker extends StatefulWidget {
  final Function(String) onGifSelected;

  const GifPicker({super.key, required this.onGifSelected});

  @override
  State<GifPicker> createState() => _GifPickerState();
}

class _GifPickerState extends State<GifPicker> {
  final _searchController = TextEditingController();
  List<dynamic> _gifs = [];
  bool _isLoading = false;
  final _dio = Dio();

  // Tenor API key (free)
  final String _apiKey = 'AIzaSyAyimkuYQYF_FXVALexPmHA2zHManR4a00';

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dio.get(
        'https://tenor.googleapis.com/v2/featured',
        queryParameters: {
          'key': _apiKey,
          'limit': 20,
          'media_filter': 'gif',
        },
      );
      setState(() => _gifs = response.data['results']);
    } catch (e) {}
    setState(() => _isLoading = false);
  }

  Future<void> _searchGifs(String query) async {
    if (query.isEmpty) {
      _loadTrending();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await _dio.get(
        'https://tenor.googleapis.com/v2/search',
        queryParameters: {
          'key': _apiKey,
          'q': query,
          'limit': 20,
          'media_filter': 'gif',
        },
      );
      setState(() => _gifs = response.data['results']);
    } catch (e) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'GIF search karo...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: _searchGifs,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF0084FF)))
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _gifs.length,
                    itemBuilder: (context, index) {
                      final gif = _gifs[index];
                      final gifUrl =
                          gif['media_formats']['gif']['url'];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onGifSelected(gifUrl);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            gifUrl,
                            fit: BoxFit.cover,
                            loadingBuilder:
                                (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFF0084FF)),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
