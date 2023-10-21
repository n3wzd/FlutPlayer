import 'package:flutter/material.dart';

class TextStyleMaker {
  static TextStyle defaultTextStyle(
      {required Color color, required double fontSize}) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w400,
      height: 0,
    );
  }
}
