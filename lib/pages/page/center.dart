import 'package:flutter/material.dart';

import '../components/audio_player_kit.dart';
import '../components/text.dart';
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
                    const SizedBox(width: 8),
                    /*ButtonMaker.defaultButton(
                      onPressed: widget.audioPlayerKit.directoryOpen,
                      text: 'Scan',
                    ),*/
                    const SizedBox(width: 8),
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
                  ],
                ),
              ),
            ),
            StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) => Checkbox(
                checkColor: Colors.white,
                value: widget.audioPlayerKit.mashupMode,
                onChanged: (bool? value) {
                  setState(() {
                    widget.audioPlayerKit.toggleMashupMode();
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
        /*StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
          return Column(
            children: [
              ButtonMaker.defaultButton(
                onPressed: () async {
                  list = await widget.audioPlayerKit.directoryOpen();
                  setState(() {});
                },
                text: 'GO!!!',
              ),
              SizedBox(
                width: 280,
                child: Text(
                  list.toString(),
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          );
        }),*/
        SizedBox(
          height: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Center(
              child:
                  widget.audioPlayerKit.trackStreamBuilder((context, duration) {
                return TextMaker.scrollAnimationText(
                    widget.audioPlayerKit.currentAudioTitle,
                    fontSize: 30);
              }),
            ),
          ),
        ),
      ],
    );
  }
}
