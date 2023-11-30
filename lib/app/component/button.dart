import 'package:flutter/material.dart';

import './text.dart';
import '../style/color.dart';

class ButtonMaker {
  static text(
          {VoidCallback? onPressed,
          required String text,
          double? fontSize,
          bool backgroundTransparent = false}) =>
      ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return ColorMaker.disableGrey;
            } else {
              return backgroundTransparent
                  ? ColorMaker.transparent
                  : ColorMaker.lightWine;
            }
          }),
          foregroundColor: MaterialStateProperty.all(ColorMaker.white),
          padding: MaterialStateProperty.all(const EdgeInsets.all(16)),
          minimumSize:
              MaterialStateProperty.all(Size.fromHeight((fontSize ?? 24) + 16)),
        ),
        child: TextMaker.normal(text, fontSize: fontSize),
      );

  static Theme icon(
          {required Icon icon,
          double iconSize = 35,
          VoidCallback? onPressed,
          Color? color,
          bool outline = true,
          bool? isSelected,
          Icon? selectedIcon}) =>
      ThemeMaker.iconButton(
          IconButton(
            icon: icon,
            color: color,
            iconSize: iconSize,
            onPressed: onPressed,
            isSelected: isSelected,
            selectedIcon: selectedIcon,
            disabledColor: ColorMaker.disableGrey,
          ),
          outline: outline);
}

class ThemeMaker {
  static iconButton(IconButton child, {outline = true}) => Theme(
        data: ThemeData(
          iconButtonTheme: IconButtonThemeData(
            style: ButtonStyle(
              iconColor: MaterialStateProperty.all(ColorMaker.lightGrey),
              backgroundColor:
                  MaterialStateProperty.all(ColorMaker.transparent),
              shape: outline
                  ? MaterialStateProperty.all(const CircleBorder(
                      side: BorderSide(color: ColorMaker.lightGrey, width: 1)))
                  : null,
              overlayColor: MaterialStateProperty.resolveWith(
                  (Set<MaterialState> states) {
                if (states.contains(MaterialState.pressed)) {
                  return ColorMaker.overlayPressedGrey;
                } else if (states.contains(MaterialState.hovered)) {
                  return ColorMaker.overlayHoveredGrey;
                }
                return ColorMaker.transparent;
              }),
            ),
          ),
          useMaterial3: true,
        ),
        child: child,
      );
}
