import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../style/colors.dart';
import '../style/text.dart';

class CenterSection extends StatelessWidget {
  const CenterSection({
    Key? key,
    required this.audioPlayer,
    required this.filesOpen,
  }) : super(key: key);
  final AudioPlayer audioPlayer;
  final VoidCallback filesOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 80,
          child: ElevatedButton(
            onPressed: filesOpen,
            child: const Text('Open'),
          ),
        ),
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 35.0, vertical: 10.0),
            child: Container(
              decoration: const BoxDecoration(color: ColorTheme.darkGrey),
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: Container(
            alignment: Alignment.center,
            child: StreamBuilder<int?>(
                stream: audioPlayer.currentIndexStream,
                builder: (context, sequenceState) {
                  return Text(
                    '${audioPlayer.sequence![audioPlayer.currentIndex ?? 0].tag.title}',
                    style: TextStyleMaker.defaultTextStyle(
                      color: ColorTheme.white,
                      fontSize: 30,
                    ),
                  );
                }),
          ),
        ),
      ],
    );
  }
}
