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

// ── Coin config ────────────────────────────────────────────────────────────
class _CoinConfig {
  const _CoinConfig({
    required this.label,
    required this.asset,
    required this.accent,
    required this.controller,
  });
  final String label;
  final String asset;
  final Color  accent;
  final TextEditingController controller;
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
  final _toUserController    = TextEditingController();
  final _yellowController    = TextEditingController(text: '0');
  final _greenController     = TextEditingController(text: '0');
  final _redController       = TextEditingController(text: '0');
  final _noteController      = TextEditingController();

  // state
  bool          _isLoading = true;
  String        _message   = '';
  bool          _msgIsError = false;
  List<dynamic> _sent      = [];
  List<dynamic> _received  = [];

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
    _yellowController.dispose();
    _greenController.dispose();
    _redController.dispose();
    _noteController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────
  Future<void> _loadTransactions() async {
    setState(() { _isLoading = true; _message = ''; });

    final sentRes     = await ApiService.getSentTransactions();
    final receivedRes = await ApiService.getReceivedTransactions();

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

  Future<void> _sendCoins() async {
    final toUserId = _toUserController.text.trim();
    if (toUserId.isEmpty) {
      _setMsg('Recipient user ID is required.', isError: true);
      return;
    }

    final yellow = int.tryParse(_yellowController.text) ?? 0;
    final green  = int.tryParse(_greenController.text)  ?? 0;
    final red    = int.tryParse(_redController.text)    ?? 0;

    if (yellow + green + red == 0) {
      _setMsg('Please enter at least one coin amount.', isError: true);
      return;
    }

    setState(() { _isLoading = true; _message = ''; });

    final res = await ApiService.transferCoins(
      toUserId,
      yellowCoins: yellow,
      greenCoins:  green,
      redCoins:    red,
      note:        _noteController.text.trim(),
    );

    if (res['success'] == true) {
      _toUserController.clear();
      _yellowController.text = '0';
      _greenController.text  = '0';
      _redController.text    = '0';
      _noteController.clear();
      await _loadTransactions();
      _setMsg('Transfer completed successfully!', isError: false);
    } else {
      setState(() => _isLoading = false);
      _setMsg(res['message']?.toString() ?? 'Transfer failed.', isError: true);
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
    final coins = [
      _CoinConfig(
        label:      'Yellow',
        asset:      'assets/images/Yellow_Coin.png',
        accent:     const Color(0xFFFFB300),
        controller: _yellowController,
      ),
      _CoinConfig(
        label:      'Green',
        asset:      'assets/images/Green_Coin.png',
        accent:     const Color(0xFF43A047),
        controller: _greenController,
      ),
      _CoinConfig(
        label:      'Red',
        asset:      'assets/images/Red_Coin.png',
        accent:     const Color(0xFFE53935),
        controller: _redController,
      ),
    ];

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
                'Send Coins',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

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

          // Coin inputs
          Row(
            children: coins.map((c) =>
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: c.label != 'Red' ? 10 : 0,
                  ),
                  child: _buildCoinInput(c, textColor, isDark),
                ),
              ),
            ).toList(),
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
          const SizedBox(height: 20),

          // Send button
          SizedBox(
            height: 50,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _gradientColors),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _kPink.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor:     Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _sendCoins,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text(
                  'Send Coins',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinInput(_CoinConfig coin, Color textColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Coin image
        Image.asset(coin.asset, width: 42, height: 42),
        const SizedBox(height: 6),
        Text(
          coin.label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: coin.accent,
          ),
        ),
        const SizedBox(height: 6),
        // +/- stepper
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : coin.accent.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: coin.accent.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stepperBtn(
                icon:    Icons.remove,
                color:   coin.accent,
                onTap: () {
                  final val = int.tryParse(coin.controller.text) ?? 0;
                  if (val > 0) coin.controller.text = '${val - 1}';
                },
              ),
              Expanded(
                child: TextField(
                  controller:  coin.controller,
                  keyboardType: TextInputType.number,
                  textAlign:   TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                  decoration: const InputDecoration(
                    border:      InputBorder.none,
                    isDense:     true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              _stepperBtn(
                icon:  Icons.add,
                color: coin.accent,
                onTap: () {
                  final val = int.tryParse(coin.controller.text) ?? 0;
                  coin.controller.text = '${val + 1}';
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepperBtn({
    required IconData icon,
    required Color    color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Icon(icon, size: 16, color: color),
      ),
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
    final counterparty = isSent
        ? (tx['toUser']   ?? tx['toUserId']   ?? 'unknown').toString()
        : (tx['fromUser'] ?? tx['fromUserId'] ?? 'unknown').toString();

    final date = tx['createdAt']?.toString().split('T').first ?? '';
    final time = tx['createdAt']?.toString().contains('T') == true
        ? tx['createdAt'].toString().split('T').last.substring(0, 5)
        : '';

    final yellow = int.tryParse(tx['yellowCoins']?.toString() ?? '0') ?? 0;
    final green  = int.tryParse(tx['greenCoins']?.toString()  ?? '0') ?? 0;
    final red    = int.tryParse(tx['redCoins']?.toString()    ?? '0') ?? 0;
    final note   = tx['note']?.toString() ?? '';

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
                Row(
                  children: [
                    Text(
                      isSent ? 'To ' : 'From ',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      counterparty,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ],
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
                // Coin chips
                Row(
                  children: [
                    if (yellow > 0) _coinChip('assets/images/Yellow_Coin.png', yellow, const Color(0xFFFFB300)),
                    if (green  > 0) _coinChip('assets/images/Green_Coin.png',  green,  const Color(0xFF43A047)),
                    if (red    > 0) _coinChip('assets/images/Red_Coin.png',    red,    const Color(0xFFE53935)),
                  ],
                ),
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
          Image.asset(asset, width: 16, height: 16),
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