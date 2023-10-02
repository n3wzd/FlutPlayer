import 'package:flutter/material.dart';

class ControlBar extends StatelessWidget {
  const ControlBar({Key? key, required this.widthRate}) : super(key: key);
  final double widthRate;

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
        FractionallySizedBox(
          widthFactor: widthRate,
          alignment: FractionalOffset.centerLeft,
          child: Container(
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
        ),
      ],
    );
  }
}
