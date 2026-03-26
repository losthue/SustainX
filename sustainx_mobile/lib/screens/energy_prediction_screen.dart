import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/api_service.dart';

// ── Shared palette ─────────────────────────────────────────────────────────
const _kPink   = Color(0xFFE91E8C);
const _kPurple = Color(0xFF9C27B0);
const _kBlue   = Color(0xFF5B8CFF);
const _kGreen  = Color(0xFF43A047);
const _kOrange = Color(0xFFFF9800);
const _kYellow = Color(0xFFFFCC00);

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

// ── Models ─────────────────────────────────────────────────────────────────
class _EnergyPrediction {
  final String period;      // "Today", "This Week", "This Month"
  final double predicted;   // Predicted kWh
  final double historical;  // Historical average
  final String trend;       // "up", "down", "stable"

  const _EnergyPrediction({
    required this.period,
    required this.predicted,
    required this.historical,
    required this.trend,
  });
}

class _EnergySavingTip {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final double potentialSavings; // MUR per month

  const _EnergySavingTip({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.potentialSavings,
  });
}

// ── Screen ─────────────────────────────────────────────────────────────────
class EnergyPredictionScreen extends StatefulWidget {
  const EnergyPredictionScreen({super.key});

  @override
  State<EnergyPredictionScreen> createState() => _EnergyPredictionScreenState();
}

class _EnergyPredictionScreenState extends State<EnergyPredictionScreen> {
  bool _isLoading = true;
  String _message = '';
  bool _msgIsError = false;
  Map<String, dynamic> _userData = {};
  late List<_EnergyPrediction> _predictions;
  late List<_EnergySavingTip> _tips;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadData();
  }

  void _initializeData() {
    // Mock predictions data
    _predictions = [
      const _EnergyPrediction(
        period: 'Today',
        predicted: 12.5,
        historical: 11.2,
        trend: 'up',
      ),
      const _EnergyPrediction(
        period: 'This Week',
        predicted: 78.3,
        historical: 75.4,
        trend: 'up',
      ),
      const _EnergyPrediction(
        period: 'This Month',
        predicted: 310.0,
        historical: 298.5,
        trend: 'stable',
      ),
    ];

    // Mock energy-saving tips
    _tips = [
      const _EnergySavingTip(
        title: 'Optimize AC Usage',
        description: 'Based on weather, reduce AC by 2°C during off-peak hours (10 PM - 6 AM).',
        icon: Icons.air_rounded,
        color: _kBlue,
        potentialSavings: 150,
      ),
      const _EnergySavingTip(
        title: 'Peak Hours Shift',
        description: 'Shift laundry & dishwashing to 11 PM - 6 AM for lower rates.',
        icon: Icons.local_laundry_service_rounded,
        color: _kOrange,
        potentialSavings: 200,
      ),
      const _EnergySavingTip(
        title: 'LED Upgrade',
        description: 'Replace remaining incandescent bulbs with LED (80% energy reduction).',
        icon: Icons.lightbulb_rounded,
        color: _kYellow,
        potentialSavings: 120,
      ),
      const _EnergySavingTip(
        title: 'Solar Production Peak',
        description: 'Use high-draw appliances between 9 AM - 4 PM when solar is strongest.',
        icon: Icons.wb_sunny_rounded,
        color: _kGreen,
        potentialSavings: 180,
      ),
    ];
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _message = ''; });

    final result = await ApiService.getWalletInfo();

    if (result['success'] == true) {
      setState(() {
        _userData = Map<String, dynamic>.from(result['data'] ?? {});
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading  = false;
      _message    = result['message']?.toString() ?? 'Unable to load data';
      _msgIsError = true;
    });
  }

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
            'Energy Prediction',
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

                    // ── Weather & Forecast ────────────────────────────────
                    _buildWeatherCard(surfaceColor, textColor, isDark),
                    const SizedBox(height: 20),

                    // ── Predictions ───────────────────────────────────────
                    _buildPredictionsSection(surfaceColor, textColor, isDark),
                    const SizedBox(height: 24),

                    // ── AI Tips ────────────────────────────────────────────
                    _buildTipsSection(surfaceColor, textColor, isDark),
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

  // ── Weather & Forecast Card ───────────────────────────────────────────────
  Widget _buildWeatherCard(Color surface, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Weather Forecast',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Partly Cloudy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Icon(Icons.cloud_rounded, color: Colors.white, size: 40),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '28°C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Humidity: 65%',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Wind: 12 km/h',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '⚡ Low solar production expected',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Predictions Section ───────────────────────────────────────────────────
  Widget _buildPredictionsSection(Color surface, Color textColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Energy Predictions',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: _predictions.map((pred) => _buildPredictionCard(pred, surface, textColor, isDark)).toList(),
        ),
      ],
    );
  }

  Widget _buildPredictionCard(_EnergyPrediction pred, Color surface, Color textColor, bool isDark) {
    final isUp = pred.trend == 'up';
    final diff = pred.predicted - pred.historical;
    final color = isUp ? Colors.orange : _kGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: _GradientBoxBorder(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.5)]),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pred.period,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: color,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isUp ? '+' : ''}${diff.toStringAsFixed(1)} kWh',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Predicted',
                    style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pred.predicted.toStringAsFixed(1)} kWh',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historical Avg',
                    style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pred.historical.toStringAsFixed(1)} kWh',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 60,
                height: 36,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (pred.predicted / 400).clamp(0.0, 1.0),
                    minHeight: 36,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── AI Tips Section ───────────────────────────────────────────────────────
  Widget _buildTipsSection(Color surface, Color textColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI-Powered Recommendations',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: _tips.map((tip) => _buildTipCard(tip, surface, textColor, isDark)).toList(),
        ),
      ],
    );
  }

  Widget _buildTipCard(_EnergySavingTip tip, Color surface, Color textColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: _GradientBoxBorder(
          gradient: LinearGradient(
            colors: [tip.color, tip.color.withOpacity(0.5)],
          ),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: tip.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tip.icon, color: tip.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tip.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Save',
                style: TextStyle(
                  fontSize: 10,
                  color: textColor.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'MUR ${tip.potentialSavings.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: tip.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
