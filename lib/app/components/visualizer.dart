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
  double _smoothRms = 0;
  double _beatPulse = 0;
  double _prevBass = 0;

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

    // Compress FFT bins 1..127 into log-scaled bands (skip DC at 0)
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

    // Bass: bins 1-8
    double bass = 0;
    for (int i = 1; i <= 8; i++) {
      bass += data[i];
    }
    bass = (bass / 8).clamp(0.0, 1.0);

    // Mid: bins 9-40
    double mid = 0;
    for (int i = 9; i <= 40; i++) {
      mid += data[i];
    }
    mid = (mid / 32).clamp(0.0, 1.0);

    // High: bins 41-127
    double high = 0;
    for (int i = 41; i < 128; i++) {
      high += data[i];
    }
    high = (high / 87).clamp(0.0, 1.0);

    final rms = (bass * 0.5 + mid * 0.3 + high * 0.2).clamp(0.0, 1.0);

    final bassAlpha = bass > _smoothBass ? 0.7 : 0.1;
    _smoothBass = (_smoothBass * (1 - bassAlpha) + bass * bassAlpha).clamp(0.0, 1.0);

    final rmsAlpha = rms > _smoothRms ? 0.6 : 0.12;
    _smoothRms = (_smoothRms * (1 - rmsAlpha) + rms * rmsAlpha).clamp(0.0, 1.0);

    final bassDelta = bass - _prevBass;
    if (bassDelta > 0.12) {
      _beatPulse = 1.0;
    } else {
      _beatPulse = (_beatPulse - 0.04).clamp(0.0, 1.0);
    }
    _prevBass = bass;
  }

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
          beatPulse: _beatPulse,
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
    required this.beatPulse,
    required this.color,
  });

  final List<double> bands;
  final double rmsLevel;
  final double bassLevel;
  final double beatPulse;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = min(cx, cy);

    final baseRadius = maxR * (0.52 + rmsLevel * 0.08);
    final borderWidth = 3.0 + rmsLevel * 4.0;

    // Beat ripple behind everything
    if (beatPulse > 0.01) {
      final rippleR = baseRadius + maxR * 0.18 * beatPulse;
      canvas.drawCircle(
        Offset(cx, cy),
        rippleR,
        Paint()
          ..color = color.withValues(alpha: beatPulse * 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // Radial bars
    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    final n = bands.length;
    final innerEdge = baseRadius + borderWidth / 2 + 3;
    final maxBarLen = maxR * 0.38;

    for (int i = 0; i < n; i++) {
      final barLen = maxBarLen * bands[i];
      if (barLen < 1.0) continue;
      final angle = (2 * pi * i / n) - pi / 2;
      final cosA = cos(angle);
      final sinA = sin(angle);
      canvas.drawLine(
        Offset(cx + cosA * innerEdge, cy + sinA * innerEdge),
        Offset(cx + cosA * (innerEdge + barLen), cy + sinA * (innerEdge + barLen)),
        barPaint,
      );
    }

    // Circle border on top
    canvas.drawCircle(
      Offset(cx, cy),
      baseRadius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  @override
  bool shouldRepaint(NcsVisualizerPainter old) => true;
}
