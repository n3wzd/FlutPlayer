import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  const Button(
      {Key? key,
      required this.buttonRadius,
      required this.icon,
      required this.onPressed})
      : super(key: key);
  final double buttonRadius;
  final Icon icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: buttonRadius,
      height: buttonRadius,
      decoration: ShapeDecoration(
        color: Colors.white.withOpacity(0),
        shape: OvalBorder(
          side: BorderSide(
            width: 1,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ),
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
      ),
    );
  }
}
