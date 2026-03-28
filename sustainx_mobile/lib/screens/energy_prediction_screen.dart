import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ── Shared palette ─────────────────────────────────────────────────────────
const _kPink   = Color(0xFFE91E8C);
const _kPurple = Color(0xFF9C27B0);
const _kBlue   = Color(0xFF5B8CFF);
const _kGreen  = Color(0xFF43A047);
const _kYellow = Color(0xFFFFCC00);
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
class EnergyPredictionScreen extends StatefulWidget {
  const EnergyPredictionScreen({super.key});

  @override
  State<EnergyPredictionScreen> createState() => _EnergyPredictionScreenState();
}

class _EnergyPredictionScreenState extends State<EnergyPredictionScreen> {
  bool _isLoading = true;
  String _message = '';
  bool _msgIsError = false;

  // Weather data
  Map<String, dynamic> _current = {};
  Map<String, dynamic> _currentRates = {};
  Map<String, dynamic> _baseRates = {};
  List<dynamic> _forecast = [];
  String _solarForecast = '';

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() { _isLoading = true; _message = ''; });

    final res = await ApiService.getWeatherForecast();

    if (res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _current      = Map<String, dynamic>.from(data['current'] ?? {});
        _currentRates = Map<String, dynamic>.from(data['current_rates'] ?? {});
        _baseRates    = Map<String, dynamic>.from(data['base_rates'] ?? {});
        _forecast     = List.from(data['forecast'] ?? []);
        _solarForecast = data['solar_forecast']?.toString() ?? '';
        _isLoading    = false;
      });
    } else {
      setState(() {
        _isLoading  = false;
        _message    = res['message']?.toString() ?? 'Unable to fetch weather';
        _msgIsError = true;
      });
    }
  }

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  IconData _weatherIcon(String? icon) {
    switch (icon) {
      case 'clear':         return Icons.wb_sunny_rounded;
      case 'partly_cloudy': return Icons.cloud_queue_rounded;
      case 'cloudy':        return Icons.cloud_rounded;
      case 'fog':           return Icons.foggy;
      case 'rain':          return Icons.water_drop_rounded;
      case 'snow':          return Icons.ac_unit_rounded;
      case 'showers':       return Icons.grain_rounded;
      case 'thunderstorm':  return Icons.flash_on_rounded;
      default:              return Icons.cloud_rounded;
    }
  }

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
              onRefresh: _loadWeather,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_message.isNotEmpty) _buildMessageBanner(),
                    const SizedBox(height: 8),

                    // Weather card
                    _buildWeatherCard(textColor),
                    const SizedBox(height: 20),

                    // Current rates card
                    _buildCurrentRatesCard(surfaceColor, textColor),
                    const SizedBox(height: 20),

                    // Line graph: Yellow coin rates
                    _buildRateGraph(
                      title: 'Yellow Coin Rate (7-day)',
                      color: _kYellow,
                      rateKey: 'yellow_rate',
                      baseRate: _toDouble(_baseRates['yellow'] ?? 1.0),
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 20),

                    // Line graph: Green coin rates
                    _buildRateGraph(
                      title: 'Green Coin Rate (7-day)',
                      color: _kGreen,
                      rateKey: 'green_rate',
                      baseRate: _toDouble(_baseRates['green'] ?? 0.5),
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 20),

                    // 7-day forecast strip
                    _buildForecastStrip(surfaceColor, textColor),
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

  // ── Weather Card ──────────────────────────────────────────────────────────
  Widget _buildWeatherCard(Color textColor) {
    final temp = _toDouble(_current['temperature']);
    final humidity = _toDouble(_current['humidity']).round();
    final wind = _toDouble(_current['wind_speed']);
    final desc = _current['weather_description']?.toString() ?? 'Unknown';
    final icon = _current['weather_icon']?.toString() ?? 'cloud';
    final multiplier = _toDouble(_current['solar_multiplier']);

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
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Weather · Mauritius',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(_weatherIcon(icon), color: Colors.white, size: 40),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${temp.toStringAsFixed(1)}°C',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Humidity: $humidity%',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Wind: ${wind.toStringAsFixed(1)} km/h',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '⚡ $_solarForecast',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Current Rates Card ────────────────────────────────────────────────────
  Widget _buildCurrentRatesCard(Color surface, Color textColor) {
    final yellowRate = _toDouble(_currentRates['yellow']);
    final greenRate  = _toDouble(_currentRates['green']);
    final yellowBase = _toDouble(_baseRates['yellow'] ?? 1.0);
    final greenBase  = _toDouble(_baseRates['green'] ?? 0.5);

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
          Text('Today\'s Adjusted Rates',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
          const SizedBox(height: 4),
          Text('Weather affects solar energy rarity → coin multipliers adjust',
              style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.5))),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _rateChip('🟡 Yellow', yellowRate, yellowBase, _kYellow)),
              const SizedBox(width: 12),
              Expanded(child: _rateChip('🟢 Green', greenRate, greenBase, _kGreen)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rateChip(String label, double rate, double base, Color color) {
    final boosted = rate > base;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 6),
          Text(
            '${rate.toStringAsFixed(2)}×',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 4),
          if (boosted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '↑ +${((rate - base) / base * 100).round()}% boost',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
              ),
            )
          else
            Text('Base rate', style: TextStyle(fontSize: 10, color: color.withOpacity(0.6))),
        ],
      ),
    );
  }

  // ── Line Graph Card ───────────────────────────────────────────────────────
  Widget _buildRateGraph({
    required String title,
    required Color color,
    required String rateKey,
    required double baseRate,
    required Color surfaceColor,
    required Color textColor,
  }) {
    final rates = _forecast.map((f) => _toDouble(f[rateKey])).toList();
    if (rates.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
              const Spacer(),
              Text(
                'Base: ${baseRate.toStringAsFixed(2)}×',
                style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.4)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineGraphPainter(
                values: rates,
                baseValue: baseRate,
                lineColor: color,
                labels: _forecast.map((f) {
                  final d = f['date']?.toString() ?? '';
                  return d.length >= 10 ? d.substring(5) : d; // "MM-DD"
                }).toList(),
                textColor: textColor.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min: ${rates.reduce(math.min).toStringAsFixed(2)}×',
                style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.5)),
              ),
              Text(
                'Max: ${rates.reduce(math.max).toStringAsFixed(2)}×',
                style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.5)),
              ),
              Text(
                'Avg: ${(rates.reduce((a, b) => a + b) / rates.length).toStringAsFixed(2)}×',
                style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 7-day Forecast Strip ──────────────────────────────────────────────────
  Widget _buildForecastStrip(Color surface, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('7-Day Forecast',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _forecast.map((f) {
              final date = f['date']?.toString() ?? '';
              final dayLabel = date.length >= 10 ? date.substring(5) : date;
              final icon = f['weather_icon']?.toString() ?? 'cloud';
              final tMax = _toDouble(f['temp_max']);
              final tMin = _toDouble(f['temp_min']);
              final yRate = _toDouble(f['yellow_rate']);
              final gRate = _toDouble(f['green_rate']);
              final multi = _toDouble(f['solar_multiplier']);
              final boosted = multi > 1.2;

              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: boosted ? _kYellow.withOpacity(0.5) : textColor.withOpacity(0.08),
                  ),
                ),
                child: Column(
                  children: [
                    Text(dayLabel,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 6),
                    Icon(_weatherIcon(icon), color: _kBlue, size: 24),
                    const SizedBox(height: 4),
                    Text('${tMax.round()}° / ${tMin.round()}°',
                        style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.6))),
                    const SizedBox(height: 8),
                    Text('🟡 ${yRate.toStringAsFixed(2)}×',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kYellow)),
                    const SizedBox(height: 2),
                    Text('🟢 ${gRate.toStringAsFixed(2)}×',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kGreen)),
                    if (boosted) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kYellow.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${multi.toStringAsFixed(1)}×',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _kYellow)),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Line Graph Painter ──────────────────────────────────────────────────────
class _LineGraphPainter extends CustomPainter {
  final List<double> values;
  final double baseValue;
  final Color lineColor;
  final List<String> labels;
  final Color textColor;

  _LineGraphPainter({
    required this.values,
    required this.baseValue,
    required this.lineColor,
    required this.labels,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final n = values.length;
    final minVal = values.reduce(math.min) - 0.1;
    final maxVal = values.reduce(math.max) + 0.1;
    final range = maxVal - minVal;

    final leftPad = 32.0;
    final bottomPad = 20.0;
    final graphW = size.width - leftPad;
    final graphH = size.height - bottomPad;

    // ─ Base rate dashed line ─
    final baseY = graphH - ((baseValue - minVal) / range) * graphH;
    final dashPaint = Paint()
      ..color = textColor.withOpacity(0.3)
      ..strokeWidth = 1;
    for (double x = leftPad; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, baseY), Offset(x + 4, baseY), dashPaint);
    }

    // Base label
    final baseTp = TextPainter(
      text: TextSpan(text: 'base', style: TextStyle(color: textColor, fontSize: 9)),
      textDirection: TextDirection.ltr,
    )..layout();
    baseTp.paint(canvas, Offset(0, baseY - 6));

    // ─ Points & line ─
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.3), lineColor.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(leftPad, 0, graphW, graphH));

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    for (int i = 0; i < n; i++) {
      final x = leftPad + (i / (n - 1)) * graphW;
      final y = graphH - ((values[i] - minVal) / range) * graphH;
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, graphH);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(leftPad + graphW, graphH);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // ─ Dots & labels ─
    final dotPaint = Paint()..color = lineColor;
    final dotBg = Paint()..color = Colors.white;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 5, dotBg);
      canvas.drawCircle(p, 3.5, dotPaint);

      // Value label
      final tp = TextPainter(
        text: TextSpan(
          text: values[i].toStringAsFixed(2),
          style: TextStyle(color: lineColor, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - 16));

      // Date label
      if (i < labels.length) {
        final dp = TextPainter(
          text: TextSpan(text: labels[i], style: TextStyle(color: textColor, fontSize: 9)),
          textDirection: TextDirection.ltr,
        )..layout();
        dp.paint(canvas, Offset(p.dx - dp.width / 2, graphH + 4));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
