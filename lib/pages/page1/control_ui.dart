import 'package:flutter/material.dart';

import '../components/audio_player_kit.dart';
import '../components/text.dart';
import '../style/colors.dart';

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
      _sliderValue = 0;
      silderMax = 1;
    }

    return Column(
      children: [
        Container(
          height: 24,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Slider(
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
            thumbColor: ColorTheme.purple,
            activeColor: ColorTheme.purple,
            inactiveColor: ColorTheme.lightGrey,
            overlayColor:
                MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.hovered)) {
                return ColorTheme.overlayHoveredPurple;
              }
              return ColorTheme.transparent;
            }),
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
                  child: TextMaker.timeFormatText(
                      Duration(milliseconds: _sliderValue.toInt())),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextMaker.timeFormatText(widget.trackDuration),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
