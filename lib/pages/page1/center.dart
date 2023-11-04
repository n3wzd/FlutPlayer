import 'package:flutter/material.dart';

import '../components/audio_player_kit.dart';
import '../components/text.dart';
import '../components/button.dart';
import '../style/colors.dart';

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
        Row(
          children: [
            SizedBox(
              height: 80,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Row(
                  children: [
                    ButtonMaker.defaultButton(
                      onPressed: audioPlayerKit.filesOpen,
                      text: 'Open',
                    ),
                    const SizedBox(width: 8),
                    ButtonMaker.defaultButton(
                      onPressed: audioPlayerKit.directoryOpen,
                      text: 'Scan',
                    ),
                    const SizedBox(width: 8),
                    TextMaker.defaultText('MASHUP'),
                    StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) =>
                          Checkbox(
                        checkColor: ColorTheme.white,
                        fillColor:
                            MaterialStateProperty.all(ColorTheme.lightWine),
                        value: audioPlayerKit.mashupMode,
                        onChanged: (bool? value) {
                          setState(() {
                            audioPlayerKit.toggleMashupMode();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) => Checkbox(
                checkColor: Colors.white,
                value: audioPlayerKit.mashupMode,
                onChanged: (bool? value) {
                  setState(() {
                    audioPlayerKit.toggleMashupMode();
                    setState(() {});
                  });
                },
              ),
            ),
          ],
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
              child: audioPlayerKit.trackStreamBuilder((context, duration) =>
                  TextMaker.scrollAnimationText(
                      audioPlayerKit.currentAudioTitle,
                      fontSize: 30)),
            ),
          ),
        ),
      ],
    );
  }
}
