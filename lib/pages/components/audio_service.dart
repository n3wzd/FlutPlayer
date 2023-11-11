import 'package:audio_service/audio_service.dart';

import '../components/audio_player_kit.dart';

class CustomAudioHandler extends BaseAudioHandler {
  CustomAudioHandler({required this.audioPlayerKit});
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
  Future<void> stop() async {
    audioPlayerKit.dispose();
  }

  @override
  Future<void> seek(Duration position) async {
    audioPlayerKit.seekPosition(position);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    audioPlayerKit.seekTrack(index);
  }
}
