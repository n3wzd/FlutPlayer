import 'package:flutter/foundation.dart';
import 'dart:async';

class AdvancedTimer {
  AdvancedTimer({required this.duration, required this.onComplete})
      : _remainingTime = duration;

  final Stopwatch _stopwatch = Stopwatch();
  final Duration duration;
  final VoidCallback onComplete;

  Timer? _timer;
  Duration _remainingTime;

  Duration get remainingTime => _remainingTime - _stopwatch.elapsed;
  bool get isRunning => _timer != null;

  void start() {
    if (_timer != null) {
      return;
    }
    _stopwatch.start();
    _timer = Timer(_remainingTime, _onComplete);
  }

  void pause() {
    if (_timer == null) {
      return;
    }
    _stopwatch.stop();
    _timer?.cancel();
    _timer = null;
    _remainingTime -= _stopwatch.elapsed;
  }

  void resume() {
    if (_timer != null || _remainingTime <= Duration.zero) {
      return;
    }
    _stopwatch.reset();
    _stopwatch.start();
    _timer = Timer(_remainingTime, _onComplete);
  }

  void cancel() {
    _stopwatch.stop();
    _stopwatch.reset();
    _timer?.cancel();
    _timer = null;
    _remainingTime = duration;
  }

  void _onComplete() {
    _stopwatch.stop();
    _timer = null;
    _remainingTime = Duration.zero;
    onComplete();
  }
}
