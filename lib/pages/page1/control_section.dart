import 'package:flutter/material.dart';

import './control_bar.dart';
import './control_time.dart';

class ControlSection extends StatelessWidget {
  const ControlSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 24,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 35.0),
          child: const ControlBar(),
        ),
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 35.0),
          child: const ControlTime(),
        ),
      ],
    );
  }
}
