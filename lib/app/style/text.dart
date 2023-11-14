import 'package:flutter/material.dart';

class TextStyleMaker {
  static normal({Color color = Colors.white, required double fontSize}) =>
      TextStyle(
        color: color,
        fontSize: fontSize,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
      );
}
