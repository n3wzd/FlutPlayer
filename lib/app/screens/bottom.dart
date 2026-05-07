import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/audio_manager.dart';
import '../components/stream_builder.dart';
import '../models/color.dart';
import '../components/action_button.dart';
import '../widgets/slider.dart';
import '../widgets/text.dart';

class BottomSection extends StatelessWidget {
  const BottomSection({super.key});

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
  const ControlSection({super.key});

  @override
  Widget build(BuildContext context) => AudioStreamBuilder.track(
    (context, duration) =>
        ControlUI(trackDuration: AudioManager.instance.duration),
  );
}

class ControlUI extends StatefulWidget {
  const ControlUI({super.key, required this.trackDuration});
  final Duration trackDuration;

  @override
  State<ControlUI> createState() => _ControlUIState();
}

class _ControlUIState extends State<ControlUI> {
  Timer? _positionTimer;
  double _sliderValue = 0;
  bool _isSliderChanging = false;

  @override
  void initState() {
    super.initState();
    _syncPosition();
    _positionTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _syncPosition(),
    );
  }

  @override
  void didUpdateWidget(ControlUI oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trackDuration != widget.trackDuration) {
      _syncPosition();
    }
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double sliderMax = widget.trackDuration.inMilliseconds.toDouble();
    if (_sliderValue >= sliderMax) {
      _sliderValue = sliderMax;
    }

    return Column(
      children: [
        Container(
          height: 24,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: SliderFactory.slider(
            value: _sliderValue,
            max: sliderMax,
            onChanged: (double value) {
              setState(() {
                _sliderValue = value;
                _isSliderChanging = true;
              });
            },
            onChangeEnd: (double value) {
              AudioManager.instance.seekPosition(
                Duration(milliseconds: value.toInt()),
              );
              setState(() {
                _sliderValue = value;
                _isSliderChanging = false;
              });
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
                    Duration(milliseconds: _sliderValue.toInt()),
                  ),
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

  void _syncPosition() {
    if (!mounted || _isSliderChanging) {
      return;
    }
    final sliderMax = widget.trackDuration.inMilliseconds.toDouble();
    final position = AudioManager.instance.position.inMilliseconds.toDouble();
    setState(() {
      _sliderValue = position.clamp(0, sliderMax).toDouble();
    });
  }
}

class ButtonUI extends StatelessWidget {
  const ButtonUI({super.key});

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
