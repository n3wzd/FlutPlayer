import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

import '../components/audio_player_kit.dart';
import '../style/colors.dart';

class CenterSection extends StatelessWidget {
  CenterSection({
    Key? key,
    required this.audioPlayerKit,
  }) : super(key: key);
  final AudioPlayerKit audioPlayerKit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35),
            child: ElevatedButton(
              onPressed: audioPlayerKit.filesOpen,
              child: const Text('Open'),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35),
            child: Container(
              decoration: const BoxDecoration(color: ColorTheme.darkGrey),
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Center(
              child: audioPlayerKit
                  .durationStreamBuilder((context, duration) => Marquee(
                        text: audioPlayerKit.currentAudioTitle,
                      )),
            ),
          ),
        ),
      ],
    );
  }
}
