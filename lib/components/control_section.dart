import 'package:flutter/material.dart';

import './control_bar.dart';
import './control_time.dart';

class ControlSection extends StatelessWidget {
  const ControlSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        ControlBar(),
        ControlTime(),
      ],
    );
  }
}
