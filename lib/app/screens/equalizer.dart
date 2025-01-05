import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'dart:async';

import '../utils/audio_manager.dart';
import '../utils/preference.dart';
import '../widgets/text.dart';
import '../widgets/slider.dart';
import '../widgets/button.dart';
import '../widgets/checkbox.dart';
import '../models/color.dart';

class EqualizerControls extends StatefulWidget {
  const EqualizerControls({Key? key}) : super(key: key);

  @override
  State<EqualizerControls> createState() => _EqualizerControlsState();
}

class _EqualizerControlsState extends State<EqualizerControls> {
  final _sliderStreamController = StreamController<void>.broadcast();
  late final int bandsLength;
  final int smoothSliderContant = 20;
  List<BandItem> bands = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    final parameters =
        await AudioManager.instance.audioPlayer.equalizer.parameters;
    bandsLength = parameters.bands.length;
    bands = List<BandItem>.generate(
        bandsLength,
        (index) => BandItem(
              band: parameters.bands[index],
              minDecibels: parameters.minDecibels,
              maxDecibels: parameters.maxDecibels,
              index: index,
              sliderValue: parameters.bands[index].gain,
            ));
    setState(() {});
  }

  void gainUpdate(int idx, double value) {
    bands[idx].sliderValue = value;
    bands[idx].band.setGain(bands[idx].sliderValue);
    if (Preference.smoothSliderEqualizer) {
      int lo = idx - 1, hi = idx + 1;
      while (lo >= 0) {
        bands[lo].sliderValue +=
            (bands[lo + 1].sliderValue - bands[lo].sliderValue) /
                smoothSliderContant;
        bands[lo].band.setGain(bands[lo].sliderValue);
        lo--;
      }
      while (hi < bands.length) {
        bands[hi].sliderValue +=
            (bands[hi - 1].sliderValue - bands[hi].sliderValue) /
                smoothSliderContant;
        bands[hi].band.setGain(bands[hi].sliderValue);
        hi++;
      }
    }
    AudioManager.instance.syncEqualizer();
  }

  void gainReset() {
    for (var bandItem in bands) {
      bandItem.sliderValue = (bandItem.maxDecibels + bandItem.minDecibels) / 2;
      bandItem.band.setGain(bandItem.sliderValue);
    }
    AudioManager.instance.syncEqualizer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.black,
      appBar: AppBar(
        title: Row(
          children: [
            TextFactory.text('enabled'),
            StatefulBuilder(
              builder: (context, setCheckBoxState) => CheckboxFactory.checkbox(
                value: Preference.enableEqualizer,
                onChanged: (bool? value) {
                  Preference.enableEqualizer = !Preference.enableEqualizer;
                  Preference.save('enableEqualizer');
                  AudioManager.instance.setEnabledEqualizer();
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 16),
            TextFactory.text('smooth slider'),
            StatefulBuilder(
              builder: (context, setCheckBoxState) => CheckboxFactory.checkbox(
                value: Preference.smoothSliderEqualizer,
                onChanged: Preference.enableEqualizer
                    ? (bool? value) {
                        Preference.smoothSliderEqualizer =
                            !Preference.smoothSliderEqualizer;
                        Preference.save('smoothSliderEqualizer');
                        setCheckBoxState(() {});
                      }
                    : null,
              ),
            ),
          ],
        ),
        backgroundColor: ColorPalette.transparent,
        automaticallyImplyLeading: false,
        actions: [
          ButtonFactory.textButton(
              onPressed: Preference.enableEqualizer
                  ? () {
                      gainReset();
                      _sliderStreamController.add(null);
                    }
                  : null,
              text: 'reset'),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var bandItem in bands)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: StreamBuilder(
                  stream: _sliderStreamController.stream,
                  builder: (context, data) => Row(
                    children: [
                      TextFactory.text(
                          '${bandItem.band.centerFrequency.round()}Hz'),
                      Expanded(
                        child: SliderFactory.slider(
                          min: bandItem.minDecibels,
                          max: bandItem.maxDecibels,
                          value: bandItem.sliderValue,
                          onChanged: Preference.enableEqualizer
                              ? (double value) {
                                  gainUpdate(bandItem.index, value);
                                  _sliderStreamController.add(null);
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const OKButton(),
        ],
      ),
    );
  }
}

class OKButton extends StatelessWidget {
  const OKButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
      alignment: Alignment.bottomCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ButtonFactory.textButton(
              onPressed: () {
                Navigator.pop(context);
              },
              text: 'ok',
              fontSize: 24),
        ],
      ));
}

class BandItem {
  BandItem({
    required this.band,
    required this.minDecibels,
    required this.maxDecibels,
    required this.index,
    required this.sliderValue,
  });
  final AndroidEqualizerBand band;
  final double minDecibels;
  final double maxDecibels;
  final int index;
  double sliderValue;
}
