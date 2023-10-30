import 'package:flutter/material.dart';

import '../style/text_style.dart';

class TextMaker {
  static const Color _defaultTextColor = Colors.white;
  static const double _defaultTextFontSize = 16;
  static String getTimeFormat(Duration d) {
    int minutes = d.inMinutes % 60, seconds = d.inSeconds % 60;
    String minutesPadding = minutes < 10 ? '0' : '';
    String secondsPadding = seconds < 10 ? '0' : '';
    return '$minutesPadding$minutes:$secondsPadding$seconds';
  }

  static Text defaultText(String value,
      {Color color = _defaultTextColor,
      double fontSize = _defaultTextFontSize}) {
    return Text(
      value,
      //maxLines: 1,
      //overflow: TextOverflow.ellipsis,
      style: TextStyleMaker.defaultTextStyle(
        color: color,
        fontSize: fontSize,
      ),
    );
  }

  static Text timeFormatText(Duration timeValue,
      {Color color = _defaultTextColor,
      double fontSize = _defaultTextFontSize}) {
    return Text(
      getTimeFormat(timeValue),
      style: TextStyleMaker.defaultTextStyle(
        color: color,
        fontSize: fontSize,
      ),
    );
  }
}
