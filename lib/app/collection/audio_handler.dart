import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

import './audio_player.dart';

Future<AudioHandler> createAudioSerivce(AudioPlayerKit audioPlayerKit) async =>
    await AudioService.init(
      builder: () => AudioHandlerKit(audioPlayerKit: audioPlayerKit),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'FlutBeat.myapp.channel.audio',
        androidNotificationChannelName: 'Music playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );

class AudioHandlerKit extends BaseAudioHandler {
  AudioHandlerKit({required this.audioPlayerKit}) {
    _notifyAudioHandler();
  }
  final AudioPlayerKit audioPlayerKit;

  @override
  Future<void> play() async {
    audioPlayerKit.play();
  }

  @override
  Future<void> pause() async {
    audioPlayerKit.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    audioPlayerKit.seekPosition(position);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    audioPlayerKit.seekTrack(index);
  }

  @override
  Future<void> skipToNext() async {
    audioPlayerKit.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    audioPlayerKit.seekToPrevious();
  }

  void _notifyAudioHandler() {
    bool isPlaying = audioPlayerKit.isPlaying;
    audioPlayerKit.playbackEventStream.listen((PlaybackEvent event) {
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
        updatePosition: audioPlayerKit.position,
      ));
    });
  }
}
