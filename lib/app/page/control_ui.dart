import 'package:flutter/material.dart';

import '../collection/audio_player.dart';
import '../component/slider.dart';
import '../component/text.dart';

class ControlUI extends StatefulWidget {
  const ControlUI(
      {Key? key,
      required this.trackDuration,
      required this.trackPosition,
      required this.audioPlayerKit})
      : super(key: key);
  final Duration trackDuration;
  final Duration trackPosition;
  final AudioPlayerKit audioPlayerKit;

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
          child: SliderMaker.normal(
            value: _sliderValue,
            max: silderMax,
            onChanged: (double value) {
              setState(() {
                _sliderValue = value;
                _isSliderChanging = true;
              });
            },
            onChangeEnd: (double value) {
              widget.audioPlayerKit
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
                  child: TextMaker.timeFormat(
                      Duration(milliseconds: _sliderValue.toInt())),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextMaker.timeFormat(widget.trackDuration),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
