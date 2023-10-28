import 'package:flutter/material.dart';

import '../components/audio_player_kit.dart';
import '../style/colors.dart';
import '../style/text.dart';

class CenterSection extends StatelessWidget {
  const CenterSection({
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
          child: ElevatedButton(
            onPressed: audioPlayerKit.filesOpen,
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
            child: Text(
              audioPlayerKit.currentAudioTitle,
              style: TextStyleMaker.defaultTextStyle(
                color: ColorTheme.white,
                fontSize: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
