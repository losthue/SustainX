import 'package:flutter/material.dart';
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

// ── Coin package model ─────────────────────────────────────────────────────
class _CoinPackage {
  const _CoinPackage({
    required this.id,
    required this.name,
    required this.coinAmount,
    required this.price,
    required this.bonus,
    required this.description,
  });

  final String id;
  final String name;
  final int    coinAmount;
  final double price;
  final int    bonus;
  final String description;

  int get totalCoins => coinAmount + bonus;
}

// ── Screen ─────────────────────────────────────────────────────────────────
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  bool          _isLoading = true;
  String        _message   = '';
  bool          _msgIsError = false;
  Map<String, dynamic> _walletData = {};
  late List<_CoinPackage> _packages;

  @override
  void initState() {
    super.initState();
    _initializePackages();
    _loadData();
  }

  void _initializePackages() {
    _packages = [
      const _CoinPackage(
        id:          '1',
        name:        'Starter',
        coinAmount:  100,
        price:       199,
        bonus:       10,
        description: 'Perfect for beginners',
      ),
      const _CoinPackage(
        id:          '2',
        name:        'Popular',
        coinAmount:  500,
        price:       799,
        bonus:       50,
        description: 'Best value',
      ),
      const _CoinPackage(
        id:          '3',
        name:        'Pro',
        coinAmount:  1000,
        price:       1499,
        bonus:       200,
        description: 'Serious investors',
      ),
      const _CoinPackage(
        id:          '4',
        name:        'Elite',
        coinAmount:  2500,
        price:       3499,
        bonus:       500,
        description: 'Maximum savings',
      ),
    ];
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _message = ''; });

    final walletRes = await ApiService.getWalletInfo();

    if (walletRes['success'] == true) {
      setState(() {
        _walletData = Map<String, dynamic>.from(walletRes['data'] ?? {});
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading  = false;
      _message    = walletRes['message']?.toString() ?? 'Unable to load wallet';
      _msgIsError = true;
    });
  }

  Future<void> _purchasePackage(_CoinPackage package) async {
    // Show a confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${package.name}'),
        content: Text(
          'Add ${package.totalCoins} Green Coins for MUR ${package.price.toStringAsFixed(0)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    setState(() { _isLoading = true; _message = ''; });

    // Simulate purchase processing
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isLoading = false);
    _setMsg('Purchase successful! ${package.totalCoins} Green Coins will be added shortly.', isError: false);
    
    // Reload wallet data
    await Future.delayed(const Duration(seconds: 1));
    await _loadData();
  }

  void _setMsg(String msg, {required bool isError}) =>
      setState(() { _message = msg; _msgIsError = isError; });

  int get _greenCoins => int.tryParse(_walletData['balances']?['greenCoins']?.toString() ?? '0') ?? 0;

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final bgColor     = isDark ? const Color(0xFF121212) : const Color(0xFFF8F0FF);
    final textColor   = isDark ? Colors.white : Colors.black87;
    final surfaceColor= isDark ? const Color(0xFF1E1E1E) : Colors.white;

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
                    // ── Status message ────────────────────────────────────
                    if (_message.isNotEmpty) _buildMessageBanner(),
                    const SizedBox(height: 8),

                    // ── Balance card ──────────────────────────────────────
                    _buildBalanceCard(surfaceColor, textColor, isDark),
                    const SizedBox(height: 24),

                    // ── Packages grid ─────────────────────────────────────
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
        color: isError
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
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
          // Coin icon
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/images/Green_Coin.png',
              width: 32, height: 32,
              errorBuilder: (_, __, ___) => Icon(
                Icons.eco_rounded,
                color: _kGreen,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Green Coins',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_greenCoins coins',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Available',
              style: TextStyle(
                color: _kGreen,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
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
        Text(
          'Buy Green Coins',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: textColor,
          ),
        ),
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
            _buildPackageCard(_packages[index], surface, textColor, isDark),
        ),
      ],
    );
  }

  Widget _buildPackageCard(_CoinPackage package, Color surface, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: _GradientBoxBorder(
          gradient: LinearGradient(colors: [_kGreen, _kGreen.withOpacity(0.7)]),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _kGreen.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Coin image
          Image.asset(
            'assets/images/Green_Coin.png',
            width: 40, height: 40,
            errorBuilder: (_, __, ___) => Icon(
              Icons.eco_rounded,
              color: _kGreen,
              size: 40,
            ),
          ),
          const SizedBox(height: 8),

          // Package name
          Text(
            package.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),

          // Coin amount
          Text(
            '${package.coinAmount}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: _kGreen,
            ),
          ),
          if (package.bonus > 0) ...[
            const SizedBox(height: 2),
            Text(
              '+${package.bonus}',
              style: TextStyle(
                fontSize: 10,
                color: _kGreen.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 6),

          // Price
          Text(
            'MUR ${package.price.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),

          // Buy button
          SizedBox(
            width: double.infinity,
            height: 28,
            child: ElevatedButton(
              onPressed: () => _purchasePackage(package),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              child: const Text('Buy'),
            ),
          ),
        ],
      ),
    );
  }
}