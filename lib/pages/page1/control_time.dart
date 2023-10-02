import 'package:flutter/material.dart';

import '../components/time_text.dart';

class ControlTime extends StatelessWidget {
  const ControlTime(
      {Key? key, required this.duration, required this.currentPosition})
      : super(key: key);
  final Duration duration;
  final Duration currentPosition;

  String getTimeFormat(Duration d) {
    int minutes = d.inMinutes % 60, seconds = d.inSeconds % 60;
    String minutesPadding = minutes < 10 ? '0' : '';
    String secondsPadding = seconds < 10 ? '0' : '';
    return '$minutesPadding$minutes:$secondsPadding$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            alignment: Alignment.centerLeft,
            child: TimeText(text: getTimeFormat(currentPosition)),
          ),
        ),
        Expanded(
          child: Container(
            alignment: Alignment.centerRight,
            child: TimeText(text: getTimeFormat(duration)),
          ),
        ),
      ],
    );
  }
}
