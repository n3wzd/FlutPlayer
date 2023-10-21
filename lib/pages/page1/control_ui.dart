import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

import '../components/text_time.dart';

import '../style/colors.dart';

class ControlUI extends StatefulWidget {
  const ControlUI(
      {Key? key,
      required this.trackDuration,
      required this.trackCurrentPosition,
      required this.assetsAudioPlayer})
      : super(key: key);
  final Duration trackDuration;
  final Duration trackCurrentPosition;
  final AssetsAudioPlayer assetsAudioPlayer;

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
    if (_sliderValue > silderMax) {
      _sliderValue = silderMax;
    }

    if (!_isSliderChanging) {
      if (_afterChangedCount <= 0) {
        _sliderValue = widget.trackCurrentPosition.inMilliseconds.toDouble();
      } else {
        _afterChangedCount--;
      }
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
              widget.assetsAudioPlayer
                  .seek(Duration(milliseconds: value.toInt()));
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
                  child: TimeText(
                      timeValue: Duration(milliseconds: _sliderValue.toInt())),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TimeText(timeValue: widget.trackDuration),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
