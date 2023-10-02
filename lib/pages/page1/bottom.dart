import 'package:flutter/material.dart';

import './control_section.dart';
import './button_section.dart';

class BottomSection extends StatelessWidget {
  const BottomSection(
      {Key? key,
      required this.duration,
      required this.currentPosition,
      required this.onPlay})
      : super(key: key);
  final Duration duration;
  final Duration currentPosition;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF36081B)),
      child: Column(
        children: [
          const SizedBox(height: 10),
          ControlSection(
            duration: duration,
            currentPosition: currentPosition,
          ),
          const SizedBox(height: 10),
          ButtonSection(onPlay: onPlay),
        ],
      ),
    );
  }
}
