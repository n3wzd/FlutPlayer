import 'package:flutter/material.dart';

class TimeText extends StatelessWidget {
  const TimeText({Key? key, required this.timeValue}) : super(key: key);
  final Duration timeValue;

  String getTimeFormat(Duration d) {
    int minutes = d.inMinutes % 60, seconds = d.inSeconds % 60;
    String minutesPadding = minutes < 10 ? '0' : '';
    String secondsPadding = seconds < 10 ? '0' : '';
    return '$minutesPadding$minutes:$secondsPadding$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      getTimeFormat(timeValue),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        height: 0,
      ),
    );
  }
}
