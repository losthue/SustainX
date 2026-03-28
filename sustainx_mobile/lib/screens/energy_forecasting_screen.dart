import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ── Shared palette ─────────────────────────────────────────────────────────
const _kPink   = Color(0xFFE91E8C);
const _kPurple = Color(0xFF9C27B0);
const _kBlue   = Color(0xFF5B8CFF);
const _kGreen  = Color(0xFF43A047);
const _kOrange = Color(0xFFFF9800);
const _kRed    = Color(0xFFFF6B6B);

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
class _PricePoint {
  final String time;
  final double price;
  final double change;

  const _PricePoint({
    required this.time,
    required this.price,
    required this.change,
  });
}

class _ForecastData {
  final String label;
  final double production;  // kWh
  final double value;       // MUR
  final String recommendation;
  final Color color;

  const _ForecastData({
    required this.label,
    required this.production,
    required this.value,
    required this.recommendation,
    required this.color,
  });
}

class _TradeOpportunity {
  final String title;
  final String description;
  final String action;      // "BUY", "SELL", "HOLD"
  final double confidence;  // 0.0 - 1.0
  final String timeWindow;
  final int potentialGain;  // MUR

  const _TradeOpportunity({
    required this.title,
    required this.description,
    required this.action,
    required this.confidence,
    required this.timeWindow,
    required this.potentialGain,
  });
}

// ── Screen ─────────────────────────────────────────────────────────────────
class EnergyForecastingScreen extends StatefulWidget {
  const EnergyForecastingScreen({super.key});

  @override
  State<EnergyForecastingScreen> createState() => _EnergyForecastingScreenState();
}

class _EnergyForecastingScreenState extends State<EnergyForecastingScreen> {
  bool _isLoading = true;
  String _message = '';
  bool _msgIsError = false;
  Map<String, dynamic> _userData = {};
  late List<_PricePoint> _priceHistory;
  late List<_ForecastData> _forecasts;
  late List<_TradeOpportunity> _opportunities;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadData();
  }

  void _initializeData() {
    // Mock price history (7-day data)
    _priceHistory = [
      const _PricePoint(time: 'Mon', price: 45.2, change: 0),
      const _PricePoint(time: 'Tue', price: 46.8, change: 3.5),
      const _PricePoint(time: 'Wed', price: 44.5, change: -4.9),
      const _PricePoint(time: 'Thu', price: 47.3, change: 6.3),
      const _PricePoint(time: 'Fri', price: 49.1, change: 3.8),
      const _PricePoint(time: 'Sat', price: 48.5, change: -1.2),
      const _PricePoint(time: 'Sun', price: 51.2, change: 5.6),
    ];

    // Mock forecasts
    _forecasts = [
      const _ForecastData(
        label: 'Today',
        production: 15.8,
        value: 810.0,
        recommendation: 'Export to Grid',
        color: _kGreen,
      ),
      const _ForecastData(
        label: 'Tomorrow',
        production: 18.2,
        value: 965.0,
        recommendation: 'Maximize Export',
        color: _kOrange,
      ),
      const _ForecastData(
        label: 'Next 7 Days',
        production: 110.5,
        value: 5850.0,
        recommendation: 'Accumulate Coins',
        color: _kBlue,
      ),
    ];

    // Mock trade opportunities
    _opportunities = [
      const _TradeOpportunity(
        title: 'Peak Demand Window',
        description: 'Grid demand is highest 6 PM - 9 PM. Export energy during this window for +15% bonus.',
        action: 'SELL',
        confidence: 0.92,
        timeWindow: 'Today 6 PM - 9 PM',
        potentialGain: 450,
      ),
      const _TradeOpportunity(
        title: 'Price Recovery Expected',
        description: 'Market analysis shows coin price will rise by 8-12% due to increased demand.',
        action: 'HOLD',
        confidence: 0.85,
        timeWindow: 'Next 48 Hours',
        potentialGain: 380,
      ),
      const _TradeOpportunity(
        title: 'Grid Stability Bonus',
        description: 'System needs 20 MWh additional capacity. Early contributors get 10% reward boost.',
        action: 'BUY',
        confidence: 0.78,
        timeWindow: 'Next 12 Hours',
        potentialGain: 290,
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
            'AI Forecasting',
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

                    // ── Current Price ─────────────────────────────────────
                    _buildPriceCard(surfaceColor, textColor, isDark),
                    const SizedBox(height: 20),

                    // ── Price Chart ──────────────────────────────────────
                    _buildPriceChart(surfaceColor, textColor, isDark),
                    const SizedBox(height: 20),

                    // ── Forecasts ────────────────────────────────────────
                    _buildForecastsSection(surfaceColor, textColor, isDark),
                    const SizedBox(height: 24),

                    // ── Trade Opportunities ───────────────────────────────
                    _buildOpportunitiesSection(surfaceColor, textColor, isDark),
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

  // ── Current Price Card ────────────────────────────────────────────────────
  Widget _buildPriceCard(Color surface, Color textColor, bool isDark) {
    final currentPrice = _priceHistory.last;
    final change = currentPrice.change;
    final isUp = change >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isUp ? _kGreen.withOpacity(0.9) : _kRed.withOpacity(0.9),
            isUp ? _kGreen.withOpacity(0.6) : _kRed.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isUp ? _kGreen : _kRed).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EnergyCoins Market Price',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MUR ${currentPrice.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(Last 24h)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(
                isUp ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: 48,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Price Chart ───────────────────────────────────────────────────────────
  Widget _buildPriceChart(Color surface, Color textColor, bool isDark) {
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
          Text(
            '7-Day Price History',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ..._priceHistory.map((p) {
                  final maxPrice = _priceHistory.map((x) => x.price).reduce((a, b) => a > b ? a : b);
                  final minPrice = _priceHistory.map((x) => x.price).reduce((a, b) => a < b ? a : b);
                  final normalized = (p.price - minPrice) / (maxPrice - minPrice);
                  final height = 30 + (normalized * 50);

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: double.infinity,
                          height: height,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _kBlue.withOpacity(0.8),
                                _kBlue.withOpacity(0.3),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.time,
                          style: TextStyle(
                            fontSize: 9,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Forecasts Section ─────────────────────────────────────────────────────
  Widget _buildForecastsSection(Color surface, Color textColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Production & Value Forecast',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: _forecasts.map((f) => _buildForecastCard(f, surface, textColor, isDark)).toList(),
        ),
      ],
    );
  }

  Widget _buildForecastCard(_ForecastData forecast, Color surface, Color textColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: _GradientBoxBorder(
          gradient: LinearGradient(colors: [forecast.color, forecast.color.withOpacity(0.5)]),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: forecast.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.flash_on_rounded, color: forecast.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  forecast.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${forecast.production.toStringAsFixed(1)} kWh → MUR ${forecast.value.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: forecast.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  forecast.recommendation,
                  style: TextStyle(
                    fontSize: 10,
                    color: forecast.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Trade Opportunities Section ───────────────────────────────────────────
  Widget _buildOpportunitiesSection(Color surface, Color textColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trade Opportunities',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: _opportunities.map((opp) => _buildOpportunityCard(opp, surface, textColor, isDark)).toList(),
        ),
      ],
    );
  }

  Widget _buildOpportunityCard(_TradeOpportunity opp, Color surface, Color textColor, bool isDark) {
    final actionColor = opp.action == 'BUY'
        ? _kGreen
        : opp.action == 'SELL'
            ? _kOrange
            : _kBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: _GradientBoxBorder(
          gradient: LinearGradient(colors: [actionColor, actionColor.withOpacity(0.5)]),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  opp.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  opp.action,
                  style: TextStyle(
                    fontSize: 11,
                    color: actionColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            opp.description,
            style: TextStyle(
              fontSize: 11,
              color: textColor.withOpacity(0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confidence',
                    style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(opp.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: actionColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Window',
                    style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    opp.timeWindow,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Potential',
                    style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '+MUR ${opp.potentialGain}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _kGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
