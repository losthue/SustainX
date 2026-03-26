import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _toUserController = TextEditingController();
  final _yellowController = TextEditingController(text: '0');
  final _greenController = TextEditingController(text: '0');
  final _redController = TextEditingController(text: '0');
  final _noteController = TextEditingController();

  bool _isLoading = false;
  String _message = '';
  List<dynamic> _sent = [];
  List<dynamic> _received = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    final sentRes = await ApiService.getSentTransactions();
    final receivedRes = await ApiService.getReceivedTransactions();

    if (sentRes['success'] == true && receivedRes['success'] == true) {
      setState(() {
        _sent = List.from(sentRes['data'] ?? []);
        _received = List.from(receivedRes['data'] ?? []);
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _message = sentRes['message']?.toString() ?? receivedRes['message']?.toString() ?? 'Unable to load transactions';
    });
  }

  Future<void> _sendCoins() async {
    final toUserId = _toUserController.text.trim();
    if (toUserId.isEmpty) {
      setState(() => _message = 'Recipient user ID is required.');
      return;
    }

    final yellow = int.tryParse(_yellowController.text) ?? 0;
    final green = int.tryParse(_greenController.text) ?? 0;
    final red = int.tryParse(_redController.text) ?? 0;

    setState(() {
      _isLoading = true;
      _message = '';
    });

    final res = await ApiService.transferCoins(toUserId, yellowCoins: yellow, greenCoins: green, redCoins: red, note: _noteController.text.trim());

    if (res['success'] == true) {
      _toUserController.clear();
      _yellowController.text = '0';
      _greenController.text = '0';
      _redController.text = '0';
      _noteController.clear();
      await _loadTransactions();
      setState(() {
        _message = 'Transfer completed successfully';
      });
    } else {
      setState(() {
        _message = res['message']?.toString() ?? 'Transfer failed.';
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _toUserController.dispose();
    _yellowController.dispose();
    _greenController.dispose();
    _redController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(_message, style: const TextStyle(color: Colors.green)),
                      ),
                    const Text('Transfer Coins', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: _toUserController,
                      decoration: const InputDecoration(labelText: 'Recipient User ID'),
                    ),
                    TextField(
                      controller: _yellowController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Yellow coins'),
                    ),
                    TextField(
                      controller: _greenController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Green coins'),
                    ),
                    TextField(
                      controller: _redController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Red coins'),
                    ),
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(labelText: 'Note (optional)'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _sendCoins, child: const Text('Send Tokens')),
                    const SizedBox(height: 24),
                    const Text('Sent Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._sent.map((tx) {
                      return Card(
                        child: ListTile(
                          title: Text('To ${tx['toUser'] ?? tx['toUserId'] ?? 'unknown'}'),
                          subtitle: Text('Y:${tx['yellowCoins'] ?? 0} G:${tx['greenCoins'] ?? 0} R:${tx['redCoins'] ?? 0}'),
                          trailing: Text(tx['createdAt']?.toString().split('T').first ?? ''),
                        ),
                      );
                    }),
                    if (_sent.isEmpty)
                      const Padding(padding: EdgeInsets.all(8), child: Text('No sent transactions yet.')),
                    const SizedBox(height: 20),
                    const Text('Received Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._received.map((tx) {
                      return Card(
                        child: ListTile(
                          title: Text('From ${tx['fromUser'] ?? tx['fromUserId'] ?? 'unknown'}'),
                          subtitle: Text('Y:${tx['yellowCoins'] ?? 0} G:${tx['greenCoins'] ?? 0} R:${tx['redCoins'] ?? 0}'),
                          trailing: Text(tx['createdAt']?.toString().split('T').first ?? ''),
                        ),
                      );
                    }),
                    if (_received.isEmpty)
                      const Padding(padding: EdgeInsets.all(8), child: Text('No received transactions yet.')),
                  ],
                ),
              ),
            ),
    );
  }
}
