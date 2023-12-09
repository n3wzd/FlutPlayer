import 'package:flutter/material.dart';

import '../utils/audio_player.dart';
import '../utils/preference.dart';
import '../widgets/slider.dart';
import '../widgets/button.dart';
import '../widgets/checkbox.dart';
import '../components/action_button.dart';
import '../models/color.dart';

class TopMenu extends StatelessWidget {
  const TopMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double silderMax = 1.0;
    double silderValue = Preference.volumeMasterRate;
    return Row(
      children: [
        ButtonFactory.iconButton(
          icon: const Icon(Icons.file_open),
          iconSize: 30,
          onPressed: AudioPlayerKit.instance.filesOpen,
          outline: false,
        ),
        const SizedBox(width: 6),
        const Icon(Icons.nightlife, color: ColorPalette.lightWine),
        StatefulBuilder(
          builder: (context, setState) => CheckboxFactory.checkbox(
            value: AudioPlayerKit.instance.mashupMode,
            onChanged: (bool? value) {
              AudioPlayerKit.instance.toggleMashupMode();
              setState(() {});
            },
          ),
        ),
        const SizedBox(width: 6),
        const FullscreenButton(),
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
                          color: ColorPalette.purple),
                      Expanded(
                        child: SliderFactory.slider(
                          value: silderValue,
                          max: silderMax,
                          onChanged: (double value) {
                            silderValue = value;
                            AudioPlayerKit.instance.masterVolume = value;
                            setState(() {});
                          },
                          onChangeEnd: (double value) {
                            Preference.save('volumeMasterRate');
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
