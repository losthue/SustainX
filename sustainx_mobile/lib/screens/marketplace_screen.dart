import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../services/api_service.dart';

// ── Shared palette ─────────────────────────────────────────────────────────
const _kPink   = Color(0xFFE91E8C);
const _kPurple = Color(0xFF9C27B0);
const _kGold   = Color(0xFFFFB300);
const _kGreen  = Color(0xFF43A047);

const _gradientColors = [_kPink, _kPurple];

// ── Gradient border ────────────────────────────────────────────────────────
class _GradientBoxBorder extends BoxBorder {
  const _GradientBoxBorder({required this.gradient, this.width = 2});
  final Gradient gradient;
  final double   width;

  @override BorderSide get bottom => BorderSide.none;
  @override BorderSide get top    => BorderSide.none;
  @override bool get isUniform    => true;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  void paint(Canvas canvas, Rect rect,
      {TextDirection? textDirection,
      BoxShape shape = BoxShape.rectangle,
      BorderRadius? borderRadius}) {
    final paint = Paint()
      ..shader     = gradient.createShader(rect)
      ..strokeWidth = width
      ..style       = PaintingStyle.stroke;
    if (borderRadius != null) {
      canvas.drawRRect(borderRadius.toRRect(rect), paint);
    } else {
      canvas.drawRect(rect, paint);
    }
  }

  @override ShapeBorder scale(double t) => this;
}

// ── Screen ─────────────────────────────────────────────────────────────────
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  bool   _isLoading  = true;
  String _message    = '';
  bool   _msgIsError = false;
  Map<String, dynamic> _walletData = {};
  List<dynamic> _packages = [];

  // Hardcoded fallback packages
  static const _fallbackPackages = [
    {'id': '1', 'name': 'Starter', 'coins': 100, 'bonus': 10, 'total_coins': 110, 'price': 199, 'currency': 'MUR'},
    {'id': '2', 'name': 'Popular', 'coins': 500, 'bonus': 50, 'total_coins': 550, 'price': 799, 'currency': 'MUR'},
    {'id': '3', 'name': 'Pro', 'coins': 1000, 'bonus': 200, 'total_coins': 1200, 'price': 1499, 'currency': 'MUR'},
    {'id': '4', 'name': 'Elite', 'coins': 2500, 'bonus': 500, 'total_coins': 3000, 'price': 3499, 'currency': 'MUR'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _message = ''; });

    final walletRes   = await ApiService.getWalletInfo();
    final packagesRes = await ApiService.getPackages();

    setState(() {
      if (walletRes['success'] == true) {
        _walletData = Map<String, dynamic>.from(walletRes['data'] ?? {});
      }
      if (packagesRes['success'] == true && (packagesRes['data'] as List?)?.isNotEmpty == true) {
        _packages = List.from(packagesRes['data'] ?? []);
      } else {
        _packages = List.from(_fallbackPackages);
      }
      _isLoading = false;
    });

    if (walletRes['success'] != true) {
      _setMsg(walletRes['message']?.toString() ?? 'Unable to load wallet', isError: true);
    }
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  // ── Stripe Payment Flow ───────────────────────────────────────────────────
  Future<void> _purchasePackage(Map<String, dynamic> package) async {
    final pkgId = package['id']?.toString() ?? '';
    final name  = package['name']?.toString() ?? 'Package';
    final total = _toInt(package['total_coins']);
    final price = _toInt(package['price']);

    // Confirm
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase $name'),
        content: Text('Buy $total Green Coins for MUR $price?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _kGreen),
            child: const Text('Continue to Payment'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    setState(() { _isLoading = true; _message = ''; });

    try {
      // 1. Create payment intent on backend
      final res = await ApiService.createPaymentIntent(pkgId);

      if (res['success'] != true) {
        setState(() => _isLoading = false);
        _setMsg(res['message']?.toString() ?? 'Failed to create payment', isError: true);
        return;
      }

      final data = res['data'] as Map<String, dynamic>;
      final clientSecret   = data['payment_intent']?.toString() ?? '';
      final ephemeralKey   = data['ephemeral_key']?.toString() ?? '';
      final customerId     = data['customer_id']?.toString() ?? '';
      final publishableKey = data['publishable_key']?.toString() ?? '';

      if (clientSecret.isEmpty || publishableKey.isEmpty) {
        setState(() => _isLoading = false);
        _setMsg('Payment configuration incomplete. Check Stripe keys.', isError: true);
        return;
      }

      // 2. Set Stripe publishable key
      Stripe.publishableKey = publishableKey;

      // 3. Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          customerEphemeralKeySecret: ephemeralKey,
          customerId: customerId,
          merchantDisplayName: 'SustainX',
          style: ThemeMode.system,
        ),
      );

      setState(() => _isLoading = false);

      // 4. Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // 5. Payment succeeded — confirm on backend
      setState(() { _isLoading = true; });

      // Extract payment intent ID from client secret
      final paymentIntentId = clientSecret.split('_secret_').first;
      final confirmRes = await ApiService.confirmPayment(paymentIntentId);

      if (confirmRes['success'] == true) {
        final coins = confirmRes['data']?['coins_credited'] ?? total;
        _setMsg('🎉 Payment successful! $coins Green Coins added!', isError: false);
      } else {
        _setMsg('Payment received! Coins will be credited shortly.', isError: false);
      }

      await _loadData();

    } on StripeException catch (e) {
      setState(() => _isLoading = false);
      if (e.error.code == FailureCode.Canceled) {
        _setMsg('Payment cancelled.', isError: true);
      } else {
        _setMsg('Payment error: ${e.error.localizedMessage}', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _setMsg('Error: $e', isError: true);
    }
  }

  void _setMsg(String msg, {required bool isError}) =>
      setState(() { _message = msg; _msgIsError = isError; });

  int get _greenCoins => _toInt(_walletData['green_coins']);
  int get _redCoins   => _toInt(_walletData['red_coins']);

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final bgColor      = isDark ? const Color(0xFF121212) : const Color(0xFFF8F0FF);
    final textColor    = isDark ? Colors.white : Colors.black87;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: _gradientColors,
          ).createShader(r),
          child: const Text(
            'Marketplace',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: Colors.white,
              letterSpacing: 1.1,
            ),
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_message.isNotEmpty) _buildMessageBanner(),
                    const SizedBox(height: 8),

                    _buildBalanceCard(surfaceColor, textColor, isDark),
                    const SizedBox(height: 16),

                    _buildStripeBadge(),
                    const SizedBox(height: 16),

                    _buildPackagesSection(surfaceColor, textColor, isDark),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Message banner ────────────────────────────────────────────────────────
  Widget _buildMessageBanner() {
    final isError = _msgIsError;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? Colors.red.shade300 : Colors.green.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.red : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _message,
              style: TextStyle(
                color: isError ? Colors.red : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stripe badge ──────────────────────────────────────────────────────────
  Widget _buildStripeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF635BFF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF635BFF).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: Color(0xFF635BFF), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Secure payments powered by Stripe',
              style: TextStyle(
                color: const Color(0xFF635BFF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF635BFF).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('SSL', style: TextStyle(
              color: Color(0xFF635BFF), fontSize: 10, fontWeight: FontWeight.bold,
            )),
          ),
        ],
      ),
    );
  }

  // ── Balance card ──────────────────────────────────────────────────────────
  Widget _buildBalanceCard(Color surface, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: _GradientBoxBorder(
          gradient: const LinearGradient(colors: _gradientColors),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _kPink.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/images/Green_Coin.png',
              width: 32, height: 32,
              errorBuilder: (_, __, ___) => Icon(Icons.eco_rounded, color: _kGreen, size: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Green Coins',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                const SizedBox(height: 4),
                Text('$_greenCoins coins',
                  style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7))),
              ],
            ),
          ),
          if (_redCoins > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$_redCoins debt',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 11)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Available',
                style: TextStyle(color: _kGreen, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  // ── Packages section ──────────────────────────────────────────────────────
  Widget _buildPackagesSection(Color surface, Color textColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Buy Green Coins',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: _packages.length,
          itemBuilder: (context, index) =>
            _buildPackageCard(_packages[index] as Map<String, dynamic>, surface, textColor, isDark),
        ),
      ],
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg, Color surface, Color textColor, bool isDark) {
    final name   = pkg['name']?.toString() ?? '';
    final coins  = _toInt(pkg['coins']);
    final bonus  = _toInt(pkg['bonus']);
    final price  = _toInt(pkg['price']);
    final isBest = name == 'Popular';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: _GradientBoxBorder(
          gradient: LinearGradient(
            colors: isBest
                ? [_kGold, _kGold.withOpacity(0.7)]
                : [_kGreen, _kGreen.withOpacity(0.7)],
          ),
          width: isBest ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isBest ? _kGold : _kGreen).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isBest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kGold, Color(0xFFFF8F00)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('⭐ BEST VALUE',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),

          Image.asset(
            'assets/images/Green_Coin.png',
            width: 36, height: 36,
            errorBuilder: (_, __, ___) => Icon(Icons.eco_rounded, color: _kGreen, size: 36),
          ),
          const SizedBox(height: 6),

          Text(name,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
            textAlign: TextAlign.center),
          const SizedBox(height: 3),

          Text('$coins', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _kGreen)),
          if (bonus > 0) ...[
            const SizedBox(height: 2),
            Text('+$bonus bonus',
              style: TextStyle(fontSize: 10, color: _kGreen.withOpacity(0.8), fontWeight: FontWeight.w500)),
          ],
          const SizedBox(height: 6),

          Text('MUR $price',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 28,
            child: ElevatedButton(
              onPressed: () => _purchasePackage(pkg),
              style: ElevatedButton.styleFrom(
                backgroundColor: isBest ? _kGold : _kGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_card_rounded, size: 14),
                  SizedBox(width: 4),
                  Text('Buy'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}