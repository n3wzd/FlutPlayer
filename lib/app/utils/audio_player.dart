import 'package:audioplayers/audioplayers.dart' as audio_players;
import '../models/data.dart';
import './playlist.dart';

class AudioPlayer {
  late final _audioPlayerAudio = audio_players.AudioPlayer();

  bool get isPlaying => _audioPlayerAudio.state == audio_players.PlayerState.playing;
  bool get isAudioPlayerEmpty => _audioPlayerAudio.source == null;

  Stream<void> get playingStream => _audioPlayerAudio.onPlayerStateChanged;
  Stream<Duration> get positionStream => _audioPlayerAudio.onPositionChanged;

  Duration get position => _positionAudio;
  Duration get duration => _durationAudio;
  Duration _positionAudio = const Duration(milliseconds: 0);
  Duration _durationAudio = const Duration(milliseconds: 1);

  void init(
    int audioPlayerCode, void Function(int) nextEventWhenPlayerCompleted) {
  
    _audioPlayerAudio.onPlayerComplete.listen((state) {
      nextEventWhenPlayerCompleted(audioPlayerCode);
    });
    _audioPlayerAudio.onDurationChanged.listen((duration) {
      _durationAudio = duration;
    });
    _audioPlayerAudio.onPositionChanged.listen((duration) {
      _positionAudio = duration;
    });
    play();
  }

  void dispose() {
    _audioPlayerAudio.dispose();
  }

  Future<Duration?> setAudioSource(AudioTrack? audioTrack) async {
    if (audioTrack != null) {
      await _audioPlayerAudio.stop();
      await _audioPlayerAudio.setSourceDeviceFile(audioTrack.path);
      return await _audioPlayerAudio.getDuration();
    }
    return null;
  }

  void play() {
    _audioPlayerAudio.resume();
  }

  Future<void> pause() async {
    await _audioPlayerAudio.pause();
  }

  Future<void> replay() async {
    await setAudioSource(PlayList.instance.currentAudioTrack);
    play();
  }

  Future<void> seek(Duration pos) async {
    await _audioPlayerAudio.seek(pos);
  }

  void setVolume(double vol) {
    _audioPlayerAudio.setVolume(vol);
  }
}
