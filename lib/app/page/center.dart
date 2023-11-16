import 'package:flutter/material.dart';

import '../collection/audio_player.dart';
import '../component/text_scroll.dart';
import '../style/color.dart';

class CenterSection extends StatelessWidget {
  const CenterSection({super.key, required this.audioPlayerKit});
  final AudioPlayerKit audioPlayerKit;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const SizedBox(
            height: 45,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 45),
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
