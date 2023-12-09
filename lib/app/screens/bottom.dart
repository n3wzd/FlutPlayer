import 'package:flutter/material.dart';

import '../utils/audio_player.dart';
import '../components/stream_builder.dart';
import '../models/color.dart';
import '../components/action_button.dart';
import '../widgets/slider.dart';
import '../widgets/text.dart';

class BottomSection extends StatelessWidget {
  const BottomSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(color: ColorPalette.darkWine),
        child: const Column(
          children: [
            SizedBox(height: 10),
            ControlSection(),
            SizedBox(height: 10),
            ButtonUI(),
          ],
        ),
      );
}

class ControlSection extends StatelessWidget {
  const ControlSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => AudioStreamBuilder.track(
        (context, duration) => AudioStreamBuilder.position(
          (context, position) => ControlUI(
            trackDuration: AudioPlayerKit.instance.duration,
            trackPosition: position.data ?? const Duration(),
          ),
        ),
      );
}

class ControlUI extends StatefulWidget {
  const ControlUI(
      {Key? key, required this.trackDuration, required this.trackPosition})
      : super(key: key);
  final Duration trackDuration;
  final Duration trackPosition;

  @override
  State<ControlUI> createState() => _ControlUIState();
}

class _ControlUIState extends State<ControlUI> {
  double _sliderValue = 0;
  bool _isSliderChanging = false;
  int _afterChangedCount = 2;

  @override
  Widget build(BuildContext context) {
    double silderMax = widget.trackDuration.inMilliseconds.toDouble();
    if (!_isSliderChanging) {
      if (_afterChangedCount <= 0) {
        _sliderValue = widget.trackPosition.inMilliseconds.toDouble();
      } else {
        _afterChangedCount--;
      }
    }
    if (_sliderValue >= silderMax) {
      _sliderValue = silderMax;
    }

    return Column(
      children: [
        Container(
          height: 24,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: SliderFactory.slider(
            value: _sliderValue,
            max: silderMax,
            onChanged: (double value) {
              setState(() {
                _sliderValue = value;
                _isSliderChanging = true;
              });
            },
            onChangeEnd: (double value) {
              AudioPlayerKit.instance
                  .seekPosition(Duration(milliseconds: value.toInt()));
              _isSliderChanging = false;
              _afterChangedCount = 2;
            },
          ),
        ),
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 35.0),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextFactory.timeFormatText(
                      Duration(milliseconds: _sliderValue.toInt())),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextFactory.timeFormatText(widget.trackDuration),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ButtonUI extends StatelessWidget {
  const ButtonUI({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShuffleButton(),
          SizedBox(width: 20),
          SeekToPreviousButton(),
          SizedBox(width: 20),
          PlayButton(iconSize: 55),
          SizedBox(width: 20),
          SeekToNextButton(),
          SizedBox(width: 20),
          LoopButton(),
        ],
      );
}
