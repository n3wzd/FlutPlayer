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
  double rmsLevel = 0;
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
  late final Ticker _ticker;
  AudioData? _audioData;
  final _model = _VizModel();

  double _smoothRms = 0;
  // Cache the parsed visualizer color so the string isn't re-parsed (int.parse
  // + Color allocation) on every tick — it only changes when the user picks a
  // new color.
  String _lastColorString = '';
  Color _color = const Color(0xFFFFFFFF);
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

    // Re-parse the color only when the user actually changed it.
    final colorString = AppState.instance.visualizerColor;
    if (colorString != _lastColorString) {
      _lastColorString = colorString;
      _color = stringToColor(colorString);
    }

    // Push live values into the model and repaint every tick. Reading from a
    // shared mutable object keeps the painter current without rebuilding.
    _model
      ..rmsLevel = _smoothRms
      ..beatPulse = _pulse
      ..time = _time
      ..spin = _spin
      ..flow = _flow
      ..color = _color
      ..notify();
  }

  void _decay() {
    const k = 0.80;
    _smoothRms *= k;
    _pulse *= k;
  }

  void _processFFT(Float32List data) {
    if (data.length < 256) return;

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
        ? _lerp(_pulse, target, 0.22) // attack on the kick (slightly eased)
        : _lerp(_pulse, target, 0.35); // release back to baseline (slightly eased)
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

  double get rmsLevel => m.rmsLevel;
  double get beatPulse => m.beatPulse;
  double get time => m.time;
  double get spin => m.spin;
  double get flow => m.flow;
  Color get color => m.color;

  static const double _perspective = 2.6;

  // Dotted mesh sphere: a lat/lon grid of points on a sphere, wave-deformed so
  // the surface drapes and flows. Projected as small glowing DOTS — the rows
  // read as the flowing mesh of the reference graphic. cos/sin of each latitude
  // (rows, pole-to-pole) and longitude (columns, around) are constant, so they
  // are precomputed once.
  // Dense ALONG each meridian (rows), sparse BETWEEN meridians (cols): the rows
  // of close dots read as flowing lines, the gaps between columns keep the lines
  // distinct. This is what makes the wave lines visible (vs a uniform dot grid).
  static const int _sphereRows = 40; // latitude divisions (dots along a meridian)
  static const int _sphereCols = 22; // longitude divisions (meridian lines)
  static const int _parallelStride = 5; // draw a latitude (grid) line every Nth row
  // Keep the dots OFF the exact poles. At a true pole sin(theta)=0, so every
  // meridian collapses onto a single point — all _sphereCols dots stack there
  // into one bright pinch. Pulling the latitude range in by this margin removes
  // that singular convergence point.
  static const double _poleMargin = 0.22;
  // The top/bottom rows still form a small cap ring that the meridian lines
  // funnel toward. Skip this many rows at each pole when drawing the meridian
  // lines so the lines stop short of the cap (no visible funnel), and fade the
  // dots toward the poles so the residual cap thins out instead of reading as a
  // bright knot.
  static const int _capSkip = 4;
  static final Float64List _latSin = _fillLat(_sphereRows + 1, true);
  static final Float64List _latCos = _fillLat(_sphereRows + 1, false);
  // Per-row pole fade: 1 at the equator, easing toward `_capFadeMin` at the
  // caps. Applied to dot/line alpha so any leftover polar crowding dims away.
  static const double _capFadeMin = 0.18;
  static final Float64List _latFade = _fillLatFade(_sphereRows + 1);
  static final Float64List _lonSin = _fill(_sphereCols, 2 * pi, true);
  static final Float64List _lonCos = _fill(_sphereCols, 2 * pi, false);
  // Reusable full-grid projected-point buffers: one pass fills them, then the
  // meridian lines, the latitude lines and the dots are all drawn from them
  // (no recompute). Indexed [row * cols + col].
  static final Float64List _gx = Float64List((_sphereRows + 1) * _sphereCols);
  static final Float64List _gy = Float64List((_sphereRows + 1) * _sphereCols);
  static final Float64List _gd = Float64List((_sphereRows + 1) * _sphereCols);

  // Fill `n` samples of sin/cos spanning [0, span). `wantSin` picks the function.
  static Float64List _fill(int n, double span, bool wantSin) {
    final out = Float64List(n);
    final denom = n; // longitude wraps → no shared endpoint
    for (int i = 0; i < n; i++) {
      final a = (i / denom) * span;
      out[i] = wantSin ? sin(a) : cos(a);
    }
    return out;
  }

  // Latitude samples, spaced EQUAL-AREA (uniform in cos θ) and pulled in from
  // the exact poles by `_poleMargin`. Equal-area spacing keeps the dot density
  // even across the sphere instead of crowding the poles, and the margin keeps
  // the top/bottom rows off the singular pole point so the meridians never
  // funnel into one bright pinch.
  static Float64List _fillLat(int n, bool wantSin) {
    final out = Float64List(n);
    for (int i = 0; i < n; i++) {
      // cos θ runs linearly from +(1-margin) (north) to -(1-margin) (south).
      final c = (1 - _poleMargin) * (1 - 2 * i / (n - 1));
      out[i] = wantSin ? sqrt(1 - c * c) : c;
    }
    return out;
  }

  // Per-row alpha weight that fades from 1 at the equator to `_capFadeMin` at
  // the poles, so dots/lines near the caps don't read as a bright convergence.
  static Float64List _fillLatFade(int n) {
    final out = Float64List(n);
    for (int i = 0; i < n; i++) {
      // |cos θ| normalised to 0 (equator) .. 1 (cap).
      final ratio = (1 - 2 * i / (n - 1)).abs();
      out[i] = _capFadeMin + (1 - _capFadeMin) * (1 - ratio * ratio);
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = min(cx, cy);

    // Circle SIZE pumps with the bass pulse (NCS-style): small between kicks,
    // expanding on the kick. beatPulse is the bass envelope follower.
    final baseRadius = maxR * (0.66 + beatPulse * 0.26);

    // The dotted mesh sphere + glowing ring (matches the reference look).
    _drawRing(canvas, cx, cy, baseRadius, maxR);
  }

  void _drawRing(Canvas canvas, double cx, double cy, double baseR, double maxR) {
    final fl = flow; // pulse-driven phase — drives the surface wave

    // --- Dotted mesh-grid spheres ---------------------------------------------
    // THREE wave-draped lat/lon grids, each with its pole pointing a DIFFERENT
    // way (and precessing on its own phase), overlaid. The convergence points
    // land in different places, so the lines weave from several axes instead of
    // all funnelling into one pole. Each is clamped inside the ring; later ones
    // are dimmer so they layer rather than fight.
    final sphereR = baseR * 0.97; // silhouette reaches the ring → dense rim
    final cosY = cos(spin);
    final sinY = sin(spin);
    final limit = baseR * 0.99;
    _drawDotSphere(canvas, cx, cy, sphereR, maxR, fl, cosY, sinY, limit,
        0.0, 0.0, 0.0, 1.0);
    _drawDotSphere(canvas, cx, cy, sphereR * 0.99, maxR, fl + 2.1, cosY, sinY,
        limit, 1.1, 0.8, 2.1, 0.78);
    _drawDotSphere(canvas, cx, cy, sphereR * 0.98, maxR, fl + 4.0, cosY, sinY,
        limit, -0.9, 2.0, 4.0, 0.58);

    // --- Inner wave contours --------------------------------------------------
    // A couple of rippling lines that hug the INSIDE of the ring and undulate
    // with the flow — the wavy band that rims the circle in the reference.
    _drawWaveContour(canvas, cx, cy, baseR * 0.9, maxR, fl, 1.0);
    _drawWaveContour(canvas, cx, cy, baseR * 0.84, maxR, fl * 1.2 + 1.6, 0.6);

    // --- Bright neon ring -----------------------------------------------------
    // Layered neon tube: a wide soft halo, a mid bloom, a saturated band, and a
    // white-hot core. Stacking the glows (not one flat stroke) gives the ring
    // the feathered, lit-from-within look of real neon instead of a plain circle.
    final hot = Color.lerp(color, const Color(0xFFFFFFFF), 0.3)!;
    canvas.drawCircle(
      Offset(cx, cy),
      baseR,
      Paint()
        ..color = color.withValues(alpha: 0.22 + beatPulse * 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = maxR * (0.08 + beatPulse * 0.03)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, maxR * 0.06),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      baseR,
      Paint()
        ..color = color.withValues(alpha: 0.5 + beatPulse * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = maxR * (0.03 + beatPulse * 0.012)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, maxR * 0.02),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      baseR,
      Paint()
        ..color = color.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = maxR * (0.014 + beatPulse * 0.005),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      baseR,
      Paint()
        ..color = hot.withValues(alpha: 0.9 + beatPulse * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = maxR * 0.004,
    );
  }

  // Draws the sphere as a wave-draped lat/lon GRID of dots: meridian lines down
  // the columns, latitude lines across the rows, and a dot at every node. Every
  // projected point is clamped within `limit` of the centre so nothing spills
  // outside the ring.
  void _drawDotSphere(
      Canvas canvas,
      double cx,
      double cy,
      double sphereR,
      double maxR,
      double fl,
      double cosY,
      double sinY,
      double limit,
      double baseA, // base pole tilt (rotate local around X) — per-mesh axis
      double baseB, // base pole swing (rotate local around Y) — per-mesh axis
      double phase, // precession phase offset — each mesh wanders differently
      double dim) {
    // Per-mesh base orientation: points the pole a different way for each mesh.
    final cosA = cos(baseA);
    final sinA = sin(baseA);
    final cosB = cos(baseB);
    final sinB = sin(baseB);
    // The tilt axis is NOT fixed vertical: it slowly precesses (own phase). A
    // time-varying X tilt nods the pole, and an in-plane Z rotation swings it off
    // vertical, so each mesh's spin axis wanders on its own path.
    final tiltX = 0.32 + 0.20 * sin(time * 0.23 + phase);
    final tiltZ = 0.28 * sin(time * 0.17 + phase * 1.3);
    final cosX = cos(tiltX);
    final sinX = sin(tiltX);
    final cosZ = cos(tiltZ);
    final sinZ = sin(tiltZ);
    final waveAmp = 0.08 + rmsLevel * 0.06 + beatPulse * 0.16; // smooth drape
    final limitSq = limit * limit;

    // 1) Project the whole grid once into the shared buffers.
    for (int r = 0; r <= _sphereRows; r++) {
      final latS = _latSin[r]; // sin(theta) = ring radius at this latitude
      final latC = _latCos[r]; // cos(theta) = height (pole axis)
      final rowBase = r * _sphereCols;
      for (int c = 0; c < _sphereCols; c++) {
        final lonC = _lonCos[c];
        final lonS = _lonSin[c];
        // Slow large-scale drape: low spatial frequency so the surface folds
        // smoothly across the whole sphere instead of fine ripples.
        final w = sin(latC * 1.8 - fl * 0.6 + lonS * 1.2) * 0.6 +
            sin(latS * 1.4 + lonC - fl * 0.4) * 0.4;
        final disp = 1.0 + waveAmp * w;
        final lx = latS * lonC * disp;
        final ly = latC * disp;
        final lz = latS * lonS * disp;
        // Base orientation: rotate the local point around X (baseA) then Y
        // (baseB) so this mesh's pole points its own way.
        final ax = lx;
        final ay = ly * cosA - lz * sinA;
        final az = ly * sinA + lz * cosA;
        final ux = ax * cosB + az * sinB;
        final uy = ay;
        final uz = -ax * sinB + az * cosB;
        // Rotate around Y (the spin), then the precessing X tilt, then an
        // in-plane Z rotation that swings the whole axis off vertical.
        final rx = ux * cosY + uz * sinY;
        final rz = -ux * sinY + uz * cosY;
        final ry = uy * cosX - rz * sinX;
        final rz2 = uy * sinX + rz * cosX;
        final fx = rx * cosZ - ry * sinZ;
        final fy = rx * sinZ + ry * cosZ;
        final proj = _perspective / (_perspective - rz2);
        final scale = sphereR * proj;
        double ox = fx * scale;
        double oy = fy * scale;
        final d2 = ox * ox + oy * oy; // clamp inside the ring
        if (d2 > limitSq) {
          final k = limit / sqrt(d2);
          ox *= k;
          oy *= k;
        }
        final idx = rowBase + c;
        _gx[idx] = cx + ox;
        _gy[idx] = cy + oy;
        _gd[idx] = (rz2 + 1) * 0.5; // 0 = back, 1 = front
      }
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 2) Meridian lines (down each column) — the flowing wave lines. Stop short
    // of the caps (_capSkip rows) so the lines don't funnel into the pole.
    final mFirst = _capSkip;
    final mLast = _sphereRows - _capSkip;
    for (int c = 0; c < _sphereCols; c++) {
      final path = Path();
      double depthSum = 0;
      for (int r = mFirst; r <= mLast; r++) {
        final idx = r * _sphereCols + c;
        if (r == mFirst) {
          path.moveTo(_gx[idx], _gy[idx]);
        } else {
          path.lineTo(_gx[idx], _gy[idx]);
        }
        depthSum += _gd[idx];
      }
      final avg = depthSum / (mLast - mFirst + 1);
      linePaint.color = color.withValues(
          alpha: ((0.05 + avg * avg * 0.30) * dim).clamp(0.0, 1.0));
      linePaint.strokeWidth = maxR * 0.0015;
      canvas.drawPath(path, linePaint);
    }

    // 3) Latitude lines (across each Nth row) — the crossing grid lines.
    for (int r = _parallelStride; r < _sphereRows; r += _parallelStride) {
      final path = Path();
      double depthSum = 0;
      final rowBase = r * _sphereCols;
      for (int c = 0; c <= _sphereCols; c++) {
        final idx = rowBase + (c % _sphereCols);
        if (c == 0) {
          path.moveTo(_gx[idx], _gy[idx]);
        } else {
          path.lineTo(_gx[idx], _gy[idx]);
        }
        if (c < _sphereCols) depthSum += _gd[idx];
      }
      final avg = depthSum / _sphereCols;
      linePaint.color = color.withValues(
          alpha: ((0.04 + avg * avg * 0.22) * dim * _latFade[r]).clamp(0.0, 1.0));
      linePaint.strokeWidth = maxR * 0.0013;
      canvas.drawPath(path, linePaint);
    }

    // 4) Small glowing dots at every node, depth-shaded.
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final n = (_sphereRows + 1) * _sphereCols;
    for (int idx = 0; idx < n; idx++) {
      final depth = _gd[idx];
      final fade = _latFade[idx ~/ _sphereCols]; // dim dots toward the poles
      final dotR =
          maxR * (0.0010 + depth * depth * 0.0024) * (1.0 + beatPulse * 0.4);
      dotPaint.color = color.withValues(
          alpha: ((0.10 + pow(depth, 1.6).toDouble() * 0.8) * dim * fade)
              .clamp(0.0, 1.0));
      canvas.drawCircle(Offset(_gx[idx], _gy[idx]), dotR, dotPaint);
    }
  }

  // A closed rippling contour that hugs the inside of the ring. Its radius
  // wobbles with an irregular traveling wave (incommensurate speeds), so it
  // undulates around the circle as the flow advances. Drawn with a soft glow
  // pass + a crisp pass for the neon look.
  void _drawWaveContour(Canvas canvas, double cx, double cy, double r0,
      double maxR, double fl, double bright) {
    final amp = maxR * (0.018 + rmsLevel * 0.02 + beatPulse * 0.03);
    final path = Path();
    const steps = 128;
    for (int i = 0; i <= steps; i++) {
      final a = (i / steps) * 2 * pi;
      final w = sin(a * 3 - fl) * 0.5 +
          sin(a * 5 - fl * 1.3 + 1.1) * 0.3 +
          sin(a * 2 + fl * 0.7 + 2.4) * 0.2;
      final rr = r0 + amp * w;
      final x = cx + cos(a) * rr;
      final y = cy + sin(a) * rr;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: (0.18 + beatPulse * 0.12) * bright)
        ..style = PaintingStyle.stroke
        ..strokeWidth = maxR * 0.01
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, maxR * 0.012),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: (0.55 + beatPulse * 0.25) * bright)
        ..style = PaintingStyle.stroke
        ..strokeWidth = maxR * 0.0035,
    );
  }

  @override
  bool shouldRepaint(NcsVisualizerPainter old) => true;
}
