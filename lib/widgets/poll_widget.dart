import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PollWidget extends StatefulWidget {
  final Map<String, dynamic> poll;
  final bool isMe;

  const PollWidget({super.key, required this.poll, required this.isMe});

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  int? _selectedOption;
  Map<int, int> _votes = {};
  bool _hasVoted = false;

  @override
  void initState() {
    super.initState();
    _loadVotes();
  }

  Future<void> _loadVotes() async {
    try {
      final response = await ApiService.getPoll(widget.poll['id']);
      final votes = response.data['votes'] as List;
      final myVote = response.data['myVote'];
      
      final Map<int, int> voteCounts = {};
      for (var vote in votes) {
        voteCounts[vote['option_index']] = int.parse(vote['count'].toString());
      }
      
      setState(() {
        _votes = voteCounts;
        _selectedOption = myVote;
        _hasVoted = myVote != null;
      });
    } catch (e) {}
  }

  Future<void> _vote(int optionIndex) async {
    if (_hasVoted) return;
    try {
      await ApiService.votePoll(widget.poll['id'], optionIndex);
      setState(() {
        _selectedOption = optionIndex;
        _hasVoted = true;
        _votes[optionIndex] = (_votes[optionIndex] ?? 0) + 1;
      });
    } catch (e) {}
  }

  int get _totalVotes => _votes.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final options = List<String>.from(widget.poll['options']);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.poll, 
                color: widget.isMe ? Colors.white : const Color(0xFF0084FF),
                size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                widget.poll['question'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: widget.isMe ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final voteCount = _votes[index] ?? 0;
          final percentage = _totalVotes > 0
              ? voteCount / _totalVotes
              : 0.0;
          final isSelected = _selectedOption == index;

          return GestureDetector(
            onTap: () => _vote(index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: Stack(
                children: [
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.isMe
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? (widget.isMe
                                ? Colors.white
                                : const Color(0xFF0084FF))
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  if (_hasVoted)
                    Container(
                      height: 40,
                      width: MediaQuery.of(context).size.width *
                          0.65 *
                          percentage,
                      decoration: BoxDecoration(
                        color: widget.isMe
                            ? Colors.white.withValues(alpha: 0.2)
                            : const Color(0xFF0084FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (isSelected)
                              Icon(Icons.check_circle,
                                  size: 16,
                                  color: widget.isMe
                                      ? Colors.white
                                      : const Color(0xFF0084FF)),
                            if (isSelected) const SizedBox(width: 6),
                            Text(
                              option,
                              style: TextStyle(
                                color: widget.isMe
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        if (_hasVoted)
                          Text(
                            '${(percentage * 100).round()}%',
                            style: TextStyle(
                              color: widget.isMe
                                  ? Colors.white70
                                  : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
        Text(
          '$_totalVotes votes',
          style: TextStyle(
            fontSize: 11,
            color: widget.isMe ? Colors.white70 : Colors.grey,
          ),
        ),
      ],
    );
  }
}
