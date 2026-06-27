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
  double flow = 0; // ring-wave phase (pulse-driven)
  Color color = const Color(0xFFFFFFFF);
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
  double _flow = 0; // ring-wave phase
  double _flowVel = 0; // ring-wave angular velocity; eases toward a pulse target
  double _time = 0;
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
    // Speed is driven PURELY by the audio: it rides the FFT energy and surges on
    // the kick. No time-based oscillation — every change reflects the data.
    if (playing) {
      _spin += dt * (_smoothRms * 2.2 + _pulse * 5.0);
      // Ring flow uses an eased VELOCITY rather than a speed set straight from
      // the pulse: the velocity ramps toward a pulse-driven target, so the wave
      // accelerates and decelerates instead of sliding at a constant speed.
      final targetVel = _pulse * 7.0; // slightly slower than before
      _flowVel += (targetVel - _flowVel) * 0.05; // inertia → accel/decel
      _flow += dt * _flowVel;
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
      ..flow = _flow
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
        ? _lerp(_pulse, target, 0.2) // less sensitive attack
        : _lerp(_pulse, target, 0.45); // fast release
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
  double get flow => m.flow;
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

    // Sphere particles (behind the ring), kept clamped inside it.
    _drawSphereParticles(canvas, cx, cy, baseRadius * 0.66, rotY, baseRadius);

    // Clean glowing outline (matches the reference look)
    _drawRing(canvas, cx, cy, baseRadius, maxR);
  }

  void _drawSphereParticles(
      Canvas canvas, double cx, double cy, double sphereR, double rotY, double ringR) {
    // Audio pushes the whole sphere outward (breathing).
    final push = 1.0 + bassLevel * 0.14 + rmsLevel * 0.07 + beatPulse * 0.18;
    // Keep every particle strictly inside the ring.
    final limit = ringR * 0.95;
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
      double ox = rx * scale;
      double oy = ry * scale;
      // Clamp the projected offset so particles never spill outside the ring.
      final d = sqrt(ox * ox + oy * oy);
      if (d > limit) {
        final k = limit / d;
        ox *= k;
        oy *= k;
      }
      final x2 = cx + ox;
      final y2 = cy + oy;

      // Depth: front (rz2 > 0) bright & large, back dim & small.
      final depthT = ((rz2 + 1) / 2).clamp(0.0, 1.0); // 0..1
      final alpha = (0.08 + pow(depthT, 1.7) * 0.85 + rmsLevel * 0.10).clamp(0.0, 1.0);
      final ptSize = (0.18 + depthT * depthT * 0.6) * (1.0 + bassLevel * 0.25 + beatPulse * 0.7);

      canvas.drawCircle(
        Offset(x2, y2),
        ptSize,
        Paint()..color = color.withValues(alpha: alpha.toDouble()),
      );
    }
  }

  void _drawRing(Canvas canvas, double cx, double cy, double baseR, double maxR) {
    // The ring is a thick band of fine light STRANDS flowing around the circle —
    // this is what gives the reference its fibrous, liquid-flowing look (most
    // visible on the left edge). Each strand is a wavy circle; stacked across
    // the band they form a glowing ring whose inner edge ripples. The flow is
    // driven by `spin` (a pure audio accumulator), so it streams with the music
    // and speeds up with the pulse. Strand brightness varies → non-uniform.
    final bandW = maxR * (0.045 + rmsLevel * 0.02 + beatPulse * 0.025);
    final amp = maxR * (0.014 + rmsLevel * 0.02 + beatPulse * 0.024); // much taller ripple
    final fl = flow; // pulse-driven phase
    const strands = 44;
    const steps = 160;

    // Band THICKNESS varies around the ring and travels with the flow, so the
    // band is fatter in some places, thinner in others (non-uniform width). Two
    // mismatched frequencies make the variation irregular/organic rather than a
    // tidy repeating pattern.
    double widthAt(double a) {
      // Non-harmonic frequencies moving at different speeds → irregular,
      // non-repeating thickness that never looks evenly spread.
      // Several integer harmonics (seamless loop) with mismatched speeds AND
      // phase offsets so peaks never line up → gentle but very irregular humps.
      final v = sin(a * 2 - fl + 0.0) * 0.62 +
          sin(a * 3 + fl * 0.8 + 1.7) * 0.26 +
          sin(a * 5 - fl * 1.2 + 0.6) * 0.12; // -1..1
      // Clamp the base: pow() of a negative number with a fractional exponent is
      // NaN, which would corrupt the path and make the ring flicker/vanish.
      final base = (0.5 + 0.5 * v).clamp(0.0, 1.0);
      return 0.28 + 0.72 * pow(base, 1.4).toDouble();
    }

    // Soft outer bloom (one fat blurred stroke) — the neon glow.
    canvas.drawCircle(
      Offset(cx, cy),
      baseR - bandW * 0.5,
      Paint()
        ..color = color.withValues(alpha: 0.22 + beatPulse * 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = bandW * 2.2
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, maxR * 0.05),
    );

    for (int s = 0; s < strands; s++) {
      final t = s / (strands - 1.0); // 0 = outer (at baseR) .. 1 = inner
      final phase = s * 0.16; // SMALL spread → fibers stay parallel (coherent band)
      final path = Path();
      for (int i = 0; i <= steps; i++) {
        final a = (i / steps) * 2 * pi;
        // Per-angle band width (flowing) pushes the inner strands in/out, and a
        // small shared ripple adds fiber texture.
        final w = sin(a * 2 - fl + phase + 0.0) * 0.62 +
            sin(a * 3 + fl * 1.2 - phase + 2.1) * 0.26 +
            sin(a * 5 - fl * 0.6 + 1.1) * 0.12;
        // Inner strands (t→1) ripple far more violently; outer strands barely.
        final r = baseR - bandW * t * widthAt(a) + amp * w * (0.2 + 1.6 * t);
        final p = Offset(cx + cos(a) * r, cy + sin(a) * r);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      // Brightest mid-band, fading to both edges; plus a little audio lift.
      final core = (1.0 - (t - 0.4).abs() * 1.6).clamp(0.0, 1.0);
      final alpha = (0.08 + core * 0.5 + beatPulse * 0.1).clamp(0.0, 0.9);
      // Outer strands are thicker, inner strands thinner.
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = maxR * (0.0035 + (1 - t) * 0.016),
      );
    }
  }

  @override
  bool shouldRepaint(NcsVisualizerPainter old) => true;
}
