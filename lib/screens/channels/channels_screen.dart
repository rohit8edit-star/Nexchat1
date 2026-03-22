import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'channel_detail_screen.dart';

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _allChannels = [];
  List<dynamic> _myChannels = [];
  List<dynamic> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    try {
      final allResponse = await ApiService.getChannels();
      final myResponse = await ApiService.getMyChannels();
      setState(() {
        _allChannels = allResponse.data;
        _myChannels = myResponse.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchChannels(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final response = await ApiService.searchChannels(query);
      setState(() => _searchResults = response.data);
    } catch (e) {
      setState(() => _searchResults = []);
    }
  }

  Future<void> _createChannel() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Naya Channel banao'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Channel naam'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.createChannel(
                    nameController.text, descController.text);
                if (mounted) {
                  Navigator.pop(context);
                  _loadChannels();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Channel ban gaya! ✅')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0084FF),
                foregroundColor: Colors.white),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelTile(dynamic channel) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF0084FF),
        child: Text(channel['name'][0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      title: Text(channel['name'],
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${channel['subscribers']} subscribers'),
      trailing: channel['is_subscribed'] == true
          ? const Icon(Icons.check_circle, color: Color(0xFF0084FF))
          : const Icon(Icons.add_circle_outline, color: Colors.grey),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChannelDetailScreen(
            channelId: channel['id'],
            channelName: channel['name'],
          ),
        ),
      ).then((_) => _loadChannels()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0084FF),
        foregroundColor: Colors.white,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Channel search karo...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: _searchChannels,
              )
            : const Text('Channels',
                style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchResults = [];
                }
              });
            },
          ),
        ],
        bottom: !_isSearching
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'EXPLORE'),
                  Tab(text: 'MY CHANNELS'),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0084FF)))
          : _isSearching
              ? ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) =>
                      _buildChannelTile(_searchResults[index]),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    RefreshIndicator(
                      onRefresh: _loadChannels,
                      child: ListView.builder(
                        itemCount: _allChannels.length,
                        itemBuilder: (context, index) =>
                            _buildChannelTile(_allChannels[index]),
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: _loadChannels,
                      child: _myChannels.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.campaign_outlined,
                                      size: 80, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('Koi channel nahi hai!',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _myChannels.length,
                              itemBuilder: (context, index) =>
                                  _buildChannelTile(_myChannels[index]),
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0084FF),
        foregroundColor: Colors.white,
        onPressed: _createChannel,
        child: const Icon(Icons.add),
      ),
    );
  }
}
