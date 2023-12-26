import 'package:flutter/material.dart';

import '../utils/audio_manager.dart';
import '../utils/preference.dart';
import '../widgets/slider.dart';
import '../widgets/button.dart';
import '../widgets/checkbox.dart';
import '../components/action_button.dart';
import '../models/color.dart';

class TopMenu extends StatelessWidget {
  const TopMenu({Key? key, required this.onDrawTap}) : super(key: key);
  final VoidCallback onDrawTap;

  @override
  Widget build(BuildContext context) {
    double silderMax = 1.0;
    double silderValue = Preference.volumeMasterRate;
    return Row(
      children: [
        ButtonFactory.iconButton(
          icon: const Icon(Icons.settings),
          iconSize: 26,
          onPressed: onDrawTap,
          outline: false,
          hasOverlay: false,
        ),
        ButtonFactory.iconButton(
          icon: const Icon(Icons.search),
          iconSize: 26,
          onPressed: AudioManager.instance.filesOpen,
          outline: false,
          hasOverlay: false,
        ),
        StatefulBuilder(
          builder: (context, setState) => ButtonFactory.iconButton(
            icon: Icon(Icons.tornado,
                color: AudioManager.instance.mashupMode
                    ? ColorPalette.lightWine
                    : ColorPalette.lightGrey),
            iconSize: 26,
            onPressed: AudioManager.instance.toggleMashupMode,
            outline: false,
            hasOverlay: false,
          ),
        ),
        const FullscreenButton(),
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
                            AudioManager.instance.masterVolume = value;
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
