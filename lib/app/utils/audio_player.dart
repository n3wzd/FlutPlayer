import 'dart:async';
import 'dart:math';

import 'package:flutter_soloud/flutter_soloud.dart';

import '../models/data.dart';
import './preference.dart';

enum AudioPlayerProcessingState { idle, loading, ready, completed }

class AudioPlayer {
  static final SoLoud _soloud = SoLoud.instance;
  static Future<void>? _initFuture;

  AudioSource? _source;
  SoundHandle? _handle;
  Duration _lastKnownPosition = Duration.zero;
  double _volume = 1.0;
  AudioPlayerProcessingState _processingState = AudioPlayerProcessingState.idle;
  StreamSubscription<StreamSoundEvent>? _soundEventSubscription;
  Timer? _positionTimer;
  late int _audioPlayerCode;
  late void Function(int) _nextEventWhenPlayerCompleted;

  final _playingStreamController = StreamController<void>.broadcast();
  final _positionStreamController = StreamController<Duration>.broadcast();
  final _playbackEventStreamController = StreamController<void>.broadcast();
  final equalizer = SoLoudEqualizer();

  bool get isPlaying {
    final handle = _handle;
    if (handle == null || handle.isError || !_soloud.isInitialized) {
      return false;
    }
    try {
      return _soloud.getIsValidVoiceHandle(handle) && !_soloud.getPause(handle);
    } catch (_) {
      return false;
    }
  }

  bool get isAudioPlayerEmpty => _source == null;
  Stream<void> get playingStream => _playingStreamController.stream;
  Stream<Duration> get positionStream => _positionStreamController.stream;
  Stream<void> get playbackEventStream => _playbackEventStreamController.stream;
  AudioPlayerProcessingState get processingState => _processingState;
  double get volume => _volume;

  Duration get position {
    final handle = _handle;
    if (handle == null || handle.isError || !_soloud.isInitialized) {
      return Duration.zero;
    }
    try {
      if (!_soloud.getIsValidVoiceHandle(handle)) {
        return _lastKnownPosition;
      }
      final currentPosition = _soloud.getPosition(handle);
      if (currentPosition <= Duration.zero &&
          isPlaying &&
          _lastKnownPosition > Duration.zero) {
        return _lastKnownPosition;
      }
      _lastKnownPosition = currentPosition;
      return currentPosition;
    } catch (_) {
      return _lastKnownPosition;
    }
  }

  Duration get duration {
    final source = _source;
    if (source == null || !_soloud.isInitialized) {
      return const Duration(milliseconds: 1);
    }
    try {
      return _soloud.getLength(source);
    } catch (_) {
      return const Duration(milliseconds: 1);
    }
  }

  Future<void> init(
    int audioPlayerCode,
    void Function(int) nextEventWhenPlayerCompleted,
  ) async {
    _audioPlayerCode = audioPlayerCode;
    _nextEventWhenPlayerCompleted = nextEventWhenPlayerCompleted;
    await _ensureInitialized();
    _soloud.setVisualizationEnabled(true);
    equalizer.loadPreferenceGains();
    _positionTimer ??= Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _emitPosition(),
    );
    _emitPlaybackState();
  }

  Future<void> dispose() async {
    _positionTimer?.cancel();
    await _soundEventSubscription?.cancel();
    await _stopCurrent();
    await _playingStreamController.close();
    await _positionStreamController.close();
    await _playbackEventStreamController.close();
  }

  Future<Duration?> setAudioSource(AudioTrack? audioTrack) async {
    if (audioTrack == null) {
      return null;
    }

    await _ensureInitialized();
    _processingState = AudioPlayerProcessingState.loading;
    _emitPlaybackState();
    await _stopCurrent();

    final source = await _soloud.loadFile(audioTrack.path);
    _source = source;
    _lastKnownPosition = Duration.zero;
    _createHandle(paused: true);
    _processingState = AudioPlayerProcessingState.ready;
    _emitPlaybackState();
    _emitPosition();
    return duration;
  }

  Future<void> clearAudioSource() async {
    await _stopCurrent();
    _emitPlaybackState();
    _emitPosition();
  }

  void play() {
    var handle = _handle;
    if ((handle == null || handle.isError) && _source != null) {
      handle = _createHandle(paused: false);
    }
    if (handle == null || handle.isError) {
      return;
    }
    _soloud.setPause(handle, false);
    _processingState = AudioPlayerProcessingState.ready;
    _emitPlaybackState();
  }

  Future<void> pause() async {
    final handle = _handle;
    if (handle == null || handle.isError) {
      return;
    }
    _soloud.setPause(handle, true);
    _emitPosition();
    _emitPlaybackState();
  }

  Future<void> replay() async {
    await seek(Duration.zero);
    await pause();
    play();
  }

  Future<void> seek(Duration pos) async {
    var handle = _handle;
    if ((handle == null || handle.isError) && _source != null) {
      handle = _createHandle(paused: true);
    }
    if (handle == null || handle.isError) {
      return;
    }
    _soloud.seek(handle, pos);
    _lastKnownPosition = pos;
    _emitPosition();
    _emitPlaybackState();
  }

  void setVolume(double vol) {
    _volume = vol;
    final handle = _handle;
    if (handle != null && !handle.isError) {
      _soloud.setVolume(handle, vol);
    }
  }

  Future<void> fadeVolume(double target, Duration duration) async {
    final start = _volume;
    final stepCount = max(1, duration.inMilliseconds ~/ 10);
    final stepDuration = Duration(
      milliseconds: max(1, duration.inMilliseconds ~/ stepCount),
    );

    for (int step = 1; step <= stepCount; step++) {
      setVolume(start + (target - start) * step / stepCount);
      await Future<void>.delayed(stepDuration);
    }
    setVolume(target);
  }

  void setEnabledEqualizer() {
    equalizer.setEnabled(
      Preference.enableEqualizer,
      hasAudioHandle: _hasValidHandle,
    );
  }

  Future<void> syncEqualizer(AudioPlayer sub) async {
    await equalizer.syncTo(sub.equalizer);
  }

  static Future<void> _ensureInitialized() {
    if (_soloud.isInitialized) {
      return Future.value();
    }
    return _initFuture ??= _soloud.init();
  }

  bool get _hasValidHandle {
    final handle = _handle;
    return handle != null && !handle.isError;
  }

  SoundHandle? _createHandle({required bool paused}) {
    final source = _source;
    if (source == null) {
      return null;
    }
    final handle = _soloud.play(source, volume: _volume, paused: paused);
    _handle = handle;
    setEnabledEqualizer();
    _listenForCompletion(source, handle);
    return handle;
  }

  void _listenForCompletion(AudioSource source, SoundHandle handle) {
    _soundEventSubscription?.cancel();
    _soundEventSubscription = source.soundEvents.listen((event) {
      if (event.handle != handle ||
          event.event != SoundEventType.handleIsNoMoreValid) {
        return;
      }
      _handle = null;
      _processingState = AudioPlayerProcessingState.completed;
      _emitPlaybackState();
      _nextEventWhenPlayerCompleted(_audioPlayerCode);
    });
  }

  Future<void> _stopCurrent() async {
    final handle = _handle;
    final source = _source;
    _handle = null;
    _source = null;
    _lastKnownPosition = Duration.zero;
    await _soundEventSubscription?.cancel();
    _soundEventSubscription = null;
    if (handle != null && !handle.isError && _soloud.isInitialized) {
      await _soloud.stop(handle);
    }
    if (source != null && _soloud.isInitialized) {
      await _soloud.disposeSource(source);
    }
    _processingState = AudioPlayerProcessingState.idle;
  }

  void _emitPlaybackState() {
    if (!_playingStreamController.isClosed) {
      _playingStreamController.add(null);
    }
    if (!_playbackEventStreamController.isClosed) {
      _playbackEventStreamController.add(null);
    }
  }

  void _emitPosition() {
    if (!_positionStreamController.isClosed) {
      _positionStreamController.add(position);
    }
  }
}

class SoLoudEqualizer {
  static const int bandsLength = Preference.equalizerBandsLength;
  static const double minGain = Preference.equalizerMinGain;
  static const double maxGain = Preference.equalizerMaxGain;
  static const double defaultGain = Preference.equalizerDefaultGain;
  static final List<double> _gains = List<double>.from(
    Preference.equalizerGains,
  );

  void loadPreferenceGains() {
    for (int i = 0; i < bandsLength; i++) {
      _gains[i] = Preference.equalizerGains[i]
          .clamp(minGain, maxGain)
          .toDouble();
    }
  }

  Future<SoLoudEqualizerParameters> get parameters async {
    final eq = SoLoud.instance.filters.parametricEqFilter;
    if (eq.isActive) {
      for (int i = 0; i < bandsLength; i++) {
        _gains[i] = eq.bandGain(i).value;
      }
    }
    return SoLoudEqualizerParameters(
      bands: List<SoLoudEqualizerBand>.generate(
        bandsLength,
        (index) => SoLoudEqualizerBand(this, index, _gains[index]),
      ),
      minDecibels: minGain,
      maxDecibels: maxGain,
    );
  }

  void setEnabled(bool enabled, {required bool hasAudioHandle}) {
    final eq = SoLoud.instance.filters.parametricEqFilter;
    if (enabled && !hasAudioHandle) {
      loadPreferenceGains();
      return;
    }
    if (enabled && !eq.isActive) {
      eq.activate();
      eq.numBands.value = bandsLength.toDouble();
      eq.stftWindowSize.value = 1024;
    } else if (!enabled && eq.isActive) {
      eq.deactivate();
      return;
    }
    if (enabled) {
      _applyGains();
    }
  }

  Future<void> syncTo(SoLoudEqualizer _) async {
    if (Preference.enableEqualizer) {
      _applyGains();
    }
  }

  void setBandGain(int index, double gain) {
    _gains[index] = gain.clamp(minGain, maxGain).toDouble();
    Preference.equalizerGains[index] = _gains[index];
    if (Preference.enableEqualizer) {
      SoLoud.instance.filters.parametricEqFilter.bandGain(index).value =
          _gains[index];
    }
  }

  void _applyGains() {
    final eq = SoLoud.instance.filters.parametricEqFilter;
    for (int i = 0; i < bandsLength; i++) {
      eq.bandGain(i).value = _gains[i];
    }
  }
}

class SoLoudEqualizerParameters {
  SoLoudEqualizerParameters({
    required this.bands,
    required this.minDecibels,
    required this.maxDecibels,
  });

  final List<SoLoudEqualizerBand> bands;
  final double minDecibels;
  final double maxDecibels;
}

class SoLoudEqualizerBand {
  SoLoudEqualizerBand(this._equalizer, this.index, this.gain);

  final SoLoudEqualizer _equalizer;
  final int index;
  double gain;

  double get centerFrequency =>
      _calculateBandFrequency(index, SoLoudEqualizer.bandsLength);

  double get defaultGain => SoLoudEqualizer.defaultGain;

  void setGain(double value) {
    gain = value;
    _equalizer.setBandGain(index, value);
  }

  double _calculateBandFrequency(int bandIndex, int bandsLength) {
    const f0 = 30.0;
    const f1 = 16000.0;
    final t = bandIndex / (bandsLength - 1);
    return f0 * pow(f1 / f0, t);
  }
}
