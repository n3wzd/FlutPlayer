import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'dart:async';

import '../collection/audio_player.dart';
import '../collection/preference.dart';
import '../component/text.dart';
import '../component/slider.dart';
import '../component/button.dart';
import '../component/checkbox.dart';
import '../style/color.dart';

class EqualizerControls extends StatefulWidget {
  const EqualizerControls({
    Key? key,
    required this.audioPlayerKit,
  }) : super(key: key);
  final AudioPlayerKit audioPlayerKit;

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
    final parameters = await widget.audioPlayerKit.equalizer.parameters;
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
    widget.audioPlayerKit.syncEqualizer();
  }

  void gainReset() {
    for (var bandItem in bands) {
      bandItem.sliderValue = (bandItem.maxDecibels + bandItem.minDecibels) / 2;
      bandItem.band.setGain(bandItem.sliderValue);
    }
    widget.audioPlayerKit.syncEqualizer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorMaker.black,
      appBar: AppBar(
        title: Row(
          children: [
            TextMaker.normal('enabled'),
            StatefulBuilder(
              builder: (context, setCheckBoxState) => CheckboxMaker.normal(
                value: Preference.enableEqualizer,
                onChanged: (bool? value) {
                  Preference.enableEqualizer = !Preference.enableEqualizer;
                  Preference.save();
                  widget.audioPlayerKit.setEnabledEqualizer();
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 16),
            TextMaker.normal('smooth slider'),
            StatefulBuilder(
              builder: (context, setCheckBoxState) => CheckboxMaker.normal(
                value: Preference.smoothSliderEqualizer,
                onChanged: Preference.enableEqualizer
                    ? (bool? value) {
                        Preference.smoothSliderEqualizer =
                            !Preference.smoothSliderEqualizer;
                        Preference.save();
                        setCheckBoxState(() {});
                      }
                    : null,
              ),
            ),
          ],
        ),
        backgroundColor: ColorMaker.transparent,
        automaticallyImplyLeading: false,
        actions: [
          ButtonMaker.text(
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
                      TextMaker.normal(
                          '${bandItem.band.centerFrequency.round()}Hz'),
                      Expanded(
                        child: SliderMaker.normal(
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
          ButtonMaker.text(
              onPressed: () {
                Preference.save();
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
