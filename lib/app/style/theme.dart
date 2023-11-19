import 'package:flutter/material.dart';

import './color.dart';

class ThemeMaker {
  static iconButton(child, {outline = true}) => Theme(
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
