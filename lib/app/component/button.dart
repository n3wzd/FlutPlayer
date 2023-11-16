import 'package:flutter/material.dart';

import './text.dart';
import '../style/color.dart';

class ButtonMaker {
  static text({required VoidCallback onPressed, required String text}) =>
      ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(ColorMaker.lightWine),
          foregroundColor: MaterialStateProperty.all(ColorMaker.white),
        ),
        child: TextMaker.normal(text),
      );
}
