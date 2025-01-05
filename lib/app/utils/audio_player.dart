import 'package:just_audio/just_audio.dart' as just_audio;
import '../models/data.dart';
import './preference.dart';

class AudioPlayer {
  late final _audioPlayerJust = just_audio.AudioPlayer(
    handleInterruptions: false,
    handleAudioSessionActivation: false,
    audioPipeline:  just_audio.AudioPipeline(
            androidAudioEffects: [
              _equalizer,
            ],
          ),
  );
  final _equalizer = just_audio.AndroidEqualizer();

  bool get isPlaying => _audioPlayerJust.playing;
  bool get isAudioPlayerEmpty => _audioPlayerJust.audioSource == null;
  just_audio.AndroidEqualizer get equalizer => _equalizer;

  Stream<void> get playingStream => _audioPlayerJust.playingStream;
  Stream<Duration> get positionStream => _audioPlayerJust.positionStream;

  Stream<just_audio.PlaybackEvent> get playbackEventStream =>
      _audioPlayerJust.playbackEventStream;
  just_audio.ProcessingState get processingState =>
      _audioPlayerJust.processingState;

  Duration get position => _audioPlayerJust.position;
  Duration get duration => _audioPlayerJust.duration ?? const Duration(milliseconds: 1);

  void init(
      int audioPlayerCode, void Function(int) nextEventWhenPlayerCompleted) {
    _audioPlayerJust.processingStateStream
        .where((state) => state == just_audio.ProcessingState.completed)
        .listen((state) {
      nextEventWhenPlayerCompleted(audioPlayerCode);
    });
    setEnabledEqualizer();
    play();
  }

  void dispose() {
    _audioPlayerJust.dispose();
  }

  Future<Duration?> setAudioSource(AudioTrack? audioTrack) async {
    if (audioTrack != null) {
      return await _audioPlayerJust
          .setAudioSource(just_audio.AudioSource.file(audioTrack.path));
    }
    return null;
  }

  void play() {
    _audioPlayerJust.play();
  }

  Future<void> pause() async {
    await _audioPlayerJust.pause();
  }

  Future<void> replay() async {
    await seek(const Duration());
    await pause();
    play();
  }

  Future<void> seek(Duration pos) async {
    await _audioPlayerJust.seek(pos);
  }

  void setVolume(double vol) {
    _audioPlayerJust.setVolume(vol);
  }

  void setEnabledEqualizer() {
    equalizer.setEnabled(Preference.enableEqualizer);
  }

  Future<void> syncEqualizer(AudioPlayer sub) async {
    var parameters = await equalizer.parameters;
    var parametersSub = await sub.equalizer.parameters;
    var bands = parameters.bands;
    var bandsSub = parametersSub.bands;
    for (int i = 0; i < bands.length; i++) {
      bandsSub[i].setGain(bands[i].gain);
    }
  }
}
