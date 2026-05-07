import 'package:flutter/material.dart';

import '../models/color.dart';

class ScrollbarFactory {
  static Widget scrollbar({
    required Widget child,
    required ScrollController controller,
  }) {
    return Theme(
      data: ThemeData(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all<Color>(ColorPalette.lightGrey),
        ),
      ),
      child: Scrollbar(controller: controller, child: child),
    );
  }
}
