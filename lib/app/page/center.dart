import 'package:flutter/material.dart';

import './top_menu.dart';
import '../collection/audio_player.dart';
import '../component/text_scroll.dart';
import '../style/color.dart';

class CenterSection extends StatelessWidget {
  const CenterSection({super.key, required this.audioPlayerKit});
  final AudioPlayerKit audioPlayerKit;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          SizedBox(
            height: 80,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: TopMenu(audioPlayerKit: audioPlayerKit),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Container(
                decoration: const BoxDecoration(color: ColorMaker.darkGrey),
              ),
            ),
          ),
          SizedBox(
            height: 80,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Center(
                child: audioPlayerKit.trackStreamBuilder((context, duration) =>
                    ScrollAnimationText(
                        text: audioPlayerKit.currentAudioTitle, fontSize: 30)),
              ),
            ),
          ),
        ],
      );
}
