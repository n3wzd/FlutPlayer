import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../component/text.dart';
import '../component/slider.dart';

class EqualizerControls extends StatelessWidget {
  final AndroidEqualizer equalizer;

  const EqualizerControls({
    Key? key,
    required this.equalizer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<AndroidEqualizerParameters>(
        future: equalizer.parameters,
        builder: (context, snapshot) {
          final parameters = snapshot.data;
          if (parameters == null) return const SizedBox();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var band in parameters.bands)
                Expanded(
                  child: Row(
                    children: [
                      TextMaker.normal('${band.centerFrequency.round()} Hz'),
                      Expanded(
                        child: VerticalSlider(
                          min: parameters.minDecibels,
                          max: parameters.maxDecibels,
                          value: band.gain,
                          onChanged: band.setGain,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class VerticalSlider extends StatefulWidget {
  const VerticalSlider({
    Key? key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    required this.onChanged,
  }) : super(key: key);
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  State<VerticalSlider> createState() => _VerticalSliderState();
}

class _VerticalSliderState extends State<VerticalSlider> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return SliderMaker.normal(
      value: _sliderValue,
      min: widget.min,
      max: widget.max,
      onChanged: (value) {
        setState(() {
          _sliderValue = value;
          widget.onChanged(value);
        });
      },
    );
  }
}
