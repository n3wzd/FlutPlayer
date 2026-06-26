import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'dart:math';
import 'dart:typed_data';

import '../models/color.dart';
import '../app_state.dart';
import '../utils/audio_manager.dart';

/// Live, mutable animation state. The painter reads these fields directly so
/// values stay current every tick without rebuilding the widget.
class _VizModel extends ChangeNotifier {
  List<double> bands = const [];
  double rmsLevel = 0;
  double bassLevel = 0;
  double midLevel = 0;
  double highLevel = 0;
  double beatPulse = 0;
  double time = 0;
  double spin = 0;
  Color color = const Color(0xFFFFFFFF);
  String debug = ''; // TEMP: live calibration readout
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
  final _model = _VizModel();

  final _smoothBands = List<double>.filled(_bandCount, 0.0);
  double _smoothBass = 0;
  double _smoothMid = 0;
  double _smoothHigh = 0;
  double _smoothRms = 0;
  // NCS-style pulse: bass spans the full 0..1 range (measured), so the pulse is
  // a plain bass-level envelope — fast attack on the kick, moderate release
  // between hits. No gain (that only saturated and pinned it at max).
  double _pulse = 0;
  double _time = 0;

  // TEMP calibration stats — running min/max of the raw features while playing.
  double _bassMin = 1, _bassMax = 0, _rmsMin = 1, _rmsMax = 0;
  double _spin = 0; // rotation phase; only advances while audio plays
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
    _model.dispose();
    try {
      _audioData?.dispose();
    } catch (_) {}
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    _time += dt;

    bool playing = false;
    try {
      playing = AudioManager.instance.isPlaying;
    } catch (_) {}

    if (playing && SoLoud.instance.isInitialized) {
      if (_audioData == null) {
        _tryInitAudioData();
      } else {
        try {
          _audioData!.updateSamples();
          _processFFT(_audioData!.getAudioData());
        } catch (_) {}
      }
    } else {
      // Paused/stopped: decay everything to zero so the visual settles into a
      // calm, motionless circle.
      _decay();
    }

    // Rotation only progresses while actually playing → frozen when paused.
    // Speed is NOT constant and direction is NOT fixed: a slow sine flips the
    // spin direction over time, while the magnitude surges on the beat and rides
    // the FFT energy — so the sphere accelerates, eases, and reverses.
    if (playing) {
      final dir = sin(_time * 0.4); // smoothly swings between -1 and +1
      _spin += dt * dir * (_smoothRms * 1.8 + _pulse * 6.0);
    }

    // Push live values into the model and repaint every tick. Reading from a
    // shared mutable object keeps the painter current without rebuilding.
    _model
      ..bands = _smoothBands
      ..rmsLevel = _smoothRms
      ..bassLevel = _smoothBass
      ..midLevel = _smoothMid
      ..highLevel = _smoothHigh
      ..beatPulse = _pulse
      ..time = _time
      ..spin = _spin
      ..color = stringToColor(AppState.instance.visualizerColor)
      ..notify();
  }

  void _decay() {
    const k = 0.80;
    for (int b = 0; b < _bandCount; b++) {
      _smoothBands[b] *= k;
    }
    _smoothBass *= k;
    _smoothMid *= k;
    _smoothHigh *= k;
    _smoothRms *= k;
    _pulse *= k;
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
    _smoothRms = _lerp(_smoothRms, rms, rms > _smoothRms ? 0.7 : 0.4);

    // Bass-level envelope: fast attack so it snaps up on the kick, moderate
    // release so it eases back down between hits. The pow(>1) curve compresses
    // the top so only the strongest kicks approach 1.0 — mid/high bass sits
    // lower, so the pulse isn't near max so often.
    final target = pow(bass, 1.6).toDouble();
    _pulse = target > _pulse
        ? _lerp(_pulse, target, 0.5) // fast attack
        : _lerp(_pulse, target, 0.28); // faster release

    // TEMP calibration: record live ranges of the raw features.
    _bassMin = min(_bassMin, bass);
    _bassMax = max(_bassMax, bass);
    _rmsMin = min(_rmsMin, rms);
    _rmsMax = max(_rmsMax, rms);
    _model.debug =
        'bass ${bass.toStringAsFixed(2)} [${_bassMin.toStringAsFixed(2)}-${_bassMax.toStringAsFixed(2)}]\n'
        'rms  ${rms.toStringAsFixed(2)} [${_rmsMin.toStringAsFixed(2)}-${_rmsMax.toStringAsFixed(2)}]\n'
        'pulse ${_pulse.toStringAsFixed(2)}';
  }

  double _lerp(double a, double b, double t) => (a * (1 - t) + b * t).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final size = min(widget.widgetWidth, widget.widgetHeight);
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(size, size),
        painter: NcsVisualizerPainter(_model),
      ),
    );
  }
}

class NcsVisualizerPainter extends CustomPainter {
  NcsVisualizerPainter(this.m) : super(repaint: m);

  final _VizModel m;

  List<double> get bands => m.bands;
  double get rmsLevel => m.rmsLevel;
  double get bassLevel => m.bassLevel;
  double get midLevel => m.midLevel;
  double get highLevel => m.highLevel;
  double get beatPulse => m.beatPulse;
  double get time => m.time;
  double get spin => m.spin;
  Color get color => m.color;

  static const int _particleCount = 420;
  static const double _perspective = 2.6;

  // Pre-generated unit-sphere points via Fibonacci lattice (even, structured).
  static final List<(double x, double y, double z)> _spherePoints = _genSpherePoints();

  static List<(double x, double y, double z)> _genSpherePoints() {
    final pts = <(double x, double y, double z)>[];
    const golden = pi * (3 - 1.4142135623730951); // golden angle approx
    for (int i = 0; i < _particleCount; i++) {
      final y = 1 - (i / (_particleCount - 1)) * 2; // 1 -> -1
      final r = sqrt(max(0.0, 1 - y * y));
      final theta = golden * i;
      pts.add((cos(theta) * r, y, sin(theta) * r));
    }
    return pts;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = min(cx, cy);

    // Circle SIZE pumps with the bass pulse (NCS-style): small between kicks,
    // expanding on the kick. beatPulse is the bass envelope follower.
    final baseRadius = maxR * (0.66 + beatPulse * 0.26);
    final rotY = spin; // audio-driven Y-axis rotation (still when silent)

    // Sphere particles (behind the ring)
    _drawSphereParticles(canvas, cx, cy, baseRadius * 0.86, rotY);

    // Clean glowing outline (matches the reference look)
    _drawRing(canvas, cx, cy, baseRadius, maxR);

    // TEMP calibration overlay.
    if (m.debug.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: m.debug,
          style: const TextStyle(color: Color(0xFF00FF66), fontSize: 11, height: 1.3),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, const Offset(6, 6));
    }
  }

  void _drawSphereParticles(Canvas canvas, double cx, double cy, double sphereR, double rotY) {
    // Audio pushes the whole sphere outward (breathing).
    final push = 1.0 + bassLevel * 0.14 + rmsLevel * 0.07 + beatPulse * 0.28;
    final cosY = cos(rotY);
    final sinY = sin(rotY);
    // Fixed 3/4 view tilt (no idle motion).
    const cosX = 0.9492312651760538; // cos(0.32)
    const sinX = 0.31456656061611776; // sin(0.32)

    for (int i = 0; i < _particleCount; i++) {
      final (px, py, pz) = _spherePoints[i];

      // Rotate around Y axis.
      final rx = px * cosY + pz * sinY;
      final rz = -px * sinY + pz * cosY;
      // Rotate around X axis (fixed tilt) for a 3/4 view.
      final ry = py * cosX - rz * sinX;
      final rz2 = py * sinX + rz * cosX;

      // High-freq shimmer nudges points radially.
      final shimmer = 1.0 + highLevel * 0.05 * sin(time * 7.0 + i * 0.7);

      // Perspective projection (front points spread wider).
      final proj = _perspective / (_perspective - rz2);
      final scale = sphereR * proj * push * shimmer;
      final x2 = cx + rx * scale;
      final y2 = cy + ry * scale;

      // Depth: front (rz2 > 0) bright & large, back dim & small.
      final depthT = ((rz2 + 1) / 2).clamp(0.0, 1.0); // 0..1
      final alpha = (0.08 + pow(depthT, 1.7) * 0.85 + rmsLevel * 0.10).clamp(0.0, 1.0);
      final ptSize = (0.3 + depthT * depthT * 1.0) * (1.0 + bassLevel * 0.35 + beatPulse * 2.6);

      canvas.drawCircle(
        Offset(x2, y2),
        ptSize,
        Paint()..color = color.withValues(alpha: alpha.toDouble()),
      );
    }
  }

  void _drawRing(Canvas canvas, double cx, double cy, double baseR, double maxR) {
    final c = Offset(cx, cy);
    final thickness = maxR * 0.022 + rmsLevel * maxR * 0.018 + beatPulse * maxR * 0.012;

    // Soft outer halo.
    canvas.drawCircle(
      c,
      baseR,
      Paint()
        ..color = color.withValues(alpha: 0.18 + rmsLevel * 0.12 + beatPulse * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness + maxR * 0.10
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, maxR * 0.06),
    );

    // Inner glow.
    canvas.drawCircle(
      c,
      baseR,
      Paint()
        ..color = color.withValues(alpha: 0.45 + beatPulse * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness + maxR * 0.025
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, maxR * 0.02),
    );

    // Bright crisp core ring.
    canvas.drawCircle(
      c,
      baseR,
      Paint()
        ..color = color.withValues(alpha: (0.9 + beatPulse * 0.1).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness,
    );
  }

  @override
  bool shouldRepaint(NcsVisualizerPainter old) => true;
}
