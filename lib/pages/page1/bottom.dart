import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

import './control_section.dart';
import './button_section.dart';

class BottomSection extends StatelessWidget {
  const BottomSection({Key? key, required this.assetsAudioPlayer})
      : super(key: key);
  final AssetsAudioPlayer assetsAudioPlayer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF36081B)),
      child: Column(
        children: [
          const SizedBox(height: 10),
          ControlSection(assetsAudioPlayer: assetsAudioPlayer),
          const SizedBox(height: 10),
          ButtonSection(assetsAudioPlayer: assetsAudioPlayer),
        ],
      ),
    );
  }
}
