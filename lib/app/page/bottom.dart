import 'package:flutter/material.dart';

import './control_ui.dart';
import './button_ui.dart';
import '../collection/audio_player.dart';
import '../style/color.dart';

class BottomSection extends StatelessWidget {
  const BottomSection({Key? key, required this.audioPlayerKit})
      : super(key: key);
  final AudioPlayerKit audioPlayerKit;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(color: ColorMaker.darkWine),
        child: Column(
          children: [
            const SizedBox(height: 10),
            audioPlayerKit.trackStreamBuilder(
              (context, duration) => audioPlayerKit.positionStreamBuilder(
                (context, position) => ControlUI(
                  trackDuration: audioPlayerKit.duration,
                  trackPosition: position.data ?? const Duration(),
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
