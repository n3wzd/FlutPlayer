import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

import './control_ui.dart';
import './button_ui.dart';

class BottomSection extends StatelessWidget {
  const BottomSection(
      {Key? key, required this.assetsAudioPlayer, required this.playing})
      : super(key: key);
  final AssetsAudioPlayer assetsAudioPlayer;
  final Playing playing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF36081B)),
      child: Column(
        children: [
          const SizedBox(height: 10),
          PlayerBuilder.currentPosition(
            player: assetsAudioPlayer,
            builder: (context, currentPosition) => ControlUI(
              trackDuration: playing.audio.duration,
              trackCurrentPosition: currentPosition,
              assetsAudioPlayer: assetsAudioPlayer,
            ),
          ),
          const SizedBox(height: 10),
          ButtonUI(assetsAudioPlayer: assetsAudioPlayer),
        ],
      ),
    );
  }
}
