import 'package:flutter/material.dart';

import './text.dart';
import '../models/color.dart';

class ButtonFactory {
  static textButton({
    required VoidCallback? onPressed,
    required String text,
    double? fontSize,
    bool backgroundTransparent = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          return states.contains(MaterialState.disabled)
              ? ColorPalette.disableGrey
              : (backgroundTransparent
                  ? ColorPalette.transparent
                  : ColorPalette.lightWine);
        }),
        foregroundColor: MaterialStateProperty.all(ColorPalette.white),
        padding: MaterialStateProperty.all(const EdgeInsets.all(16)),
      ),
      child: TextFactory.text(text, fontSize: fontSize),
    );
  }

  static iconButton(
      {required Icon icon,
      double iconSize = 35,
      required VoidCallback? onPressed,
      Color? iconColor,
      bool outline = true,
      bool hasOverlay = true,
      bool? isSelected,
      Icon? selectedIcon}) {
    return Theme(
      data: ThemeData(
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            iconColor: MaterialStateProperty.all(ColorPalette.lightGrey),
            backgroundColor:
                MaterialStateProperty.all(ColorPalette.transparent),
            shape: outline
                ? MaterialStateProperty.all(
                    const CircleBorder(
                      side: BorderSide(
                        color: ColorPalette.lightGrey,
                        width: 1,
                      ),
                    ),
                  )
                : null,
            overlayColor: MaterialStateProperty.resolveWith(
              (Set<MaterialState> states) {
                if (hasOverlay) {
                  if (states.contains(MaterialState.pressed)) {
                    return ColorPalette.overlayPressedGrey;
                  } else if (states.contains(MaterialState.hovered)) {
                    return ColorPalette.overlayHoveredGrey;
                  }
                }
                return ColorPalette.transparent;
              },
            ),
          ),
        ),
        useMaterial3: true,
      ),
      child: IconButton(
        icon: icon,
        color: iconColor,
        iconSize: iconSize,
        onPressed: onPressed,
        isSelected: isSelected,
        selectedIcon: selectedIcon,
        disabledColor: ColorPalette.disableGrey,
      ),
    );
  }
}
