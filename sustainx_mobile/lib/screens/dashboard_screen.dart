import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String _message = '';
  Map<String, dynamic> _walletData = {};

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getWalletInfo();
    if (result['success'] == true) {
      setState(() {
        _walletData = Map<String, dynamic>.from(result['data'] ?? {});
        _message = '';
        _isLoading = false;
      });
      return;
    }

    if (result['statusCode'] == 401) {
      await _logout();
      return;
    }

    setState(() {
      _message = result['message']?.toString() ?? 'Unable to load wallet';
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await ApiService.clearAuth();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/auth');
  }

  @override
  Widget build(BuildContext context) {
    final username = _walletData['username'] ?? 'User';
    final balances = _walletData['balances'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('SustainX Dashboard'),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Text('Hello, $username', style: const TextStyle(color: Colors.white, fontSize: 20)),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Energy Monitor'),
              onTap: () => Navigator.pushNamed(context, '/energy'),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Transactions'),
              onTap: () => Navigator.pushNamed(context, '/transactions'),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Leaderboard'),
              onTap: () => Navigator.pushNamed(context, '/leaderboard'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWallet,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_message.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(_message, style: const TextStyle(color: Colors.red)),
                        ),
                      Card(
                        child: ListTile(
                          title: Text('Wallet: ${_walletData['walletAddress'] ?? '-'}'),
                          subtitle: Text('Energy Score: ${_walletData['energyScore'] ?? '0'}'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Balances', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              Text('Yellow: ${balances['yellowCoins'] ?? 0}'),
                              Text('Green: ${balances['greenCoins'] ?? 0}'),
                              Text('Red: ${balances['redCoins'] ?? 0}'),
                              const SizedBox(height: 8),
                              Text('Total: ${_walletData['totalBalance'] ?? 0}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.history),
                        label: const Text('View Energy History'),
                        onPressed: () => Navigator.pushNamed(context, '/energy'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.swap_calls),
                        label: const Text('Send Coins & View History'),
                        onPressed: () => Navigator.pushNamed(context, '/transactions'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.emoji_events),
                        label: const Text('Leaderboard'),
                        onPressed: () => Navigator.pushNamed(context, '/leaderboard'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
