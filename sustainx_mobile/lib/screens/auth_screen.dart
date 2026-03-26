import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _pageController = PageController();
  int _currentPage = 0; // 0 = Login, 1 = Register

  // ── Login fields ──────────────────────────────────────────────
  final _loginEmailController    = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscure = true;

  // ── Register fields ───────────────────────────────────────────
  final _regUsernameController = TextEditingController();
  final _regEmailController    = TextEditingController();
  final _regPasswordController = TextEditingController();
  bool _regObscure = true;

  // ── State ──────────────────────────────────────────────────────
  bool   _isLoading = false;
  String _message   = '';

  @override
  void dispose() {
    _pageController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regUsernameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────
  void _switchPage(int page) {
    setState(() {
      _currentPage = page;
      _message     = '';
    });
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _showError(String msg) => setState(() => _message = msg);

  // ── Submit ─────────────────────────────────────────────────────
  Future<void> _submit() async {
    final isRegister = _currentPage == 1;

    if (isRegister) {
      if (_regUsernameController.text.trim().length < 3) {
        _showError('Username must be at least 3 characters.');
        return;
      }
      if (_regEmailController.text.trim().isEmpty ||
          !_regEmailController.text.contains('@')) {
        _showError('Please enter a valid email address.');
        return;
      }
      if (_regPasswordController.text.trim().length < 6) {
        _showError('Password must be at least 6 characters.');
        return;
      }
    } else {
      if (_loginEmailController.text.trim().isEmpty ||
          !_loginEmailController.text.contains('@')) {
        _showError('Please enter a valid email address.');
        return;
      }
      if (_loginPasswordController.text.trim().length < 6) {
        _showError('Password must be at least 6 characters.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _message   = '';
    });

    try {
      final result = isRegister
          ? await ApiService.register(
              _regUsernameController.text.trim(),
              _regEmailController.text.trim(),
              _regPasswordController.text.trim(),
            )
          : await ApiService.login(
              _loginEmailController.text.trim(),
              _loginPasswordController.text.trim(),
            );

      if (result['success'] == true) {
        final token = result['data']?['token'] ?? result['data'];
        final user  = result['data']?['user']?['username'] ??
            _regUsernameController.text.trim();

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
      if (mounted) setState(() => _message = 'Network error: $ex');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(size),
          const SizedBox(height: 40),
          _buildTabs(),
          const SizedBox(height: 12),
          Expanded(child: _buildPages()),
        ],
      ),
    );
  }

  // ── Header (image + logo overlap) ─────────────────────────────
  Widget _buildHeader(Size size) => Stack(
        clipBehavior: Clip.none,
        children: [
          // Background image
          Container(
            height: size.height * .4,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/EnergyPass_header.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: const Center(
              child: Text(''),
            ),
          ),
          // Curved white/surface overlay
          Positioned(
            bottom: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 170,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
            ),
          ),
          // Logo centred over the curve
          Positioned(
            bottom: -75,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/EnergyPass_Logo.png',
              height: 170,
              // remove tint to keep original logo colors
              color: null,
              colorBlendMode: null,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 170,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Text('Logo not found', style: TextStyle(color: Colors.red)),
                  ),
                );
              },
            ),
          ),
        ],
      );

  // ── Tabs ───────────────────────────────────────────────────────
  static const _tabAccentLogin    = Color(0xFFE91E8C); // pink
  static const _tabAccentRegister = Color(0xFF1E88E5); // blue

  Widget _buildTabs() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _tab('Sign In', 0, _tabAccentLogin),
          Text(
            ' | ',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.4),
            ),
          ),
          _tab('Sign Up', 1, _tabAccentRegister),
        ],
      );

  Widget _tab(String label, int page, Color accent) => GestureDetector(
        onTap: () => _switchPage(page),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  _currentPage == page ? FontWeight.bold : FontWeight.normal,
              color: _currentPage == page
                  ? accent
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(.55),
            ),
          ),
        ),
      );

  // ── Pages ──────────────────────────────────────────────────────
  Widget _buildPages() => PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (p) => setState(() => _currentPage = p),
        children: [
          _wrap(_loginForm()),
          _wrap(_registerForm()),
        ],
      );

  Widget _wrap(Widget child) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: child,
      );

  // ── Login form ─────────────────────────────────────────────────
  Widget _loginForm() => Column(
        children: [
          _field(
            controller: _loginEmailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          _passwordField(
            controller: _loginPasswordController,
            label: 'Password',
            obscure: _loginObscure,
            onToggle: () => setState(() => _loginObscure = !_loginObscure),
          ),
          const SizedBox(height: 24),
          _submitButton('Sign In'),
          _errorText(),
        ],
      );

  // ── Register form ──────────────────────────────────────────────
  Widget _registerForm() => Column(
        children: [
          _field(
            controller: _regUsernameController,
            label: 'Username',
            icon: Icons.person_outline,
          ),
          _field(
            controller: _regEmailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          _passwordField(
            controller: _regPasswordController,
            label: 'Password',
            obscure: _regObscure,
            onToggle: () => setState(() => _regObscure = !_regObscure),
          ),
          const SizedBox(height: 24),
          _submitButton('Create Account'),
          _errorText(),
        ],
      );

  // ── Field widgets ──────────────────────────────────────────────
  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _inputDecoration(label, icon),
        ),
      );

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          decoration: _inputDecoration(label, Icons.lock_outline).copyWith(
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: onToggle,
            ),
          ),
        ),
      );

  InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(.35),
          ),
        ),
      );

  // ── Gradient submit button ─────────────────────────────────────
  Widget _submitButton(String label) => SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_tabAccentLogin, _tabAccentRegister],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      );

  // ── Error message ──────────────────────────────────────────────
  Widget _errorText() => _message.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Text(
            _message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 13,
            ),
          ),
        );
}