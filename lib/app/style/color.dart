import 'package:flutter/material.dart';

class ColorMaker {
  static const black = Colors.black;
  static const white = Colors.white;
  static const transparent = Colors.transparent;
  static const lightGrey = Color(0xFFD9D9D9);
  static const grey = Color(0xFFAAAAAA);
  static const darkGrey = Color(0xFF1D1D1D);
  static const lightBlack = Color(0xFF111111);
  static const lightWine = Color(0xFF8C003A);
  static const darkWine = Color(0xFF36081B);
  static const purple = Color(0xFF5B2EC5);
  static const overlayHoveredGrey = Color(0x33FFFFFF);
  static const overlayPressedGrey = Color(0x44FFFFFF);
  static const overlayHoveredPurple = Color(0x445B2EC5);
  static const disableGrey = Color(0xff474747);
  static const lightGreySeparator = Color(0x44D9D9D9);
}

/*enum VisualizerColor {
  red('red'),
  orange('orange'),
  yellow('yellow'),
  green('green'),
  mint('mint'),
  cyan('cyan'),
  blue('blue'),
  purple('purple'),
  pink('pink'),
  teal('teal'),
  grey('grey'),
  white('white'),
  black('black'),
  undefined('undefined');

  const VisualizerColor(this.code);
  final String code;

  factory VisualizerColor.toEnum(String code) {
    return VisualizerColor.values.firstWhere((value) => value.code == code,
        orElse: () => VisualizerColor.undefined);
  }

  @override
  String toString() {
    return code;
  }
}*/
