import 'package:flutter/material.dart';

import '../components/audio_player.dart';
import '../components/text.dart';
import '../components/text_scroll.dart';
import '../components/button.dart';
import '../style/colors.dart';

class CenterSection extends StatefulWidget {
  const CenterSection({super.key, required this.audioPlayerKit});
  final AudioPlayerKit audioPlayerKit;

  @override
  State<CenterSection> createState() => _CenterSectionState();
}

class _CenterSectionState extends State<CenterSection> {
  List<String> list = [];
  double silderValue = 1;

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
                      onPressed: widget.audioPlayerKit.filesOpen,
                      text: 'Open',
                    ),
                    /*const SizedBox(width: 8),
                    ButtonMaker.defaultButton(
                      onPressed: widget.audioPlayerKit.directoryOpen,
                      text: 'Scan',
                    ),*/
                    const SizedBox(width: 12),
                    TextMaker.defaultText('MASHUP'),
                    StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) =>
                          Checkbox(
                        checkColor: ColorTheme.white,
                        fillColor:
                            MaterialStateProperty.all(ColorTheme.lightWine),
                        value: widget.audioPlayerKit.mashupMode,
                        onChanged: (bool? value) {
                          setState(() {
                            widget.audioPlayerKit.toggleMashupMode();
                          });
                        },
                      ),
                    ),
                    StatefulBuilder(
                      builder: (context, setState) => SizedBox(
                        width: 100,
                        child: Slider(
                          value: silderValue,
                          max: 1,
                          onChanged: (double value) {
                            setState(() {
                              silderValue = value;
                              widget.audioPlayerKit.masterVolume = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
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
              child:
                  widget.audioPlayerKit.trackStreamBuilder((context, duration) {
                return ScrollAnimationText(
                    text: widget.audioPlayerKit.currentAudioTitle,
                    fontSize: 30);
              }),
            ),
          ),
        ),
      ],
    );
  }
}
