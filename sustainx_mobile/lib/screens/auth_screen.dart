import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _isLoading = false;
  String _message = '';

  Future<void> _submit() async {
    if (_isRegister && _usernameController.text.trim().length < 3) {
      setState(() => _message = 'Username must be at least 3 characters long.');
      return;
    }
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      setState(() => _message = 'Please enter a valid email address.');
      return;
    }
    if (_passwordController.text.trim().length < 6) {
      setState(() => _message = 'Password must be at least 6 characters long.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final result = _isRegister
          ? await ApiService.register(
              _usernameController.text.trim(),
              _emailController.text.trim(),
              _passwordController.text.trim())
          : await ApiService.login(
              _emailController.text.trim(),
              _passwordController.text.trim());

      if (result['success'] == true) {
        final token = result['data']?['token'] ?? result['data'];
        final user = result['data']?['user']?['username'] ?? _usernameController.text.trim();

        if (token != null && token is String && token.isNotEmpty) {
          await ApiService.saveToken(token, user as String);
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/dashboard');
          return;
        }
      }

      setState(() {
        _message = result['message']?.toString() ?? 'Authentication failed';
      });
    } catch (ex) {
      if (mounted) {
        setState(() {
          _message = 'Network error: ${ex.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
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
                child: Text(_isRegister
                    ? 'Already have account? Login'
                    : 'Create account'),
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
