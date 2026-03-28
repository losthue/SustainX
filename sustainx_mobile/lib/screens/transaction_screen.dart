import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

// ── Shared palette ─────────────────────────────────────────────────────────
const _kPink   = Color(0xFFE91E8C);
const _kPurple = Color(0xFF9C27B0);
const _kGold   = Color(0xFFFFB300);

const _gradientColors = [_kPink, _kPurple];

// ── Gradient border (same helper as profile/leaderboard) ───────────────────
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
class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});
  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen>
    with SingleTickerProviderStateMixin {

  // controllers
  final _toUserController      = TextEditingController();
  final _greenAmountController  = TextEditingController(text: '0');
  final _noteController         = TextEditingController();

  // state
  bool          _isLoading = true;
  String        _message   = '';
  bool          _msgIsError = false;
  List<dynamic> _sent      = [];
  List<dynamic> _received  = [];

  // wallet info
  double _greenCoins = 0;
  double _redCoins   = 0;
  double _yellowCoins = 0;

  late TabController _tabController;
  bool _initialized = false;

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initialized = true;
    _loadTransactions();
  }

  @override
  void dispose() {
    _toUserController.dispose();
    _greenAmountController.dispose();
    _noteController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────
  Future<void> _loadTransactions() async {
    setState(() { _isLoading = true; _message = ''; });

    final sentRes     = await ApiService.getSentTransactions();
    final receivedRes = await ApiService.getReceivedTransactions();
    final walletRes   = await ApiService.getWalletBalance();

    if (walletRes['success'] == true) {
      final data = walletRes['data'] as Map<String, dynamic>?;
      setState(() {
        _greenCoins  = _toDouble(data?['green_coins']);
        _redCoins    = _toDouble(data?['red_coins']);
        _yellowCoins = _toDouble(data?['yellow_coins']);
      });
    }

    if (sentRes['success'] == true && receivedRes['success'] == true) {
      setState(() {
        _sent      = List.from(sentRes['data']     ?? []);
        _received  = List.from(receivedRes['data'] ?? []);
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading  = false;
      _message    = sentRes['message']?.toString() ??
                    receivedRes['message']?.toString() ??
                    'Unable to load transactions';
      _msgIsError = true;
    });
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _transferGreenCoins() async {
    final recipient = _toUserController.text.trim();
    final amount = double.tryParse(_greenAmountController.text.trim()) ?? 0;

    if (recipient.isEmpty) {
      _setMsg('Recipient user ID is required.', isError: true);
      return;
    }
    if (amount <= 0) {
      _setMsg('Enter a positive amount of green coins to transfer.', isError: true);
      return;
    }
    if (amount > _greenCoins) {
      _setMsg('Only ${_greenCoins.toStringAsFixed(0)} green coins available.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiService.transferGreenCoins(
      recipient,
      amount,
      note: _noteController.text.trim(),
    );
    if (res['success'] == true) {
      _greenAmountController.text = '0';
      _toUserController.clear();
      _noteController.clear();
      await _loadTransactions();
      _setMsg('Transferred ${amount.toStringAsFixed(0)} green coins to $recipient.', isError: false);
    } else {
      _setMsg(res['message']?.toString() ?? 'Transfer failed', isError: true);
      setState(() => _isLoading = false);
    }
  }


  void _setMsg(String msg, {required bool isError}) =>
      setState(() { _message = msg; _msgIsError = isError; });

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
            'Transactions',
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
              onRefresh: _loadTransactions,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Status message ────────────────────────────────────
                    if (_message.isNotEmpty) _buildMessageBanner(),
                    const SizedBox(height: 8),

                    // ── Transfer card ─────────────────────────────────────
                    _buildTransferCard(surfaceColor, textColor, isDark),
                    const SizedBox(height: 28),

                    // ── History tabs ──────────────────────────────────────
                    _buildHistorySection(surfaceColor, textColor, isDark),
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

  // ── Transfer card ─────────────────────────────────────────────────────────
  Widget _buildTransferCard(Color surface, Color textColor, bool isDark) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _gradientColors),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Send Green Coins',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Wallet status
          Row(
            children: [
              _balanceBadge('🟢 Green', _greenCoins, const Color(0xFF43A047)),
              const SizedBox(width: 8),
              _balanceBadge('🟡 Yellow', _yellowCoins, _kGold),
              const SizedBox(width: 8),
              _balanceBadge('🔴 Red', _redCoins, Colors.red),
            ],
          ),
          const SizedBox(height: 16),

          // Transfer green coins
          _buildActionRow(
            label: 'Amount',
            controller: _greenAmountController,
            buttonLabel: 'Send',
            onPressed: _transferGreenCoins,
            textColor: textColor,
            isDark: isDark,
            accentColor: const Color(0xFF43A047),
          ),
          const SizedBox(height: 16),

          // Recipient
          _buildTextField(
            controller:  _toUserController,
            label:       'Recipient User ID',
            hint:        'Enter user ID',
            icon:        Icons.person_search_rounded,
            textColor:   textColor,
            isDark:      isDark,
          ),
          const SizedBox(height: 16),

          // Note
          _buildTextField(
            controller:  _noteController,
            label:       'Note',
            hint:        'Optional message...',
            icon:        Icons.notes_rounded,
            textColor:   textColor,
            isDark:      isDark,
            maxLines:    2,
          ),
          const SizedBox(height: 12),

          // Auto-offset info
          if (_redCoins > 0)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have ${_redCoins.toStringAsFixed(0)} red coins debt. Green coins received will auto-offset your debt.',
                      style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.6)),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _balanceBadge(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              amount.toStringAsFixed(0),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required String label,
    required TextEditingController controller,
    required String buttonLabel,
    required VoidCallback onPressed,
    required Color textColor,
    required bool isDark,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1B1B1B) : const Color(0xFFF2F2F8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color  textColor,
    required bool   isDark,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
        const SizedBox(height: 6),
        TextField(
          controller:  controller,
          maxLines:    maxLines,
          style:       TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText:  hint,
            hintStyle: TextStyle(color: textColor.withOpacity(0.35)),
            prefixIcon: Icon(icon, size: 18, color: _kPink),
            filled:    true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.06)
                : _kPurple.withOpacity(0.04),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPink, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── History section ───────────────────────────────────────────────────────
  Widget _buildHistorySection(Color surface, Color textColor, bool isDark) {
    if (!_initialized) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),

        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : _kPurple.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller:     _tabController,
            indicator: BoxDecoration(
              gradient:      const LinearGradient(colors: _gradientColors),
              borderRadius:  BorderRadius.circular(12),
            ),
            indicatorSize:  TabBarIndicatorSize.tab,
            labelColor:     Colors.white,
            unselectedLabelColor: textColor.withOpacity(0.5),
            labelStyle:     const TextStyle(fontWeight: FontWeight.bold),
            dividerColor:   Colors.transparent,
            tabs: const [
              Tab(text: '  📤  Sent  '),
              Tab(text: '  📥  Received  '),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Tab content (not scrollable — embedded in outer scroll)
        AnimatedBuilder(
          animation: _tabController,
          builder: (_, __) {
            final list = _tabController.index == 0 ? _sent : _received;
            final isSent = _tabController.index == 0;
            if (list.isEmpty) {
              return _buildEmptyState(isSent, textColor);
            }
            return Column(
              children: list.asMap().entries.map((e) =>
                _buildTxCard(e.value as Map<String, dynamic>, isSent, surface, textColor, isDark),
              ).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isSent, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            isSent ? Icons.outbox_rounded : Icons.move_to_inbox_rounded,
            size: 52,
            color: textColor.withOpacity(0.18),
          ),
          const SizedBox(height: 12),
          Text(
            isSent
                ? 'No sent transactions yet.'
                : 'No received transactions yet.',
            style: TextStyle(
              color: textColor.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTxCard(
    Map<String, dynamic> tx,
    bool isSent,
    Color surface,
    Color textColor,
    bool isDark,
  ) {
    // New backend shape: sender_name, receiver_name, sender_id, receiver_id
    final counterparty = isSent
        ? (tx['receiver_name'] ?? tx['receiver_id'] ?? 'unknown').toString()
        : (tx['sender_name']   ?? tx['sender_id']   ?? 'unknown').toString();

    final date = tx['created_at']?.toString().split('T').first ?? '';
    final time = tx['created_at']?.toString().contains('T') == true
        ? tx['created_at'].toString().split('T').last.substring(0, 5)
        : '';

    final coinType = tx['coin_type']?.toString() ?? 'green';
    final amount   = double.tryParse(tx['amount']?.toString() ?? '0')?.round() ?? 0;
    final txType   = tx['transaction_type']?.toString() ?? '';
    final note     = tx['note']?.toString() ?? '';

    // Determine coin color + icon
    Color coinColor;
    String coinAsset;
    switch (coinType) {
      case 'green':
        coinColor = const Color(0xFF43A047);
        coinAsset = 'assets/images/Green_Coin.png';
        break;
      case 'red':
        coinColor = const Color(0xFFE53935);
        coinAsset = 'assets/images/Red_Coin.png';
        break;
      default:
        coinColor = const Color(0xFFFFB300);
        coinAsset = 'assets/images/Yellow_Coin.png';
        break;
    }

    // Build label
    String displayLabel;
    if (txType == 'mint') {
      displayLabel = 'Minted ($coinType)';
    } else if (txType == 'offset') {
      displayLabel = 'Offset ($coinType)';
    } else {
      displayLabel = isSent ? 'To $counterparty' : 'From $counterparty';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: _GradientBoxBorder(
          gradient: LinearGradient(
            colors: isSent
                ? [_kPink.withOpacity(0.7), _kPurple.withOpacity(0.7)]
                : [_kPurple.withOpacity(0.7), _kPink.withOpacity(0.7)],
          ),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Direction icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSent
                    ? [_kPink.withOpacity(0.15), _kPurple.withOpacity(0.15)]
                    : [_kPurple.withOpacity(0.15), _kPink.withOpacity(0.15)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSent
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: isSent ? _kPink : _kPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.45),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                // Coin chip
                if (amount > 0) _coinChip(coinAsset, amount, coinColor),
              ],
            ),
          ),

          // Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                date,
                style: TextStyle(
                  fontSize: 11,
                  color: textColor.withOpacity(0.45),
                ),
              ),
              if (time.isNotEmpty)
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withOpacity(0.3),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _coinChip(String asset, int amount, Color accent) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:        accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(asset, width: 16, height: 16,
            errorBuilder: (_, __, ___) => Icon(Icons.circle, color: accent, size: 16),
          ),
          const SizedBox(width: 4),
          Text(
            '$amount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}