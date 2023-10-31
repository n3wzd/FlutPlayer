import 'package:flutter/material.dart';

class TextStyleMaker {
  static TextStyle defaultTextStyle(
      {Color color = Colors.white, required double fontSize}) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w400,
    );
  }
}
