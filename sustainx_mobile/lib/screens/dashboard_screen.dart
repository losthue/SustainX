import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Colour tokens
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg         = Color(0xFFF4F6F9);
  static const card       = Color(0xFF12132D); // deep navy balance card
  static const violet     = Color(0xFF7C5CFC); // transfer card / accents
  static const violetSoft = Color(0xFFEDE9FF);
  static const green      = Color(0xFF3EC98E);
  static const greenSoft  = Color(0xFFE3FBF0);
  static const yellow     = Color(0xFFFFCC00);
  static const yellowSoft = Color(0xFFFFF8DC);
  static const red        = Color(0xFFFF6B6B);
  static const textDark   = Color(0xFF12132D);
  static const textMid    = Color(0xFF7A7F9A);
  static const white      = Colors.white;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _message = '';
  Map<String, dynamic> _walletData = {};

  final _sendController = TextEditingController();
  late final AnimationController _ringCtrl;
  late final Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic);
    _loadWallet();
  }

  @override
  void dispose() {
    _sendController.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getWalletInfo();
    if (result['success'] == true) {
      setState(() {
        _walletData = Map<String, dynamic>.from(result['data'] ?? {});
        _message    = '';
        _isLoading  = false;
      });
      _ringCtrl.forward(from: 0);
      return;
    }
    if (result['statusCode'] == 401) {
      await _logout();
      return;
    }
    setState(() {
      _message   = result['message']?.toString() ?? 'Unable to load wallet';
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await ApiService.clearAuth();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/auth');
  }

  // ── computed helpers ─────────────────────────────────────────
  String get _username    => _walletData['username']     ?? 'User';
  int    get _total       => _parseInt(_walletData['totalBalance'] ?? 0);
  Map    get _balances    => (_walletData['balances']    as Map?) ?? {};
  int    get _yellow      => _parseInt(_balances['yellowCoins']   ?? 0);
  int    get _green       => _parseInt(_balances['greenCoins']    ?? 0);
  int    get _red         => _parseInt(_balances['redCoins']      ?? 0);
  // export % = greenCoins / total (clamped 0-1)
  double get _exportRatio => _total > 0 ? (_green / _total).clamp(0.0, 1.0) : 0.0;
  int    get _exportCoins => ((_exportRatio) * _total).round();

  // ── type conversion helper ──────────────────────────────────
  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ── build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: _C.violet,
              onRefresh: _loadWallet,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildTopBar()),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (_message.isNotEmpty) _buildError(),
                        const SizedBox(height: 8),
                        _buildBalanceCard(),
                        const SizedBox(height: 20),
                        _buildTransferCard(),
                        const SizedBox(height: 20),
                        _buildCoinBreakdown(),
                        const SizedBox(height: 24),
                        _buildSendSection(),
                        const SizedBox(height: 24),
                        _buildHistoryHeader(),
                        const SizedBox(height: 12),
                        _buildHistoryList(),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── top bar ──────────────────────────────────────────────────
  Widget _buildTopBar() => SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: _iconBox(Icons.grid_view_rounded, _C.white),
                ),
              ),
              const Spacer(),
              const Text(
                'EnergyPass',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _C.textDark,
                  letterSpacing: -.3,
                ),
              ),
              const Spacer(),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _C.violet,
                    child: Text(
                      _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: _C.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: _C.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: _C.bg, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  // ── balance card ─────────────────────────────────────────────
  Widget _buildBalanceCard() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // date + dropdown
            Row(
              children: [
                const Icon(Icons.bolt_rounded, color: _C.yellow, size: 14),
                const SizedBox(width: 6),
                Text(
                  _currentPeriod(),
                  style: const TextStyle(color: _C.textMid, fontSize: 12),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: _C.white, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // total balance
            Text(
              _fmt(_total),
              style: const TextStyle(
                color: _C.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Total Yellow Coins',
              style: TextStyle(color: _C.textMid, fontSize: 13),
            ),
            const SizedBox(height: 20),
            // monthly export ring + figure
            Row(
              children: [
                AnimatedBuilder(
                  animation: _ringAnim,
                  builder: (_, __) => SizedBox(
                    width: 60, height: 60,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: _exportRatio * _ringAnim.value,
                        trackColor: Colors.white12,
                        fillColor:  _C.green,
                      ),
                      child: Center(
                        child: Text(
                          '${(_exportRatio * 100).round()}%',
                          style: const TextStyle(
                            color: _C.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Energy Export',
                      style: TextStyle(color: _C.textMid, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_fmt(_exportCoins)} ',
                      style: const TextStyle(
                        color: _C.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _pill('${(_exportRatio * 100).round()}%', _C.green),
              ],
            ),
          ],
        ),
      );

  // ── transfer card ────────────────────────────────────────────
  Widget _buildTransferCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C5CFC), Color(0xFF5B8CFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.bolt_rounded, color: _C.white, size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Amount Transferred this month',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  _fmt(_yellow),
                  style: const TextStyle(
                    color: _C.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // decorative wave
            SizedBox(
              width: 60, height: 40,
              child: CustomPaint(painter: _WavePainter()),
            ),
          ],
        ),
      );

  // ── coin breakdown ───────────────────────────────────────────
  Widget _buildCoinBreakdown() => Row(
        children: [
          Expanded(child: _coinTile('Solar', _green,   _C.green,  _C.greenSoft,  Icons.wb_sunny_rounded, imagePath: 'assets/images/Green_Coin.png')),
          const SizedBox(width: 12),
          Expanded(child: _coinTile('Grid',  _yellow,  _C.yellow, _C.yellowSoft, Icons.bolt_rounded, imagePath: 'assets/images/Yellow_Coin.png')),
          const SizedBox(width: 12),
          Expanded(child: _coinTile('Usage', _red,     _C.red,    const Color(0xFFFFEBEB), Icons.power_rounded, imagePath: 'assets/images/Red_Coin.png')),
        ],
      );

  Widget _coinTile(String label, int amount, Color accent, Color bg, IconData icon, {String? imagePath}) =>
      Container(
        height: 162,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (imagePath != null)
              Image.asset(imagePath, height: 60, width: 60, fit: BoxFit.cover)
            else
              Icon(icon, color: accent, size: 60),
            const SizedBox(height: 10),
            Text(
              _fmt(amount),
              style: TextStyle(
                color: accent,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: _C.textMid, fontSize: 12)),
          ],
        ),
      );

  // ── send section ─────────────────────────────────────────────
  Widget _buildSendSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Send EnergyCoins',
            style: TextStyle(
              color: _C.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: _C.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _sendController,
                    decoration: InputDecoration(
                      hintText: 'Search username…',
                      hintStyle: const TextStyle(color: _C.textMid, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: _C.textMid, size: 20),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/transactions'),
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C5CFC), Color(0xFF5B8CFF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: _C.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // quick-action chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _quickChip('Prediction', Icons.auto_awesome_rounded, '/prediction'),
                const SizedBox(width: 10),
                _quickChip('Forecasting', Icons.trending_up_rounded, '/forecasting'),
                const SizedBox(width: 10),
                _quickChip('Marketplace', Icons.shopping_cart_rounded, '/marketplace'),
              ],
            ),
          ),
        ],
      );

  Widget _quickChip(String label, IconData icon, String route) =>
      GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _C.violetSoft,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Icon(icon, color: _C.violet, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: _C.violet,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

  // ── transfer history ─────────────────────────────────────────
  Widget _buildHistoryHeader() => Row(
        children: [
          const Text(
            'Transfer History',
            style: TextStyle(
              color: _C.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/transactions'),
            child: const Text(
              'See all',
              style: TextStyle(color: _C.violet, fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );

  Widget _buildHistoryList() {
    // Build mock history from wallet address for display purposes;
    // real history comes from the transactions route.
    final walletAddress = _walletData['walletAddress']?.toString() ?? '';
    final energyScore   = _walletData['energyScore']  ?? 0;

    final items = [
      _HistoryItem(
        label:  'Energy Export Reward',
        sub:    _shortDate(DateTime.now().subtract(const Duration(days: 1))),
        amount: _exportCoins,
        icon:   Icons.wb_sunny_rounded,
        color:  _C.green,
        credit: true,
      ),
      _HistoryItem(
        label:  'Grid Purchase',
        sub:    _shortDate(DateTime.now().subtract(const Duration(days: 3))),
        amount: _yellow,
        icon:   Icons.bolt_rounded,
        color:  _C.yellow,
        credit: true,
      ),
      _HistoryItem(
        label:  'Consumption Deduction',
        sub:    _shortDate(DateTime.now().subtract(const Duration(days: 5))),
        amount: _red,
        icon:   Icons.power_rounded,
        color:  _C.red,
        credit: false,
      ),
    ];

    if (walletAddress.isEmpty && energyScore == 0 && _total == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No history yet', style: TextStyle(color: _C.textMid)),
        ),
      );
    }

    return Column(
      children: items.map(_buildHistoryTile).toList(),
    );
  }

  Widget _buildHistoryTile(_HistoryItem item) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: item.color.withOpacity(.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label,
                      style: const TextStyle(
                          color: _C.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(item.sub,
                      style: const TextStyle(color: _C.textMid, fontSize: 12)),
                ],
              ),
            ),
            Text(
              '${item.credit ? '+' : '-'}${_fmt(item.amount)} EC',
              style: TextStyle(
                color: item.credit ? _C.green : _C.red,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );

  // ── drawer ───────────────────────────────────────────────────
  Widget _buildDrawer() => Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _C.violet,
                      child: Text(
                        _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                        style: const TextStyle(
                            color: _C.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(_username,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _C.textDark)),
                    Text(_walletData['walletAddress']?.toString() ?? '',
                        style: const TextStyle(color: _C.textMid, fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              _drawerTile(Icons.auto_awesome_rounded, 'AI Prediction', '/prediction'),
              _drawerTile(Icons.trending_up_rounded, 'AI Forecasting', '/forecasting'),
              _drawerTile(Icons.swap_horiz_rounded, 'Transactions', '/transactions'),
              _drawerTile(Icons.emoji_events_rounded, 'Leaderboard', '/leaderboard'),
              _drawerTile(Icons.shopping_cart_rounded, 'Marketplace', '/marketplace'),
              _drawerTile(Icons.person_rounded, 'Profile', '/profile'),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: _logout,
                  child: Row(
                    children: const [
                      Icon(Icons.logout_rounded, color: _C.red),
                      SizedBox(width: 12),
                      Text('Log out',
                          style: TextStyle(
                              color: _C.red, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _drawerTile(IconData icon, String label, String route) =>
      ListTile(
        leading: Icon(icon, color: _C.violet),
        title: Text(label,
            style: const TextStyle(
                color: _C.textDark, fontWeight: FontWeight.w500)),
        onTap: () => Navigator.pushNamed(context, route),
      );

  // ── error banner ─────────────────────────────────────────────
  Widget _buildError() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.red.withOpacity(.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: _C.red, size: 18),
            const SizedBox(width: 10),
            Expanded(
                child: Text(_message,
                    style: const TextStyle(color: _C.red, fontSize: 13))),
          ],
        ),
      );

  // ── micro-widgets ────────────────────────────────────────────
  Widget _iconBox(IconData icon, Color color) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _C.textDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 18),
      );

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(.18),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );

  // ── utils ────────────────────────────────────────────────────
  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _currentPeriod() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Data model for history tiles
// ─────────────────────────────────────────────────────────────────────────────
class _HistoryItem {
  final String  label;
  final String  sub;
  final int     amount;
  final IconData icon;
  final Color   color;
  final bool    credit;
  const _HistoryItem({
    required this.label,
    required this.sub,
    required this.amount,
    required this.icon,
    required this.color,
    required this.credit,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Ring painter (export progress)
// ─────────────────────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color  trackColor;
  final Color  fillColor;
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = (size.width - 8) / 2;
    final stroke = 5.0;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    final trackPaint = Paint()
      ..color       = trackColor
      ..style       = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap   = StrokeCap.round;

    final fillPaint = Paint()
      ..color       = fillColor
      ..style       = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap   = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);
    if (progress > 0) {
      canvas.drawArc(
          rect, -math.pi / 2, math.pi * 2 * progress, false, fillPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Wave painter (decorative element on transfer card)
// ─────────────────────────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = Colors.white.withOpacity(.4)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap   = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(0, h * .6);
    path.cubicTo(w * .2, h * .2, w * .4, h * .9, w * .6, h * .4);
    path.cubicTo(w * .75, h * .05, w * .9, h * .55, w, h * .35);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter _) => false;
}