import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ── Shared palette ─────────────────────────────────────────────────────────
const _kPink   = Color(0xFFE91E8C);
const _kPurple = Color(0xFF9C27B0);
const _kGreen  = Color(0xFF43A047);
const _kGold   = Color(0xFFFFB300);
const _kRed    = Color(0xFFE53935);

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
class EnergyRecordScreen extends StatefulWidget {
  const EnergyRecordScreen({super.key});

  @override
  State<EnergyRecordScreen> createState() => _EnergyRecordScreenState();
}

class _EnergyRecordScreenState extends State<EnergyRecordScreen> {
  final _importController = TextEditingController();
  final _exportController = TextEditingController();

  bool   _isLoading  = false;
  bool   _ratesLoaded = false;
  String _message    = '';
  bool   _msgIsError = false;

  // Conversion rates from backend (AI-adjusted)
  double _yellowRate  = 1.0;
  double _redRate     = 1.5;
  String _aiReasoning = '';
  String _weather     = '';

  // Past readings
  List<dynamic> _pastReadings = [];

  @override
  void initState() {
    super.initState();
    _loadRatesAndReadings();
  }

  @override
  void dispose() {
    _importController.dispose();
    _exportController.dispose();
    super.dispose();
  }

  int get _nextCycle {
    if (_pastReadings.isEmpty) return 1;
    int maxCycle = 0;
    for (final r in _pastReadings) {
      final c = int.tryParse(r['billing_cycle']?.toString() ?? '0') ?? 0;
      if (c > maxCycle) maxCycle = c;
    }
    return maxCycle + 1;
  }

  Future<void> _loadRatesAndReadings() async {
    setState(() => _isLoading = true);

    final ratesRes = await ApiService.getEnergyRates();
    if (ratesRes['success'] == true) {
      final data = ratesRes['data'] as Map<String, dynamic>?;
      if (data != null) {
        _yellowRate = _toDouble(data['yellow']?['rate'] ?? 1.0);
        _redRate    = _toDouble(data['red']?['rate'] ?? 1.5);
        _aiReasoning = data['ai_reasoning']?.toString() ?? '';
        _weather = data['weather']?.toString() ?? '';
        _ratesLoaded = true;
      }
    }

    final readingsRes = await ApiService.getEnergyReadings();
    if (readingsRes['success'] == true) {
      _pastReadings = List.from(readingsRes['data'] ?? []);
    }

    setState(() => _isLoading = false);
  }

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  // Computed preview values
  double get _importKwh => double.tryParse(_importController.text.trim()) ?? 0;
  double get _exportKwh => double.tryParse(_exportController.text.trim()) ?? 0;
  double get _netKwh    => _exportKwh - _importKwh;

  double get _previewYellow => _netKwh > 0 ? (_netKwh * _yellowRate) : 0;
  double get _previewRed    => _netKwh < 0 ? (_netKwh.abs() * _redRate) : 0;

  Future<void> _submitReading() async {
    if (_importKwh <= 0 && _exportKwh <= 0) {
      _setMsg('Enter at least one kWh value.', isError: true); return;
    }
    if (_importKwh < 0) {
      _setMsg('Import kWh cannot be negative.', isError: true); return;
    }
    if (_exportKwh < 0) {
      _setMsg('Export kWh cannot be negative.', isError: true); return;
    }

    final cycle = _nextCycle;
    setState(() { _isLoading = true; _message = ''; });

    final res = await ApiService.recordEnergy(_importKwh, _exportKwh, cycle);

    if (res['success'] == true) {
      // Auto-mint coins for this cycle
      final mintRes = await ApiService.generateCoinsForCycle(cycle);
      final mintOk = mintRes['success'] == true;

      _setMsg(
        mintOk
            ? 'Cycle $cycle recorded & coins minted! ✨'
            : 'Cycle $cycle recorded, but minting failed: ${mintRes['message'] ?? 'unknown error'}',
        isError: !mintOk,
      );
      _importController.clear();
      _exportController.clear();
      await _loadRatesAndReadings();
    } else {
      _setMsg(res['message']?.toString() ?? 'Failed to record energy', isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateCoins(int cycle) async {
    setState(() { _isLoading = true; _message = ''; });

    final res = await ApiService.generateCoinsForCycle(cycle);

    if (res['success'] == true) {
      final processed = res['data']?['users_processed'] ?? 0;
      _setMsg('Coins generated for cycle $cycle! ($processed users processed)', isError: false);
      await _loadRatesAndReadings();
    } else {
      _setMsg(res['message']?.toString() ?? 'Coin generation failed', isError: true);
      setState(() => _isLoading = false);
    }
  }

  void _setMsg(String msg, {required bool isError}) =>
      setState(() { _message = msg; _msgIsError = isError; });

  // ── Build ────────────────────────────────────────────────────────────────
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
            'Record Energy',
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
              onRefresh: _loadRatesAndReadings,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_message.isNotEmpty) _buildMessageBanner(),
                    const SizedBox(height: 8),

                    // Conversion rates info
                    _buildRatesCard(surfaceColor, textColor, isDark),
                    const SizedBox(height: 20),

                    // Input form
                    _buildInputCard(surfaceColor, textColor, isDark),
                    const SizedBox(height: 20),

                    // Preview
                    if (_importKwh > 0 || _exportKwh > 0)
                      _buildPreviewCard(surfaceColor, textColor, isDark),
                    if (_importKwh > 0 || _exportKwh > 0)
                      const SizedBox(height: 20),

                    // Past readings
                    _buildPastReadings(surfaceColor, textColor, isDark),
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

  // ── Rates card ────────────────────────────────────────────────────────────
  Widget _buildRatesCard(Color surface, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: _GradientBoxBorder(
          gradient: const LinearGradient(colors: _gradientColors),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI-Adjusted Rates',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
          if (_aiReasoning.isNotEmpty) ...[  
            const SizedBox(height: 4),
            Text('🤖 $_aiReasoning',
              style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.5)),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 10),
          _rateRow('🟡 Yellow', '${_yellowRate}× per kWh surplus', 'AI', _kGold, textColor),
          _rateRow('🔴 Red', '${_redRate}× per kWh deficit', 'AI', _kRed, textColor),
        ],
      ),
    );
  }

  Widget _rateRow(String coin, String rate, String type, Color color, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(coin, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(rate, style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(type, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Input card ────────────────────────────────────────────────────────────
  Widget _buildInputCard(Color surface, Color textColor, bool isDark) {
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
          BoxShadow(color: _kPink.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _gradientColors),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.electric_meter_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Record Monthly Reading',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _gradientColors),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Cycle #$_nextCycle',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _inputField(
            controller: _importController,
            label: 'Import kWh (from grid)',
            hint: 'e.g. 25',
            icon: Icons.download_rounded,
            textColor: textColor,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          _inputField(
            controller: _exportController,
            label: 'Export kWh (to grid)',
            hint: 'e.g. 40',
            icon: Icons.upload_rounded,
            textColor: textColor,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _gradientColors),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: _submitReading,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Submit Reading',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color textColor,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}), // trigger preview rebuild
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textColor.withOpacity(0.35)),
            prefixIcon: Icon(icon, size: 18, color: _kPink),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.06) : _kPurple.withOpacity(0.04),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
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

  // ── Preview card ──────────────────────────────────────────────────────────
  Widget _buildPreviewCard(Color surface, Color textColor, bool isDark) {
    final isSurplus = _netKwh > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSurplus ? _kGreen.withOpacity(0.5) : _kRed.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSurplus ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: isSurplus ? _kGreen : _kRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isSurplus ? 'Net Surplus: ${_netKwh.toStringAsFixed(1)} kWh' : 'Net Deficit: ${_netKwh.abs().toStringAsFixed(1)} kWh',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Coins you would earn:', style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6))),
          const SizedBox(height: 8),
          Row(
            children: [
              _previewCoinChip('🟡', _previewYellow, _kGold),
              const SizedBox(width: 8),
              _previewCoinChip('🔴', _previewRed, _kRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewCoinChip(String emoji, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              amount.toStringAsFixed(1),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // ── Past readings ─────────────────────────────────────────────────────────
  Widget _buildPastReadings(Color surface, Color textColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Past Readings',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor)),
        const SizedBox(height: 12),

        if (_pastReadings.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.electric_meter_outlined, size: 48, color: textColor.withOpacity(0.2)),
                  const SizedBox(height: 8),
                  Text('No readings recorded yet.', style: TextStyle(color: textColor.withOpacity(0.4))),
                ],
              ),
            ),
          )
        else
          ...(_pastReadings.map((r) {
            final reading = Map<String, dynamic>.from(r);
            final cycle   = reading['billing_cycle']?.toString() ?? '?';
            final imp     = _toDouble(reading['import_kwh']);
            final exp     = _toDouble(reading['export_kwh']);
            final net     = _toDouble(reading['net_kwh']);
            final isSurplus = net > 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: textColor.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isSurplus ? _kGreen.withOpacity(0.12) : _kRed.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '#$cycle',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isSurplus ? _kGreen : _kRed,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import: ${imp.toStringAsFixed(1)} · Export: ${exp.toStringAsFixed(1)}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Net: ${net.toStringAsFixed(1)} kWh',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSurplus ? _kGreen : _kRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Generate coins button
                  GestureDetector(
                    onTap: () => _generateCoins(int.parse(cycle)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: _gradientColors),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Mint',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList()),
      ],
    );
  }
}
