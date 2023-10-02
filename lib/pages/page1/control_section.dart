import 'package:flutter/material.dart';

import './control_bar.dart';
import './control_time.dart';

class ControlSection extends StatelessWidget {
  const ControlSection(
      {Key? key, required this.duration, required this.currentPosition})
      : super(key: key);
  final Duration duration;
  final Duration currentPosition;

  @override
  Widget build(BuildContext context) {
    final double widthRate = (duration.inSeconds > 0)
        ? currentPosition.inSeconds / duration.inSeconds
        : 0;

    return Column(
      children: [
        Container(
          height: 24,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 35.0),
          child: ControlBar(
            widthRate: widthRate,
          ),
        ),
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 35.0),
          child: ControlTime(
            duration: duration,
            currentPosition: currentPosition,
          ),
        ),
      ],
    );
  }
}
