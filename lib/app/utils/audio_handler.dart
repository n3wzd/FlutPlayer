import 'package:audio_service/audio_service.dart';
import './audio_manager.dart';
import './audio_player.dart';
import './playlist.dart';
import './stream_controller.dart';

Future<AudioHandler> createAudioSerivce() async => await AudioService.init(
  builder: () => AudioHandlerManager(),
  config: const AudioServiceConfig(
    androidNotificationChannelId: 'com.mycompany.myapp.channel.audio',
    androidNotificationChannelName: 'Music playback',
    androidStopForegroundOnPause: false,
    androidNotificationClickStartsActivity: false,
  ),
);

class AudioHandlerManager extends BaseAudioHandler {
  AudioHandlerManager() {
    _notifyAudioHandler();
    _listenForTrackChanges();
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
  Future<void> skipToNext() async {
    AudioManager.instance.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    AudioManager.instance.seekToPrevious();
  }

  void _notifyAudioHandler() {
    AudioManager.instance.audioPlayer.playbackEventStream.listen((event) {
      bool isPlaying = AudioManager.instance.isPlaying;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            isPlaying ? MediaControl.pause : MediaControl.play,
            MediaControl.skipToNext,
          ],
          systemActions: const {MediaAction.seek},
          androidCompactActionIndices: const [0, 1, 2],
          playing: isPlaying,
          processingState: const {
            AudioPlayerProcessingState.idle: AudioProcessingState.idle,
            AudioPlayerProcessingState.loading: AudioProcessingState.loading,
            AudioPlayerProcessingState.ready: AudioProcessingState.ready,
            AudioPlayerProcessingState.completed:
                AudioProcessingState.completed,
          }[AudioManager.instance.audioPlayer.processingState]!,
          updatePosition: AudioManager.instance.position,
          bufferedPosition: AudioManager.instance.duration,
        ),
      );
    });
  }

  void _listenForTrackChanges() {
    AudioStreamController.track.stream.listen((value) {
      if (PlayList.instance.isNotEmpty) {
        var media = MediaItem(
          id: PlayList.instance.currentAudioTitle,
          title: PlayList.instance.currentAudioTitle,
          duration: AudioManager.instance.duration,
        );
        mediaItem.add(media);
      }
    });
  }
}
