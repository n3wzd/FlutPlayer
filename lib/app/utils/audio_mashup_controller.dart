import 'dart:async';
import 'dart:math';

import '../models/timer.dart';

typedef DoubleCallback = void Function(double value);
typedef AsyncCallback = FutureOr<void> Function();

class AudioMashupController {
  StreamSubscription<double>? _volumeTransitionTimer;
  AdvancedTimer? _nextTriggerTimer;

  void startVolumeTransition({
    required Duration duration,
    required DoubleCallback onTick,
    required void Function() onDone,
  }) {
    final intervalCount = duration.inMilliseconds ~/ 100;
    if (intervalCount <= 0) {
      onTick(1.0);
      onDone();
      return;
    }

    _volumeTransitionTimer?.cancel();
    _volumeTransitionTimer = Stream<double>.periodic(
      const Duration(milliseconds: 100),
      (x) => x / intervalCount,
    ).take(intervalCount).listen(onTick, onDone: onDone);
  }

  void startNextTrigger({
    required Duration duration,
    required bool Function() shouldAdvance,
    required AsyncCallback onNext,
  }) {
    _nextTriggerTimer?.cancel();
    _nextTriggerTimer = AdvancedTimer(
      duration: duration,
      onComplete: () {
        if (shouldAdvance()) {
          onNext();
        }
      },
    )..start();
  }

  void pause() {
    _volumeTransitionTimer?.pause();
    _nextTriggerTimer?.pause();
  }

  void resume() {
    _volumeTransitionTimer?.resume();
    _nextTriggerTimer?.resume();
  }

  Future<void> cancel() async {
    await _volumeTransitionTimer?.cancel();
    _volumeTransitionTimer = null;
    _nextTriggerTimer?.cancel();
    _nextTriggerTimer = null;
  }

  static Duration randomTriggerDuration({
    required int minSeconds,
    required int maxSeconds,
  }) {
    final range = max(0, maxSeconds - minSeconds);
    final milliseconds =
        (range * 1000 * Random().nextDouble() + minSeconds * 1000).toInt();
    return Duration(milliseconds: milliseconds);
  }
}

class AudioVolumeMixer {
  static const double _logScale = 8.0;
  static const double _expPower = 3.5;

  static AudioVolumeLevels calculate({
    required bool customMixMode,
    required double transitionRate,
  }) {
    final rate = transitionRate.clamp(0.0, 1.0).toDouble();
    if (customMixMode) {
      return _calculateCustomMix(rate);
    }
    return AudioVolumeLevels(
      primary: _logVolume(rate),
      secondary: 1.0 - pow(rate, _expPower).toDouble(),
    );
  }

  static AudioVolumeLevels _calculateCustomMix(double rate) {
    const baseA = 0.6;
    const baseB = 0.1;
    const volumeThreshold1 = 0.2;
    const volumeThreshold2 = 0.7;

    if (rate < volumeThreshold1) {
      final v = rate / volumeThreshold1;
      return AudioVolumeLevels(
        primary: _logVolume(v) * baseA,
        secondary: 1.0 - pow(v, _expPower).toDouble() * baseB,
      );
    }

    if (rate < volumeThreshold2) {
      return const AudioVolumeLevels(primary: baseA, secondary: 1.0 - baseB);
    }

    final v = (rate - volumeThreshold2) / (1.0 - volumeThreshold2);
    return AudioVolumeLevels(
      primary: _logVolume(v) * (1.0 - baseA) + baseA,
      secondary: 1.0 - (pow(v, _expPower).toDouble() * (1.0 - baseB) + baseB),
    );
  }

  static double _logVolume(double value) =>
      log(1 + value * _logScale) / log(1 + _logScale);
}

class AudioVolumeLevels {
  const AudioVolumeLevels({required this.primary, required this.secondary});

  final double primary;
  final double secondary;
}
