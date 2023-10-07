import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

import './control_ui.dart';

class ControlStream extends StatelessWidget {
  const ControlStream({Key? key, required this.assetsAudioPlayer})
      : super(key: key);
  final AssetsAudioPlayer assetsAudioPlayer;

  @override
  Widget build(BuildContext context) {
    Duration trackDuration = const Duration();
    Duration trackCurrentPosition = const Duration();

    return StreamBuilder<Playing?>(
      stream: assetsAudioPlayer.current,
      builder: (context, playing) {
        if (playing.data != null) {
          trackDuration = playing.data!.audio.duration;
        }
        return StreamBuilder(
          stream: assetsAudioPlayer.currentPosition,
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.data != null) {
              trackCurrentPosition = asyncSnapshot.data!;
            }
            return ControlUI(
              trackDuration: trackDuration,
              trackCurrentPosition: trackCurrentPosition,
              assetsAudioPlayer: assetsAudioPlayer,
            );
          },
        );
      },
    );
  }
}
