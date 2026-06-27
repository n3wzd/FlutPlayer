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
  // NCS-style pulse: instead of the absolute bass level (which on bass-heavy
  // tracks sits near 1.0 the whole time and looks static), the pulse measures
  // the bass *relative* to an adaptive window — a slow floor (the quiet level
  // between kicks) and a slow peak (the loudest recent kick). The current bass
  // is remapped into that window, so the pulse always swings the full 0..1 on
  // every kick regardless of how loud the track is overall.
  double _pulse = 0;
  double _bassFloor = 0; // adaptive quiet baseline (rises slowly, drops fast)
  double _bassPeak = 0.2; // adaptive recent peak (snaps up, decays slowly)
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
    for (int i = 1; i <= 8; i++) {
      bass += data[i];
    }
    bass = (bass / 8).clamp(0.0, 1.0);

    double mid = 0;
    for (int i = 9; i <= 40; i++) {
      mid += data[i];
    }
    mid = (mid / 32).clamp(0.0, 1.0);

    double high = 0;
    for (int i = 41; i < 128; i++) {
      high += data[i];
    }
    high = (high / 87).clamp(0.0, 1.0);

    final rms = (bass * 0.5 + mid * 0.3 + high * 0.2).clamp(0.0, 1.0);

    _smoothBass = _lerp(_smoothBass, bass, bass > _smoothBass ? 0.7 : 0.1);
    _smoothMid = _lerp(_smoothMid, mid, mid > _smoothMid ? 0.6 : 0.12);
    _smoothHigh = _lerp(_smoothHigh, high, high > _smoothHigh ? 0.6 : 0.15);
    _smoothRms = _lerp(_smoothRms, rms, rms > _smoothRms ? 0.7 : 0.4);

    // Adaptive window: track the quiet baseline (floor) and the recent loudest
    // kick (peak). The floor drops instantly to new lows and rises slowly; the
    // peak snaps up to new highs and decays slowly. This auto-calibrates to the
    // track's loudness so the pulse stays dynamic instead of pinned near max.
    _bassFloor = bass < _bassFloor ? bass : _lerp(_bassFloor, bass, 0.01);
    _bassPeak = bass > _bassPeak ? bass : _lerp(_bassPeak, bass, 0.012);
    final span = _bassPeak - _bassFloor;
    // Remap current bass into [floor, peak]. The guard avoids amplifying noise
    // when there's no real dynamic range (near-silence or steady tone).
    final norm = span > 0.06
        ? ((bass - _bassFloor) / span).clamp(0.0, 1.0)
        : 0.0;

    // Bass-level envelope: fast attack so it snaps up on the kick, moderate
    // release so it eases back down between hits. The pow curve keeps the pulse
    // low between kicks so the kick itself reads as a sharp swell.
    final target = pow(norm, 1.8).toDouble();
    _pulse = target > _pulse
        ? _lerp(_pulse, target, 0.3) // snappier attack on the kick
        : _lerp(_pulse, target, 0.5); // fast release back to baseline
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

  // Ring tessellation. Per-angle values are precomputed into these reusable
  // buffers each frame (once), then shared across all strands — the strands
  // only do cheap arithmetic, not trig. Buffers are allocated once (steps is
  // constant) to avoid per-frame garbage.
  static const int _ringSteps = 160;
  static const int _ringStrands = 44;
  static final Float64List _rCos = Float64List(_ringSteps + 1); // cos(angle)
  static final Float64List _rSin = Float64List(_ringSteps + 1); // sin(angle)
  static final Float64List _rWid = Float64List(_ringSteps + 1); // band-width factor
  static final Float64List _wave = Float64List(_ringSteps + 1); // traveling-crest height ∈ [0,1]

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
    final limitSq = limit * limit;
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
      // Compare squared distances so sqrt only runs for the few that exceed it.
      final d2 = ox * ox + oy * oy;
      if (d2 > limitSq) {
        final k = limit / sqrt(d2);
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
    final fl = flow; // pulse-driven phase — moves the whole wave coherently
    // Max inward reach of the wave. The idle term keeps a gentle living ripple;
    // the beat term lets the strongest kicks drive a crest all the way to — and
    // past — the centre. baseR is the distance to the centre, so a depth ≥ baseR
    // means that crest crosses it and emerges on the far side (a "sphere").
    final waveDepth = baseR * (0.10 + beatPulse * 1.05) + rmsLevel * maxR * 0.08;

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

    // Precompute per-angle values once per frame: cos/sin, the band-width
    // factor, and the traveling-crest HEIGHT FIELD. The wave is a few swells
    // that all circulate at the same angular speed, so the pattern keeps its
    // shape as it travels — a coherent flow, not spikes popping at random
    // positions. Sharpening localises each crest: one side lifts and its
    // neighbours tremble, while the troughs stay calm.
    for (int i = 0; i <= _ringSteps; i++) {
      final a = (i / _ringSteps) * 2 * pi;
      _rCos[i] = cos(a);
      _rSin[i] = sin(a);
      // Band-width modulation (gentle), all terms drifting the same way so the
      // band breathes with the flow instead of churning. Clamp pow base ≥ 0.
      final v = sin(a * 2 - fl) * 0.62 +
          sin(a * 3 - fl * 1.5 + 1.7) * 0.26 +
          sin(a * 5 - fl * 2.5 + 0.6) * 0.12;
      final base = (0.5 + 0.5 * v).clamp(0.0, 1.0);
      _rWid[i] = 0.28 + 0.72 * pow(base, 1.4).toDouble();
      // Height field ∈ [0,1]: two swells travel around together (cos(2a - fl));
      // the cube sharpens them into localised crests so the lift is concentrated
      // and falls away smoothly to either side. A fine ripple rides the crest
      // for surface trembling.
      final g = (cos(a * 2 - fl) + 1) * 0.5;
      final crest = g * g * g;
      final tremble = sin(a * 9 - fl * 3 + 1.1) * 0.12 * crest;
      _wave[i] = (crest + tremble).clamp(0.0, 1.0);
    }

    for (int s = 0; s < _ringStrands; s++) {
      final t = s / (_ringStrands - 1.0); // 0 = outer (at baseR) .. 1 = inner
      final bwt = bandW * t; // band-width contribution for this strand
      // Inner strands ride the crest far more than outer ones, so at a crest the
      // band fans inward into a spike pointing at the centre; outer strands barely
      // move, holding the ring's outer edge steady.
      final rip = waveDepth * (0.08 + 0.92 * t);
      final path = Path();
      for (int i = 0; i <= _ringSteps; i++) {
        // The wave only ever pushes INWARD (toward the centre); on a strong beat
        // the crest can pass the centre and surface on the opposite side. Clamp at
        // -baseR so it never pokes back outside the circle on that far side.
        var r = baseR - bwt * _rWid[i] - rip * _wave[i];
        if (r < -baseR) r = -baseR;
        final x = cx + _rCos[i] * r;
        final y = cy + _rSin[i] * r;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
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
