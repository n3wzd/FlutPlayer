import 'package:flutter/material.dart';

class ColorPalette {
  static const black = Colors.black;
  static const white = Colors.white;
  static const transparent = Colors.transparent;
  static const lightGrey = Color(0xffd9d9d9);
  static const grey = Color(0xffaaaaaa);
  static const darkGrey = Color(0xff1d1d1d);
  static const lightBlack = Color(0xff111111);
  static const lightWine = Color(0xff8c003a);
  static const darkWine = Color(0xff36081b);
  static const purple = Color(0xff5b2ec5);
  static const overlayHoveredGrey = Color(0x33ffffff);
  static const overlayPressedGrey = Color(0x44ffffff);
  static const overlayHoveredPurple = Color(0x445b2ec5);
  static const disableGrey = Color(0xff474747);
  static const lightGreySeparator = Color(0x44d9d9d9);
}

String colorToString(Color data) => data.toString().substring(10, 16);
Color stringToColor(String data) => Color(int.parse('0xff$data'));

Map<String, String> defaultVisualizerColors = {
  'red': 'ff0000',
  'orange': 'ff6f2c',
  'yellow': 'ffff00',
  'mint': '22ff98',
  'green': '09ff0B',
  'cyan': '00ffff',
  'light blue': '459dff',
  'blue': '1865f9',
  'purple': '8B46ff',
  'lavender': '9570ff',
  'pink': 'ff08c2',
  'teal': '488485',
  'white': 'ffffff',
  'grey': '898989',
  'black': '000000',
};
