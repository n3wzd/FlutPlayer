import 'package:flutter/material.dart';

import './color.dart';

class TextStyleMaker {
  static normal({Color? color, double? fontSize, FontWeight? fontWeight}) =>
      TextStyle(
        color: color ?? ColorMaker.lightGrey,
        fontSize: fontSize ?? 16,
        fontFamily: 'Inter',
        fontWeight: fontWeight ?? FontWeight.normal,
      );
}
