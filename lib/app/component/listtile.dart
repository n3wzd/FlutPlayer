import 'package:flutter/material.dart';

import '../style/color.dart';
import './text.dart';

class ListTileMaker {
  static multiItem(
          {required int index,
          required String name,
          VoidCallback? onTap,
          bool selected = false}) =>
      ListTile(
        title: SizedBox(
          height: 60,
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextMaker.normal(
              name,
              fontSize: 18,
            ),
          ),
        ),
        minVerticalPadding: 0,
        onTap: onTap,
        selected: selected,
        selectedTileColor: ColorMaker.lightWine,
        tileColor: index % 2 == 1 ? ColorMaker.darkGrey : ColorMaker.black,
        hoverColor: ColorMaker.lightWine,
      );
}
