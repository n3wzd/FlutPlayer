import 'package:flutter/material.dart';

class ControlTime extends StatelessWidget {
  const ControlTime({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Text(
          '01:23',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            height: 0,
          ),
        ),
        Text(
          '03:40',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            height: 0,
          ),
        ),
      ],
    );
  }
}
