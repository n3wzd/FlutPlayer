import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import './control_ui.dart';
import './button_ui.dart';

import '../style/colors.dart';

class BottomSection extends StatelessWidget {
  const BottomSection({Key? key, required this.audioPlayer}) : super(key: key);
  final AudioPlayer audioPlayer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: ColorTheme.darkWine),
      child: Column(
        children: [
          const SizedBox(height: 10),
          StreamBuilder<Duration>(
            stream: audioPlayer.positionStream,
            builder: (context, currentPosition) => ControlUI(
              trackDuration: audioPlayer.duration ?? const Duration(),
              trackCurrentPosition: currentPosition.data ?? const Duration(),
              audioPlayer: audioPlayer,
            ),
          ),
          const SizedBox(height: 10),
          ButtonUI(audioPlayer: audioPlayer),
        ],
      ),
    );
  }
}
