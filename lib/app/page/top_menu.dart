import 'package:flutter/material.dart';

import '../collection/audio_player.dart';
import '../collection/preference.dart';
import '../component/slider.dart';
import '../component/button.dart';
import '../component/checkbox.dart';
import '../style/color.dart';

class TopMenu extends StatelessWidget {
  const TopMenu({Key? key, required this.audioPlayerKit}) : super(key: key);
  final AudioPlayerKit audioPlayerKit;

  @override
  Widget build(BuildContext context) {
    double silderMax = 1.0;
    double silderValue = silderMax;
    return Row(
      children: [
        ButtonMaker.icon(
          icon: const Icon(Icons.file_open),
          iconSize: 30,
          onPressed: audioPlayerKit.filesOpen,
          outline: false,
        ),
        const SizedBox(width: 6),
        const Icon(Icons.nightlife, color: ColorMaker.lightWine),
        StatefulBuilder(
          builder: (context, setState) => CheckboxMaker.normal(
            value: audioPlayerKit.mashupMode,
            onChanged: (bool? value) {
              audioPlayerKit.toggleMashupMode();
              setState(() {});
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Visibility(
              visible: MediaQuery.of(context).size.width >= 356,
              child: SizedBox(
                width: 160,
                child: StatefulBuilder(
                  builder: (context, setState) => Row(
                    children: [
                      Icon(
                          silderValue > silderMax / 2
                              ? Icons.volume_up
                              : (silderValue > 0
                                  ? Icons.volume_down
                                  : Icons.volume_mute),
                          color: ColorMaker.purple),
                      Expanded(
                        child: SliderMaker.normal(
                          value: silderValue,
                          max: silderMax,
                          onChanged: (double value) {
                            silderValue = value;
                            audioPlayerKit.masterVolume = value;
                            setState(() {});
                          },
                          onChangeEnd: (double value) {
                            Preference.save();
                          },
                          useOverlayColor: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}
