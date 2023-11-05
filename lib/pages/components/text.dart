import 'package:flutter/material.dart';

import '../style/text_style.dart';

class TextMaker {
  static const Color _defaultTextColor = Colors.white;
  static const double _defaultTextFontSize = 16;

  static Text defaultText(String text,
          {Color color = _defaultTextColor,
          double fontSize = _defaultTextFontSize}) =>
      Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyleMaker.defaultTextStyle(
          color: color,
          fontSize: fontSize,
        ),
      );

  static Text timeFormatText(Duration timeValue,
          {Color color = _defaultTextColor,
          double fontSize = _defaultTextFontSize}) =>
      Text(
        getTimeFormat(timeValue),
        style: TextStyleMaker.defaultTextStyle(
          color: color,
          fontSize: fontSize,
        ),
      );

  static String getTimeFormat(Duration d) {
    int minutes = d.inMinutes % 60, seconds = d.inSeconds % 60;
    String minutesPadding = minutes < 10 ? '0' : '';
    String secondsPadding = seconds < 10 ? '0' : '';
    return '$minutesPadding$minutes:$secondsPadding$seconds';
  }

  static LayoutBuilder scrollAnimationText(String text,
      {Color color = _defaultTextColor,
      double fontSize = _defaultTextFontSize}) {
    String space = '        ';
    ScrollController controller = ScrollController();
    double textWidth = getTextWidth(text, fontSize);
    double spaceWidth = getTextWidth(space, fontSize);

    return LayoutBuilder(builder: (context, constraints) {
      bool canScroll = constraints.maxWidth < textWidth;
      return GestureDetector(
          child: SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: TextMaker.defaultText(
              canScroll ? '$text$space$text' : text,
              color: color,
              fontSize: fontSize,
            ),
          ),
          onTap: () async {
            if (canScroll) {
              await controller.animateTo(textWidth + spaceWidth,
                  duration: Duration(
                      milliseconds: 2000000 ~/ (textWidth + spaceWidth)),
                  curve: Curves.linear);
              controller.jumpTo(0);
            }
          });
    });
  }

  static double getTextWidth(String text, double fontSize) {
    TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyleMaker.defaultTextStyle(fontSize: fontSize),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size.width;
  }
}
