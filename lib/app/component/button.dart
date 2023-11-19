import 'package:flutter/material.dart';

import './text.dart';
import '../style/color.dart';

class ButtonMaker {
  static text(
          {required VoidCallback onPressed,
          required String text,
          double? fontSize,
          bool backgroundTransparent = false}) =>
      ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(backgroundTransparent
              ? ColorMaker.transparent
              : ColorMaker.lightWine),
          foregroundColor: MaterialStateProperty.all(ColorMaker.white),
          padding: MaterialStateProperty.all(const EdgeInsets.all(16)),
        ),
        child: TextMaker.normal(text, fontSize: fontSize),
      );
}
