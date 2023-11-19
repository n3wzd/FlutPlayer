import 'package:flutter/material.dart';

import '../style/text.dart';

class TextMaker {
  static final _method = TextMakerMethod();

  static normal(String text,
          {Color? color,
          double? fontSize,
          FontWeight? fontWeight,
          bool allowLineBreak = false}) =>
      Text(
        text,
        maxLines: allowLineBreak ? null : 1,
        overflow: allowLineBreak ? null : TextOverflow.ellipsis,
        style: TextStyleMaker.normal(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      );

  static timeFormat(Duration timeValue,
          {Color? color, double? fontSize, FontWeight? fontWeight}) =>
      Text(
        _method._getTimeFormat(timeValue),
        style: TextStyleMaker.normal(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      );
}

class TextMakerMethod {
  _getTimeFormat(Duration d) {
    int minutes = d.inMinutes % 60, seconds = d.inSeconds % 60;
    String minutesPadding = minutes < 10 ? '0' : '';
    String secondsPadding = seconds < 10 ? '0' : '';
    return '$minutesPadding$minutes:$secondsPadding$seconds';
  }
}
