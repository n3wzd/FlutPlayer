import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'dart:math';
import 'dart:typed_data';

import '../models/color.dart';
import '../app_state.dart';

class _RepaintNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class VisualizerController extends StatefulWidget {
  const VisualizerController({
    super.key,
    required this.widgetWidth,
    required this.widgetHeight,
  });
  final double widgetWidth;
  final double widgetHeight;

  @override
  State<VisualizerController> createState() => _VisualizerControllerState();
}

class _VisualizerControllerState extends State<VisualizerController>
    with SingleTickerProviderStateMixin {
  static const int _bandCount = 32;

  late final Ticker _ticker;
  AudioData? _audioData;
  final _repaint = _RepaintNotifier();

  final _smoothBands = List<double>.filled(_bandCount, 0.0);
  double _smoothBass = 0;
  double _smoothMid = 0;
  double _smoothHigh = 0;
  double _smoothRms = 0;
  double _beatPulse = 0;
  double _prevBass = 0;
  double _time = 0;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tryInitAudioData();
    _ticker = createTicker(_onTick)..start();
  }

  void _tryInitAudioData() {
    try {
      if (SoLoud.instance.isInitialized) {
        SoLoud.instance.setVisualizationEnabled(true);
        _audioData = AudioData(GetSamplesKind.linear);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    try {
      _audioData?.dispose();
    } catch (_) {}
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    _time += dt;

    if (!SoLoud.instance.isInitialized) return;

    if (_audioData == null) {
      _tryInitAudioData();
      return;
    }

    try {
      _audioData!.updateSamples();
      _processFFT(_audioData!.getAudioData());
      _repaint.notify();
    } catch (_) {}
  }

  void _processFFT(Float32List data) {
    if (data.length < 256) return;

    for (int b = 0; b < _bandCount; b++) {
      final startBin = (pow(127.0, b / _bandCount)).toInt().clamp(1, 126);
      final endBin = (pow(127.0, (b + 1) / _bandCount)).toInt().clamp(1, 127);
      double sum = 0;
      int count = 0;
      for (int i = startBin; i <= endBin; i++) {
        sum += data[i];
        count++;
      }
      final raw = count > 0 ? (sum / count).clamp(0.0, 1.0) : 0.0;
      final alpha = raw > _smoothBands[b] ? 0.75 : 0.12;
      _smoothBands[b] = _smoothBands[b] * (1 - alpha) + raw * alpha;
    }

    double bass = 0;
    for (int i = 1; i <= 8; i++) bass += data[i];
    bass = (bass / 8).clamp(0.0, 1.0);

    double mid = 0;
    for (int i = 9; i <= 40; i++) mid += data[i];
    mid = (mid / 32).clamp(0.0, 1.0);

    double high = 0;
    for (int i = 41; i < 128; i++) high += data[i];
    high = (high / 87).clamp(0.0, 1.0);

    final rms = (bass * 0.5 + mid * 0.3 + high * 0.2).clamp(0.0, 1.0);

    _smoothBass = _lerp(_smoothBass, bass, bass > _smoothBass ? 0.7 : 0.1);
    _smoothMid = _lerp(_smoothMid, mid, mid > _smoothMid ? 0.6 : 0.12);
    _smoothHigh = _lerp(_smoothHigh, high, high > _smoothHigh ? 0.6 : 0.15);
    _smoothRms = _lerp(_smoothRms, rms, rms > _smoothRms ? 0.6 : 0.12);

    final bassDelta = bass - _prevBass;
    if (bassDelta > 0.12) {
      _beatPulse = 1.0;
    } else {
      _beatPulse = (_beatPulse - 0.04).clamp(0.0, 1.0);
    }
    _prevBass = bass;
  }

  double _lerp(double a, double b, double t) => (a * (1 - t) + b * t).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final size = min(widget.widgetWidth, widget.widgetHeight);
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(size, size),
        painter: NcsVisualizerPainter(
          repaint: _repaint,
          bands: _smoothBands,
          rmsLevel: _smoothRms,
          bassLevel: _smoothBass,
          midLevel: _smoothMid,
          highLevel: _smoothHigh,
          beatPulse: _beatPulse,
          time: _time,
          color: stringToColor(AppState.instance.visualizerColor),
        ),
      ),
    );
  }
}

class NcsVisualizerPainter extends CustomPainter {
  NcsVisualizerPainter({
    required super.repaint,
    required this.bands,
    required this.rmsLevel,
    required this.bassLevel,
    required this.midLevel,
    required this.highLevel,
    required this.beatPulse,
    required this.time,
    required this.color,
  });

  final List<double> bands;
  final double rmsLevel;
  final double bassLevel;
  final double midLevel;
  final double highLevel;
  final double beatPulse;
  final double time;
  final Color color;

  static const int _ringPoints = 120;
  static const int _particleCount = 280;
  static const double _perspective = 2.2;

  final _rng = Random(42);

  // Pre-generated sphere point angles (stable across frames)
  static final List<(double theta, double phi)> _spherePoints = _genSpherePoints();

  static List<(double theta, double phi)> _genSpherePoints() {
    final rng = Random(1337);
    final pts = <(double theta, double phi)>[];
    for (int i = 0; i < _particleCount; i++) {
      final theta = rng.nextDouble() * 2 * pi;
      // Use arccos for uniform distribution on sphere
      final phi = acos(2 * rng.nextDouble() - 1) - pi / 2;
      pts.add((theta, phi));
    }
    return pts;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = min(cx, cy);

    final baseRadius = maxR * (0.48 + rmsLevel * 0.08);
    final rotY = time * 0.4; // Y-axis rotation

    // Beat ripple
    if (beatPulse > 0.01) {
      final rippleR = baseRadius + maxR * 0.18 * beatPulse;
      canvas.drawCircle(
        Offset(cx, cy),
        rippleR,
        Paint()
          ..color = color.withValues(alpha: beatPulse * 0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Glow behind ring
    final glowRadius = baseRadius + beatPulse * maxR * 0.06;
    canvas.drawCircle(
      Offset(cx, cy),
      glowRadius,
      Paint()
        ..color = color.withValues(alpha: 0.06 + rmsLevel * 0.08 + beatPulse * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // Sphere particles
    _drawSphereParticles(canvas, cx, cy, baseRadius * 0.72, rotY);

    // Deforming outer ring
    _drawDeformingRing(canvas, cx, cy, baseRadius, maxR);
  }

  void _drawSphereParticles(Canvas canvas, double cx, double cy, double sphereR, double rotY) {
    final deformBass = 1.0 + bassLevel * 0.10;
    final deformRms = 1.0 + rmsLevel * 0.08;

    for (int i = 0; i < _particleCount; i++) {
      final (theta, phi) = _spherePoints[i];

      // Apply Y-axis rotation
      final th = theta + rotY;

      // Slight high-freq shimmer per particle
      final shimmer = highLevel * 0.06 * sin(th * 3.7 + time * 6.0 + i * 0.31);

      final x3 = cos(phi) * cos(th);
      final y3 = sin(phi) + shimmer;
      final z3 = cos(phi) * sin(th);

      // Perspective projection
      final proj = _perspective / (_perspective - z3 * 0.5);
      final x2 = cx + x3 * sphereR * proj * deformBass * deformRms;
      final y2 = cy + y3 * sphereR * proj * deformBass * deformRms;

      // Depth-based brightness: front = bright, back = dim
      final depthT = (z3 + 1) / 2; // 0..1
      final alpha = 0.12 + depthT * 0.55 + rmsLevel * 0.15;
      final ptSize = (0.8 + depthT * 1.6) * (1.0 + bassLevel * 0.4);

      canvas.drawCircle(
        Offset(x2, y2),
        ptSize,
        Paint()..color = color.withValues(alpha: alpha.clamp(0.0, 0.9)),
      );
    }
  }

  void _drawDeformingRing(Canvas canvas, double cx, double cy, double baseR, double maxR) {
    final ringThickness = 3.0 + bassLevel * 6.0 + rmsLevel * 2.0;
    final n = _ringPoints;
    final path = Path();

    for (int i = 0; i <= n; i++) {
      final angle = (2 * pi * i / n) - pi / 2;

      // Band lookup: map angle to band index
      final bandIdx = ((i / n) * bands.length).floor().clamp(0, bands.length - 1);
      final bandVal = bands[bandIdx];

      // Low freq = big deform, mid = medium, high = fine ripple
      final deform =
          bassLevel * 14.0 * cos(angle * 2 + time * 1.2) +
          midLevel * 8.0 * cos(angle * 5 + time * 2.1) +
          highLevel * 3.5 * sin(angle * 12 + time * 5.0) +
          bandVal * 10.0 +
          beatPulse * 8.0 +
          sin(angle * 3 + time * 0.8) * 2.0; // idle gentle wave

      final r = baseR + deform;
      final x = cx + cos(angle) * r;
      final y = cy + sin(angle) * r;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Outer glow stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.25 + beatPulse * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringThickness + 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Core ring stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.85 + beatPulse * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringThickness
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(NcsVisualizerPainter old) => true;
}
