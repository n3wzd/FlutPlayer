import 'package:flutter/material.dart';

import '../components/time_text.dart';

class ControlTime extends StatelessWidget {
  const ControlTime({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            alignment: Alignment.centerLeft,
            child: const TimeText(text: '01:23'),
          ),
        ),
        Expanded(
          child: Container(
            alignment: Alignment.centerRight,
            child: const TimeText(text: '03:40'),
          ),
        ),
      ],
    );
  }
}
