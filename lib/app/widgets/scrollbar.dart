import 'package:flutter/material.dart';

import '../models/color.dart';

class ScrollbarFactory {
  static scrollbar({
    required Widget child,
    required ScrollController controller,
  }) {
    return Theme(
      data: ThemeData(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: MaterialStateProperty.all<Color>(ColorPalette.lightGrey),
        ),
      ),
      child: Scrollbar(
        controller: controller,
        child: child,
      ),
    );
  }
}
