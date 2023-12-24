import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import './audio_manager.dart';

Future<AudioHandler> createAudioSerivce() async => await AudioService.init(
      builder: () => AudioHandlerKit(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'FlutBeat.myapp.channel.audio',
        androidNotificationChannelName: 'Music playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );

class AudioHandlerKit extends BaseAudioHandler {
  AudioHandlerKit() {
    _notifyAudioHandler();
  }

  @override
  Future<void> play() async {
    AudioManager.instance.play();
  }

  @override
  Future<void> pause() async {
    AudioManager.instance.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    AudioManager.instance.seekPosition(position);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    AudioManager.instance.seekTrack(index);
  }

  @override
  Future<void> skipToNext() async {
    AudioManager.instance.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    AudioManager.instance.seekToPrevious();
  }

  void _notifyAudioHandler() {
    bool isPlaying = AudioManager.instance.isPlaying;
    AudioManager.instance.audioPlayer.playbackEventStream
        .listen((PlaybackEvent event) {
      playbackState.add(PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        playing: isPlaying,
        // updatePosition: AudioManager.instance.position,
      ));
    });
  }
}
