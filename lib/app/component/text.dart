import 'package:flutter/material.dart';

import '../style/text.dart';

class TextMaker {
  static const _defaultTextColor = Colors.white;
  static const _defaultTextFontSize = 16.0;
  static final _method = TextMakerMethod();

  static normal(text,
          {color = _defaultTextColor, fontSize = _defaultTextFontSize}) =>
      Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyleMaker.normal(
          color: color,
          fontSize: fontSize,
        ),
      );

  static timeFormat(timeValue,
          {color = _defaultTextColor, fontSize = _defaultTextFontSize}) =>
      Text(
        _method._getTimeFormat(timeValue),
        style: TextStyleMaker.normal(
          color: color,
          fontSize: fontSize,
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
