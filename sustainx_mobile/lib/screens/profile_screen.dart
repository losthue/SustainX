import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loading = true;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _message = '';
    });
    final result = await ApiService.getProfile();
    if (result['success'] == true) {
      final data = Map<String, dynamic>.from(result['data'] ?? {});
      _usernameController.text = data['username'] ?? '';
      _emailController.text = data['email'] ?? '';
      setState(() {
        _loading = false;
      });
      return;
    }
    setState(() {
      _message = result['message']?.toString() ?? 'Failed to load profile';
      _loading = false;
    });
  }

  Future<void> _updateProfile() async {
    setState(() {
      _loading = true;
      _message = '';
    });
    final result = await ApiService.updateProfile(
      {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
      },
    );
    if (result['success'] == true) {
      setState(() {
        _message = 'Profile updated successfully.';
      });
      await _loadProfile();
    } else {
      setState(() {
        _message = result['message']?.toString() ?? 'Failed to update profile';
      });
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(_message, style: const TextStyle(color: Colors.green)),
                    ),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _updateProfile, child: const Text('Save Profile')),
                ],
              ),
            ),
    );
  }
}
