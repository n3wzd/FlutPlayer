import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  const Button({Key? key, required this.buttonRadius}) : super(key: key);
  final double buttonRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: buttonRadius,
      height: buttonRadius,
      padding: const EdgeInsets.all(10.0),
      decoration: ShapeDecoration(
        color: Colors.white.withOpacity(0),
        shape: OvalBorder(
          side: BorderSide(
            width: 1,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
