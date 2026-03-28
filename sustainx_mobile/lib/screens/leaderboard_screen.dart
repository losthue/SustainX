import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ── Palette (matches profile_screen gradient theme) ────────────────────────
const _kPink   = Color(0xFFE91E8C);
const _kPurple = Color(0xFF9C27B0);

const _kGold       = Color(0xFFFFD700);
const _kGoldLight  = Color(0xFFFFF3B0);
const _kSilver     = Color(0xFFC0C0C0);
const _kSilverLight= Color(0xFFEEEEEE);
const _kBronze     = Color(0xFFCD7F32);
const _kBronzeLight= Color(0xFFF5DEB3);

// ── Screen ─────────────────────────────────────────────────────────────────

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  bool          _loading     = true;
  String        _error       = '';
  List<dynamic> _leaderboard = [];

  late AnimationController _animController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _initialized = true;
    _fetchLeaderboard();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() { _loading = true; _error = ''; });

    final result = await ApiService.getLeaderboard();

    if (result['success'] == true) {
      setState(() {
        _leaderboard = List.from(result['data'] ?? []);
        _loading     = false;
      });
      _animController.forward(from: 0);
      return;
    }

    setState(() {
      _error   = result['message']?.toString() ?? 'Failed to load leaderboard';
      _loading = false;
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _entry(int i) =>
      i < _leaderboard.length ? (_leaderboard[i] as Map<String, dynamic>) : {};

  String _name(int i)  => _entry(i)['name']?.toString()   ?? 'N/A';
  int    _coins(int i) => (double.tryParse(
      _entry(i)['total_yellow']?.toString() ?? '0') ?? 0).round();
  int    _rank(int i)  => int.tryParse(
      _entry(i)['rank']?.toString() ?? '${i + 1}') ?? (i + 1);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF8F0FF);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [_kPink, _kPurple],
          ).createShader(r),
          child: Text(
            'Leaderboard',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _fetchLeaderboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    child: Column(
                      children: [
                        if (_leaderboard.isNotEmpty) _buildPodium(isDark, textColor),
                        if (_leaderboard.length > 3) ...[
                          const SizedBox(height: 24),
                          _buildTable(isDark, textColor),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchLeaderboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  // ── Podium ────────────────────────────────────────────────────────────────

  Widget _buildPodium(bool isDark, Color textColor) {
    // Layout: [2nd] [1st] [3rd]
    return SizedBox(
      height: 300,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          Expanded(child: _buildPodiumSlot(
            index:       1,
            podiumHeight: 80,
            crownColor:  _kSilver,
            glowColor:   _kSilver,
            labelColor:  _kSilverLight,
            isDark:      isDark,
            textColor:   textColor,
            delay:       0.15,
          )),
          // 1st place
          Expanded(child: _buildPodiumSlot(
            index:       0,
            podiumHeight: 130,
            crownColor:  _kGold,
            glowColor:   _kGold,
            labelColor:  _kGoldLight,
            isDark:      isDark,
            textColor:   textColor,
            delay:       0.0,
          )),
          // 3rd place
          Expanded(child: _buildPodiumSlot(
            index:       2,
            podiumHeight: 60,
            crownColor:  _kBronze,
            glowColor:   _kBronze,
            labelColor:  _kBronzeLight,
            isDark:      isDark,
            textColor:   textColor,
            delay:       0.3,
          )),
        ],
      ),
    );
  }

  Widget _buildPodiumSlot({
    required int    index,
    required double podiumHeight,
    required Color  crownColor,
    required Color  glowColor,
    required Color  labelColor,
    required bool   isDark,
    required Color  textColor,
    required double delay,
  }) {
    if (index >= _leaderboard.length) return const SizedBox.shrink();

    final rankNum = index + 1;

    final slideAnim = !_initialized ? AlwaysStoppedAnimation(Offset.zero) : Tween<Offset>(
      begin: const Offset(0, 0.6),
      end:   Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve:  Interval(delay, delay + 0.55, curve: Curves.easeOutCubic),
    ));

    final fadeAnim = !_initialized ? const AlwaysStoppedAnimation(1.0) : Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve:  Interval(delay, delay + 0.55, curve: Curves.easeIn),
      ),
    );

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Crown icon
            Icon(Icons.workspace_premium_rounded, color: crownColor, size: 22),
            const SizedBox(height: 2),

            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(0.5),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: rankNum == 1 ? 28 : 20,
                backgroundColor: crownColor,
                child: Text(
                  _name(index).isNotEmpty ? _name(index)[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: rankNum == 1 ? 18 : 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),

            // Username
            Text(
              _name(index),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: rankNum == 1 ? 13 : 11,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 1),

            // Coin count
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monetization_on_rounded, color: crownColor, size: 11),
                const SizedBox(width: 2),
                Text(
                  '${_coins(index)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: crownColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),

            // Podium block
            Container(
              height: podiumHeight,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                  colors: [
                    crownColor.withOpacity(isDark ? 0.75 : 0.9),
                    crownColor.withOpacity(isDark ? 0.4  : 0.55),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: crownColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '#$rankNum',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Table for 4th+ ────────────────────────────────────────────────────────

  Widget _buildTable(bool isDark, Color textColor) {
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _kPink.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kPink, _kPurple]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: const [
                SizedBox(width: 36, child: Text('#',        style: _headerStyle)),
                Expanded(         child: Text('Player',     style: _headerStyle)),
                SizedBox(width: 90,child: Text('Coins',     style: _headerStyleRight)),
              ],
            ),
          ),

          // Rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _leaderboard.length - 3,
            itemBuilder: (context, i) {
              final actualIndex = i + 3;
              final isEven      = i.isEven;
              final rankNum     = _rank(actualIndex);

              return AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final t = Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: _animController,
                      curve: Interval(
                        (0.4 + i * 0.05).clamp(0.0, 0.95),
                        (0.7 + i * 0.05).clamp(0.05, 1.0),
                        curve: Curves.easeOut,
                      ),
                    ),
                  );
                  return Opacity(
                    opacity: t.value,
                    child: child,
                  );
                },
                child: Container(
                  color: isEven
                      ? (isDark
                          ? Colors.white.withOpacity(0.03)
                          : Colors.grey.withOpacity(0.04))
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Rank badge
                      SizedBox(
                        width: 36,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kPurple.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$rankNum',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _kPurple,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Avatar + name
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: _kPink.withOpacity(0.15),
                        child: Text(
                          _name(actualIndex).isNotEmpty
                              ? _name(actualIndex)[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _kPink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _name(actualIndex),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Coins
                      SizedBox(
                        width: 90,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.monetization_on_rounded,
                                color: _kGold, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              '${_coins(actualIndex)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Bottom padding
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontSize: 13,
  letterSpacing: 0.5,
);

const _headerStyleRight = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontSize: 13,
  letterSpacing: 0.5,
);