import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _loading = true;
  String _error = '';
  List<dynamic> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final result = await ApiService.getLeaderboard();
    if (result['success'] == true) {
      setState(() {
        _leaderboard = List.from(result['data'] ?? []);
        _loading = false;
      });
      return;
    }
    setState(() {
      _error = result['message']?.toString() ?? 'Failed to load leaderboard';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _fetchLeaderboard,
                  child: ListView.separated(
                    itemCount: _leaderboard.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _leaderboard[index] as Map<String, dynamic>;
                      final rank = index + 1;
                      return ListTile(
                        leading: CircleAvatar(child: Text(rank.toString())),
                        title: Text(item['username'] ?? 'N/A'),
                        subtitle: Text('Total Coins: ${item['totalCoins'] ?? 0}'),
                        trailing: Text('Rank ${item['rank'] ?? rank}'),
                      );
                    },
                  ),
                ),
    );
  }
}
