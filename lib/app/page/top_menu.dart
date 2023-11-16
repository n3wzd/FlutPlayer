import 'package:flutter/material.dart';

import '../collection/audio_player.dart';
import '../component/slider.dart';
import '../style/color.dart';
import '../style/theme.dart';

class TopMenu extends StatelessWidget {
  const TopMenu({Key? key, required this.audioPlayerKit}) : super(key: key);
  final AudioPlayerKit audioPlayerKit;

  @override
  Widget build(BuildContext context) {
    double silderMax = 1.0;
    double silderValue = silderMax;
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Row(
            children: [
              ThemeMaker.iconButton(
                outline: false,
                IconButton(
                  icon: const Icon(Icons.file_open),
                  iconSize: 30,
                  onPressed: audioPlayerKit.filesOpen,
                ),
              ),
              ThemeMaker.iconButton(
                outline: false,
                IconButton(
                  icon: const Icon(Icons.delete, color: ColorMaker.lightGrey),
                  iconSize: 25,
                  onPressed: audioPlayerKit.clearPlayList,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.nightlife, color: ColorMaker.lightWine),
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) =>
                    Checkbox(
                  checkColor: ColorMaker.white,
                  fillColor: MaterialStateProperty.all(ColorMaker.lightWine),
                  value: audioPlayerKit.mashupMode,
                  onChanged: (bool? value) {
                    setState(() {
                      audioPlayerKit.toggleMashupMode();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
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
                            setState(() {
                              silderValue = value;
                              audioPlayerKit.masterVolume = value;
                            });
                          },
                          useOverlayColor: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
