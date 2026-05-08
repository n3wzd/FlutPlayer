import 'package:flutter/material.dart';

import './text.dart';
import '../models/color.dart';

class ButtonFactory {
  static Widget textButton({
    required VoidCallback? onPressed,
    required String text,
    double? fontSize,
    bool backgroundTransparent = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.disabled)
              ? ColorPalette.disableGrey
              : (backgroundTransparent
                    ? ColorPalette.transparent
                    : ColorPalette.lightWine);
        }),
        foregroundColor: WidgetStateProperty.all(ColorPalette.white),
        padding: WidgetStateProperty.all(const EdgeInsets.all(16)),
      ),
      child: TextFactory.text(text, fontSize: fontSize),
    );
  }

  static Widget iconButton({
    required Icon icon,
    double iconSize = 35,
    required VoidCallback? onPressed,
    Color? iconColor,
    bool outline = true,
    bool hasOverlay = true,
    bool? isSelected,
    Icon? selectedIcon,
    String? tooltip,
  }) {
    return Theme(
      data: ThemeData(
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            iconColor: WidgetStateProperty.all(ColorPalette.lightGrey),
            backgroundColor: WidgetStateProperty.all(ColorPalette.transparent),
            mouseCursor: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.disabled)
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click;
            }),
            shape: outline
                ? WidgetStateProperty.all(
                    const CircleBorder(
                      side: BorderSide(color: ColorPalette.lightGrey, width: 1),
                    ),
                  )
                : null,
            overlayColor: WidgetStateProperty.resolveWith((
              Set<WidgetState> states,
            ) {
              if (hasOverlay) {
                if (states.contains(WidgetState.pressed)) {
                  return ColorPalette.overlayPressedGrey;
                } else if (states.contains(WidgetState.hovered)) {
                  return ColorPalette.overlayHoveredGrey;
                }
              }
              return ColorPalette.transparent;
            }),
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
        tooltip: tooltip,
        disabledColor: ColorPalette.disableGrey,
      ),
    );
  }
}
