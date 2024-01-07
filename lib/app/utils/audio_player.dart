import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:audioplayers/audioplayers.dart' as audio_players;
import '../global.dart' as global;
import '../models/data.dart';
import './playlist.dart';
import './preference.dart';

class AudioPlayer {
  late final _audioPlayerJust = just_audio.AudioPlayer(
    handleInterruptions: false,
    handleAudioSessionActivation: false,
    audioPipeline: global.isAndroid
        ? just_audio.AudioPipeline(
            androidAudioEffects: [
              _equalizer,
            ],
          )
        : null,
  );
  late final _audioPlayerAudio = audio_players.AudioPlayer();
  final _equalizer = just_audio.AndroidEqualizer();

  bool get usingJustAudio => !global.isWindows;
  bool get isPlaying => usingJustAudio
      ? _audioPlayerJust.playing
      : _audioPlayerAudio.state == audio_players.PlayerState.playing;
  bool get isAudioPlayerEmpty => usingJustAudio
      ? _audioPlayerJust.audioSource == null
      : _audioPlayerAudio.source == null;
  just_audio.AndroidEqualizer get equalizer => _equalizer;

  Stream<void> get playingStream => usingJustAudio
      ? _audioPlayerJust.playingStream
      : _audioPlayerAudio.onPlayerStateChanged;
  Stream<Duration> get positionStream => usingJustAudio
      ? _audioPlayerJust.positionStream
      : _audioPlayerAudio.onPositionChanged;

  Stream<just_audio.PlaybackEvent> get playbackEventStream =>
      _audioPlayerJust.playbackEventStream;
  just_audio.ProcessingState get processingState =>
      _audioPlayerJust.processingState;

  Duration get position =>
      usingJustAudio ? _audioPlayerJust.position : _positionAudio;
  Duration get duration => usingJustAudio
      ? (_audioPlayerJust.duration ?? const Duration(milliseconds: 1))
      : _durationAudio;
  Duration _positionAudio = const Duration(milliseconds: 0);
  Duration _durationAudio = const Duration(milliseconds: 1);

  void init(
      int audioPlayerCode, void Function(int) nextEventWhenPlayerCompleted) {
    if (usingJustAudio) {
      _audioPlayerJust.processingStateStream
          .where((state) => state == just_audio.ProcessingState.completed)
          .listen((state) {
        nextEventWhenPlayerCompleted(audioPlayerCode);
      });
      setEnabledEqualizer();
    } else {
      _audioPlayerAudio.onPlayerComplete.listen((state) {
        nextEventWhenPlayerCompleted(audioPlayerCode);
      });
      _audioPlayerAudio.onDurationChanged.listen((duration) {
        _durationAudio = duration;
      });
      _audioPlayerAudio.onPositionChanged.listen((duration) {
        _positionAudio = duration;
      });
    }
    play();
  }

  void dispose() {
    _audioPlayerJust.dispose();
    _audioPlayerAudio.dispose();
  }

  Future<Duration?> setAudioSource(AudioTrack? audioTrack) async {
    if (audioTrack != null) {
      if (usingJustAudio) {
        if (global.isAndroid) {
          return await _audioPlayerJust
              .setAudioSource(just_audio.AudioSource.file(audioTrack.path));
        } else {
          return await _audioPlayerJust.setAudioSource(
              FileAudioSource(bytes: audioTrack.file!.bytes!.cast<int>()));
        }
      } else {
        await _audioPlayerAudio.stop();
        await _audioPlayerAudio.setSourceDeviceFile(audioTrack.path);
        return await _audioPlayerAudio.getDuration();
      }
    }
    return null;
  }

  void play() {
    if (usingJustAudio) {
      _audioPlayerJust.play();
    } else {
      _audioPlayerAudio.resume();
    }
  }

  Future<void> pause() async {
    if (usingJustAudio) {
      await _audioPlayerJust.pause();
    } else {
      await _audioPlayerAudio.pause();
    }
  }

  Future<void> replay() async {
    if (usingJustAudio) {
      await seek(const Duration());
      await pause();
      play();
    } else {
      await setAudioSource(PlayList.instance.currentAudioTrack);
      play();
    }
  }

  Future<void> seek(Duration pos) async {
    if (usingJustAudio) {
      await _audioPlayerJust.seek(pos);
    } else {
      await _audioPlayerAudio.seek(pos);
    }
  }

  void setVolume(double vol) {
    if (usingJustAudio) {
      _audioPlayerJust.setVolume(vol);
    } else {
      _audioPlayerAudio.setVolume(vol);
    }
  }

  void setEnabledEqualizer() {
    if (global.isAndroid) {
      equalizer.setEnabled(Preference.enableEqualizer);
    }
  }

  Future<void> syncEqualizer(AudioPlayer sub) async {
    if (global.isAndroid) {
      var parameters = await equalizer.parameters;
      var parametersSub = await sub.equalizer.parameters;
      var bands = parameters.bands;
      var bandsSub = parametersSub.bands;
      for (int i = 0; i < bands.length; i++) {
        bandsSub[i].setGain(bands[i].gain);
      }
    }
  }
}

/*import 'package:just_audio/just_audio.dart' as just_audio;
import '../global.dart' as global;
import '../models/data.dart';
import './playlist.dart';
import './preference.dart';

class AudioPlayer {
  late final _audioPlayerJust = just_audio.AudioPlayer(
    handleInterruptions: false,
    handleAudioSessionActivation: false,
    audioPipeline: global.isAndroid
        ? just_audio.AudioPipeline(
            androidAudioEffects: [
              _equalizer,
            ],
          )
        : null,
  );
  final _equalizer = just_audio.AndroidEqualizer();

  bool get usingJustAudio => !global.isWindows;
  bool get isPlaying =>
      usingJustAudio ? _audioPlayerJust.playing : _audioPlayerJust.playing;
  bool get isAudioPlayerEmpty => usingJustAudio
      ? _audioPlayerJust.audioSource == null
      : _audioPlayerJust.audioSource == null;
  just_audio.AndroidEqualizer get equalizer => _equalizer;

  Stream<void> get playingStream => usingJustAudio
      ? _audioPlayerJust.playingStream
      : _audioPlayerJust.playingStream;
  Stream<Duration> get positionStream => usingJustAudio
      ? _audioPlayerJust.positionStream
      : _audioPlayerJust.positionStream;

  Stream<just_audio.PlaybackEvent> get playbackEventStream =>
      _audioPlayerJust.playbackEventStream;
  just_audio.ProcessingState get processingState =>
      _audioPlayerJust.processingState;

  Duration get position =>
      usingJustAudio ? _audioPlayerJust.position : _positionAudio;
  Duration get duration => usingJustAudio
      ? (_audioPlayerJust.duration ?? const Duration(milliseconds: 1))
      : _durationAudio;
  Duration _positionAudio = const Duration(milliseconds: 0);
  Duration _durationAudio = const Duration(milliseconds: 1);

  void init(
      int audioPlayerCode, void Function(int) nextEventWhenPlayerCompleted) {
    if (usingJustAudio) {
      _audioPlayerJust.processingStateStream
          .where((state) => state == just_audio.ProcessingState.completed)
          .listen((state) {
        nextEventWhenPlayerCompleted(audioPlayerCode);
      });
      setEnabledEqualizer();
    } else {}
    play();
  }

  void dispose() {
    _audioPlayerJust.dispose();
  }

  Future<Duration?> setAudioSource(AudioTrack? audioTrack) async {
    if (audioTrack != null) {
      if (usingJustAudio) {
        if (global.isAndroid) {
          return await _audioPlayerJust
              .setAudioSource(just_audio.AudioSource.file(audioTrack.path));
        } else {
          return await _audioPlayerJust.setAudioSource(
              FileAudioSource(bytes: audioTrack.file!.bytes!.cast<int>()));
        }
      } else {}
    }
    return null;
  }

  void play() {
    if (usingJustAudio) {
      _audioPlayerJust.play();
    } else {}
  }

  Future<void> pause() async {
    if (usingJustAudio) {
      await _audioPlayerJust.pause();
    } else {}
  }

  Future<void> replay() async {
    if (usingJustAudio) {
      await seek(const Duration());
      await pause();
      play();
    } else {
      await setAudioSource(PlayList.instance.currentAudioTrack);
      play();
    }
  }

  Future<void> seek(Duration pos) async {
    if (usingJustAudio) {
      await _audioPlayerJust.seek(pos);
    } else {}
  }

  void setVolume(double vol) {
    if (usingJustAudio) {
      _audioPlayerJust.setVolume(vol);
    } else {}
  }

  void setEnabledEqualizer() {
    if (global.isAndroid) {
      equalizer.setEnabled(Preference.enableEqualizer);
    }
  }

  Future<void> syncEqualizer(AudioPlayer sub) async {
    if (global.isAndroid) {
      var parameters = await equalizer.parameters;
      var parametersSub = await sub.equalizer.parameters;
      var bands = parameters.bands;
      var bandsSub = parametersSub.bands;
      for (int i = 0; i < bands.length; i++) {
        bandsSub[i].setGain(bands[i].gain);
      }
    }
  }
}*/
