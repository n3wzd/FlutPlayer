import 'package:flutter/material.dart';

import '../components/audio_player_kit.dart';
import './control_ui.dart';
import './button_ui.dart';

import '../style/colors.dart';

class BottomSection extends StatelessWidget {
  const BottomSection({Key? key, required this.audioPlayerKit})
      : super(key: key);
  final AudioPlayerKit audioPlayerKit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: ColorTheme.darkWine),
      child: Column(
        children: [
          const SizedBox(height: 10),
          audioPlayerKit.processingStateStreamBuilder(
            (context, processingState) => audioPlayerKit.durationStreamBuilder(
              (context, currentPosition) => ControlUI(
                trackDuration: audioPlayerKit.duration,
                trackCurrentPosition: currentPosition.data ?? const Duration(),
                audioPlayerKit: audioPlayerKit,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ButtonUI(audioPlayerKit: audioPlayerKit),
        ],
      ),
    );
  }
}
