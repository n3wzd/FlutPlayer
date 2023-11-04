import 'package:flutter/material.dart';

import './text.dart';
import '../style/colors.dart';

class ButtonMaker {
  static ElevatedButton defaultButton(
          {required VoidCallback onPressed, required String text}) =>
      ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(ColorTheme.lightWine),
          foregroundColor: MaterialStateProperty.all(ColorTheme.white),
        ),
        child: TextMaker.defaultText(text),
      );
}
