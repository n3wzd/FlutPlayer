import 'package:flutter/material.dart';

class ControlBar extends StatelessWidget {
  const ControlBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 1,
          decoration: const ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 2,
                strokeAlign: BorderSide.strokeAlignCenter,
                color: Color(0xFF694655),
              ),
            ),
          ),
        ),
        Container(
          height: 1,
          decoration: const ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 4,
                strokeAlign: BorderSide.strokeAlignCenter,
                color: Color(0xFF5B2EC5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
