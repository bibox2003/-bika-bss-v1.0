import 'dart:math';
import 'package:flutter/material.dart';

class IotSnapshot {
  final double temperatureC; // e.g. 18 - 35
  final double humidityPct; // 0 - 100
  final double airQualityIdx; // 0 - 500 (AQI-like)
  final double noiseDb; // 20 - 100
  final double lightLux; // 0 - 1000+
  final DateTime updatedAt;

  IotSnapshot({
    required this.temperatureC,
    required this.humidityPct,
    required this.airQualityIdx,
    required this.noiseDb,
    required this.lightLux,
    required this.updatedAt,
  });

  static IotSnapshot mock({int? seed}) {
    final r = Random(seed ?? DateTime.now().millisecondsSinceEpoch);
    return IotSnapshot(
      temperatureC: 18 + r.nextDouble() * 14, // 18..32
      humidityPct: 35 + r.nextDouble() * 45, // 35..80
      airQualityIdx: 30 + r.nextDouble() * 140, // 30..170
      noiseDb: 30 + r.nextDouble() * 35, // 30..65
      lightLux: 80 + r.nextDouble() * 700, // 80..780
      updatedAt: DateTime.now(),
    );
  }
}

class IotPreviewSection extends StatelessWidget {
  final IotSnapshot snapshot;
  final VoidCallback onRefresh;

  const IotPreviewSection({
    super.key,
    required this.snapshot,
    required this.onRefresh,
  });

  String _fmt1(double v) => v.toStringAsFixed(1);
  String _fmt0(double v) => v.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sensors_outlined),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'IoT Metrics (Preview)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
                TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Mock refresh'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Live sensor streaming will replace these mock values once the IoT device is integrated.',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                IotMetricCard(
                  title: 'Temperature',
                  value: '${_fmt1(snapshot.temperatureC)} °C',
                  icon: Icons.thermostat_outlined,
                  progress: _clamp01((snapshot.temperatureC - 10) / 30),
                  trendSeed: snapshot.updatedAt.millisecondsSinceEpoch + 1,
                ),
                IotMetricCard(
                  title: 'Humidity',
                  value: '${_fmt0(snapshot.humidityPct)}%',
                  icon: Icons.water_drop_outlined,
                  progress: _clamp01(snapshot.humidityPct / 100),
                  trendSeed: snapshot.updatedAt.millisecondsSinceEpoch + 2,
                ),
                IotMetricCard(
                  title: 'Air Quality',
                  value: '${_fmt0(snapshot.airQualityIdx)} AQI',
                  icon: Icons.air_outlined,
                  progress: _clamp01(snapshot.airQualityIdx / 200),
                  trendSeed: snapshot.updatedAt.millisecondsSinceEpoch + 3,
                ),
                IotMetricCard(
                  title: 'Noise',
                  value: '${_fmt0(snapshot.noiseDb)} dB',
                  icon: Icons.graphic_eq_outlined,
                  progress: _clamp01(snapshot.noiseDb / 100),
                  trendSeed: snapshot.updatedAt.millisecondsSinceEpoch + 4,
                ),
                IotMetricCard(
                  title: 'Light',
                  value: '${_fmt0(snapshot.lightLux)} lux',
                  icon: Icons.light_mode_outlined,
                  progress: _clamp01(snapshot.lightLux / 1000),
                  trendSeed: snapshot.updatedAt.millisecondsSinceEpoch + 5,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Last updated: ${snapshot.updatedAt.toLocal()}',
                    style: TextStyle(color: Theme.of(context).hintColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  double _clamp01(double v) => v.clamp(0.0, 1.0);
}

class IotMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final double progress; // 0..1
  final int trendSeed;

  const IotMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.progress,
    required this.trendSeed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 26,
                width: double.infinity,
                child: _MiniSparkline(seed: trendSeed),
              ),
              const SizedBox(height: 4),
              Text(
                'Live trend (soon)',
                style:
                    TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  final int seed;
  const _MiniSparkline({required this.seed});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(
        seed: seed,
        strokeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final int seed;
  final Color strokeColor;

  _SparklinePainter({
    required this.seed,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(seed);
    final points = List<double>.generate(18, (_) => r.nextDouble());

    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - (points[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.seed != seed || oldDelegate.strokeColor != strokeColor;
  }
}
