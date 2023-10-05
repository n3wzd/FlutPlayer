import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

class ControlSlider extends StatefulWidget {
  const ControlSlider(
      {Key? key,
      required this.trackDuration,
      required this.trackCurrentPosition,
      required this.assetsAudioPlayer,
      required this.onUpdated})
      : super(key: key);
  final Duration trackDuration;
  final Duration trackCurrentPosition;
  final AssetsAudioPlayer assetsAudioPlayer;
  final Function(int) onUpdated;

  @override
  State<ControlSlider> createState() => _ControlSliderState();
}

class _ControlSliderState extends State<ControlSlider> {
  double sliderValue = 0;
  bool isChanging = false;

  @override
  Widget build(BuildContext context) {
    if (!isChanging) {
      sliderValue = widget.trackCurrentPosition.inMilliseconds.toDouble();
    }

    return Slider(
      value: sliderValue,
      max: widget.trackDuration.inMilliseconds.toDouble(),
      onChanged: (double value) {
        sliderValue = value;
        isChanging = true;
        setState(() {});
      },
      onChangeEnd: (double value) {
        widget.assetsAudioPlayer.seek(Duration(milliseconds: value.toInt()));
        sliderValue = value;
        isChanging = false;
        widget.onUpdated(value.toInt());
      },
    );
  }
}
