import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ---------------------------------------------------------------------------
// Minimal local colour + gradient helpers (mirrors AppColors / GradientBoxBorder
// from the reference project without requiring those packages).
// ---------------------------------------------------------------------------

const _kPink   = Color(0xFFE91E8C);
const _kPurple = Color(0xFF9C27B0);
const _gradientColors = [_kPink, _kPurple];

/// A simple [BoxBorder] that paints a gradient stroke.
class _GradientBoxBorder extends BoxBorder {
  const _GradientBoxBorder({required this.gradient, this.width = 2});

  final Gradient gradient;
  final double   width;

  @override
  BorderSide get bottom => BorderSide.none;
  @override
  BorderSide get top    => BorderSide.none;
  @override
  bool get isUniform    => true;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    if (borderRadius != null) {
      canvas.drawRRect(borderRadius.toRRect(rect), paint);
    } else {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  ShapeBorder scale(double t) => this;
}

// ---------------------------------------------------------------------------
// ProfileScreen
// ---------------------------------------------------------------------------

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usernameController = TextEditingController();
  final _emailController    = TextEditingController();

  bool   _loading   = true;
  bool   _isEditing = false;
  String _message   = '';

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _message = ''; });

    final result = await ApiService.getProfile();

    if (result['success'] == true) {
      final data = Map<String, dynamic>.from(result['data'] ?? {});
      _usernameController.text = data['username'] ?? '';
      _emailController.text    = data['email']    ?? '';
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _message = result['message']?.toString() ?? 'Failed to load profile';
      _loading = false;
    });
  }

  Future<void> _updateProfile() async {
    // Basic validation
    if (_usernameController.text.trim().isEmpty) {
      _snack('Username is required', Colors.red); return;
    }
    if (_emailController.text.trim().isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text.trim())) {
      _snack('Please enter a valid email', Colors.red); return;
    }

    setState(() { _loading = true; _message = ''; _isEditing = false; });

    final result = await ApiService.updateProfile({
      'username': _usernameController.text.trim(),
      'email':    _emailController.text.trim(),
    });

    if (result['success'] == true) {
      _snack('Profile updated successfully', Colors.green);
      await _loadProfile();
    } else {
      _snack(result['message']?.toString() ?? 'Failed to update profile', Colors.red);
      setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor      = isDark ? const Color(0xFF121212) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final textColor    = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  // ── Avatar ───────────────────────────────────────────────
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: surfaceColor,
                    child: const Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 10),

                  // ── Name & email ─────────────────────────────────────────
                  Text(
                    _usernameController.text,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _emailController.text,
                    style: TextStyle(color: subTextColor),
                  ),
                  const SizedBox(height: 20),

                  // ── Info card ────────────────────────────────────────────
                  _buildInfoCard(
                    bgColor:      bgColor,
                    surfaceColor: surfaceColor,
                    textColor:    textColor,
                    isDark:       isDark,
                  ),

                  const SizedBox(height: 30),

                  // ── Option rows ──────────────────────────────────────────
                  _buildOptionRow(
                    icon:     Icons.settings,
                    label:    'Settings',
                    bgColor:  bgColor,
                    isDark:   isDark,
                    textColor: textColor,
                    onTap:    () {/* Navigate to SettingsScreen */},
                  ),
                  _buildOptionRow(
                    icon:     Icons.password,
                    label:    'Change Password',
                    bgColor:  bgColor,
                    isDark:   isDark,
                    textColor: textColor,
                    onTap:    () {/* Navigate to ChangePasswordScreen */},
                  ),
                  _buildOptionRow(
                    icon:     Icons.reviews_outlined,
                    label:    'Send Review',
                    bgColor:  bgColor,
                    isDark:   isDark,
                    textColor: textColor,
                    onTap:    () {/* Navigate to SendReviewScreen */},
                  ),
                  _buildOptionRow(
                    icon:      Icons.logout,
                    label:     'Log Out',
                    bgColor:   bgColor,
                    isDark:    isDark,
                    textColor: textColor,
                    onTap: () async {
                      await ApiService.clearAuth();
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, '/auth');
                    },
                  ),
                ],
              ),
            ),
    );
  }

  // ── Info card ──────────────────────────────────────────────────────────────

  Widget _buildInfoCard({
    required Color bgColor,
    required Color surfaceColor,
    required Color textColor,
    required bool  isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: _GradientBoxBorder(
          gradient: const LinearGradient(colors: _gradientColors),
          width: 2,
        ),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField(
            label:       'Username',
            controller:  _usernameController,
            surfaceColor: surfaceColor,
            textColor:   textColor,
          ),
          _buildField(
            label:       'Email',
            controller:  _emailController,
            surfaceColor: surfaceColor,
            textColor:   textColor,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),
          _buildEditSaveButton(),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required Color surfaceColor,
    required Color textColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
          ),
          const SizedBox(height: 6),
          TextField(
            controller:  controller,
            enabled:     _isEditing,
            keyboardType: keyboardType,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              filled:      true,
              fillColor:   surfaceColor,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditSaveButton() {
    return SizedBox(
      height: 45,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: _gradientColors),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor:     Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: () {
            if (_isEditing) {
              _updateProfile();
            } else {
              setState(() => _isEditing = true);
            }
          },
          child: Text(
            _isEditing ? 'Save' : 'Edit Profile',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  // ── Option row ─────────────────────────────────────────────────────────────

  Widget _buildOptionRow({
    required IconData icon,
    required String   label,
    required Color    bgColor,
    required Color    textColor,
    required bool     isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: _GradientBoxBorder(
            gradient: const LinearGradient(colors: _gradientColors),
            width: 2,
          ),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(icon, color: _kPink),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ]),
            const Icon(Icons.chevron_right, color: _kPink),
          ],
        ),
      ),
    );
  }
}