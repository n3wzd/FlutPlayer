import 'package:flutter/material.dart';

import './text.dart';
import '../style/color.dart';
import '../style/theme.dart';

class ButtonMaker {
  static ElevatedButton text(
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

  static Theme icon(
          {required Icon icon,
          double iconSize = 35,
          required VoidCallback onPressed,
          bool outline = true,
          bool? isSelected,
          Icon? selectedIcon}) =>
      ThemeMaker.iconButton(
          IconButton(
            icon: icon,
            iconSize: iconSize,
            onPressed: onPressed,
            isSelected: isSelected,
            selectedIcon: selectedIcon,
          ),
          outline: outline);
}
