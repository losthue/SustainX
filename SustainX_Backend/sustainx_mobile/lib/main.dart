import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

const String backendBaseUrl = 'http://10.0.2.2:5000/api';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SustainX EnergyPass',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isRegister = false;
  bool _isLoading = false;
  String _message = '';

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    final url = Uri.parse(backendBaseUrl + (_isRegister ? '/auth/register' : '/auth/login'));

    final body = {
      if (_isRegister) 'username': _username.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text.trim(),
    };

    try {
      final res = await http.post(url,
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));

      final json = jsonDecode(res.body);

      if (res.statusCode >= 400 || json['success'] != true) {
        setState(() {
          _message = json['message'] ?? 'Authentication failed';
          _isLoading = false;
        });
        return;
      }

      final token = json['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('energyToken', token);
      await prefs.setString('energyUser', json['user']['username']);

      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()));
    } catch (e) {
      setState(() {
        _message = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isRegister ? 'Register' : 'Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_isRegister)
                TextField(
                  controller: _username,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _authenticate,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isRegister ? 'Register' : 'Login'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isRegister = !_isRegister;
                    _message = '';
                  });
                },
                child: Text(_isRegister ? 'Already have account? Login' : 'Create account'),
              ),
              if (_message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_message, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String token = '';
  Map<String, dynamic> userWallet = {};
  String message = '';
  bool loading = true;
  final _importController = TextEditingController(text: '0');
  final _exportController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('energyToken') ?? '';
    token = storedToken;

    if (token.isEmpty) {
      _logout();
      return;
    }

    final url = Uri.parse('$backendBaseUrl/wallet/info');
    final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (res.statusCode == 401) {
      _logout();
      return;
    }

    final json = jsonDecode(res.body);

    setState(() {
      loading = false;
      if (json['success'] == true) {
        userWallet = json['data'] ?? {};
      } else {
        message = json['message'] ?? 'Unable to load wallet';
      }
    });
  }

  Future<void> _recordEnergy() async {
    final imported = double.tryParse(_importController.text) ?? 0;
    final exported = double.tryParse(_exportController.text) ?? 0;

    final url = Uri.parse('$backendBaseUrl/energy/record');
    final res = await http.post(url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'importedKWh': imported, 'exportedKWh': exported, 'conversionRate': 10}));

    final json = jsonDecode(res.body);

    setState(() {
      message = json['message'] ?? '';
    });

    if (res.statusCode == 201 && json['success'] == true) {
      await _loadProfile();
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('energyToken');
    await prefs.remove('energyUser');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EnergyPass Dashboard'),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: ListTile(
                      title: Text(userWallet['username'] ?? 'User'),
                      subtitle: Text('Wallet: ${userWallet['walletAddress'] ?? '-'}'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Balances', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Yellow: ${userWallet['balances']?['yellowCoins'] ?? 0}'),
                          Text('Green: ${userWallet['balances']?['greenCoins'] ?? 0}'),
                          Text('Red: ${userWallet['balances']?['redCoins'] ?? 0}'),
                          Text('Total: ${userWallet['totalBalance'] ?? 0}'),
                          Text('Score: ${userWallet['energyScore'] ?? 0}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Record Energy Data', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _importController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Imported kWh'),
                  ),
                  TextField(
                    controller: _exportController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Exported kWh'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _recordEnergy, child: const Text('Submit Energy')),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(message, style: const TextStyle(color: Colors.green)),
                  ],
                ],
              ),
            ),
    );
  }
}
