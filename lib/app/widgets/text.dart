import 'package:flutter/material.dart';

import '../models/color.dart';

class TextFactory {
  static text(String text,
          {Color? color,
          double? fontSize,
          FontWeight? fontWeight,
          bool allowLineBreak = false,
          TextStyle? style}) =>
      Text(
        text,
        maxLines: allowLineBreak ? null : 1,
        overflow: allowLineBreak ? null : TextOverflow.ellipsis,
        style: style ??
            TextStyleFactory.style(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
      );

  static timeFormatText(Duration timeValue,
          {Color? color, double? fontSize, FontWeight? fontWeight}) =>
      Text(
        getTimeFormat(timeValue),
        style: TextStyleFactory.style(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      );

  static scrollAnimationText(
          {required String text, Color? color, double? fontSize}) =>
      ScrollAnimationText(
        text: text,
        color: color,
        fontSize: fontSize,
      );
}

class TextStyleFactory {
  static style(
          {Color? color,
          double? fontSize,
          FontWeight? fontWeight,
          Paint? foreground}) =>
      TextStyle(
        color: color ?? ColorPalette.lightGrey,
        fontSize: fontSize ?? 16,
        fontFamily: 'Inter',
        fontWeight: fontWeight ?? FontWeight.normal,
        foreground: foreground,
      );
}

class ScrollAnimationText extends StatefulWidget {
  const ScrollAnimationText(
      {super.key, required this.text, this.color, this.fontSize});
  final String text;
  final Color? color;
  final double? fontSize;
  final String space = '        ';

  @override
  State<ScrollAnimationText> createState() => _ScrollAnimationTextState();
}

class _ScrollAnimationTextState extends State<ScrollAnimationText> {
  final _controller = ScrollController();

  @override
  Widget build(context) {
    if (_controller.hasClients) {
      _controller.jumpTo(0);
    }
    double textWidth = getTextWidth(widget.text, widget.fontSize);
    double spaceWidth = getTextWidth(widget.space, widget.fontSize);

    return LayoutBuilder(builder: (context, constraints) {
      bool canScroll = constraints.maxWidth < textWidth;
      return GestureDetector(
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: TextFactory.text(
              canScroll
                  ? '${widget.text}${widget.space}${widget.text}'
                  : widget.text,
              color: widget.color,
              fontSize: widget.fontSize,
            ),
          ),
          onTap: () async {
            if (canScroll) {
              await _controller.animateTo(textWidth + spaceWidth,
                  duration: Duration(
                      milliseconds: ((textWidth + spaceWidth) ~/ 20) * 100),
                  curve: Curves.linear);
              _controller.jumpTo(0);
            }
          });
    });
  }

  static getTextWidth(text, fontSize) {
    TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyleFactory.style(fontSize: fontSize),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size.width;
  }
}

getTimeFormat(Duration d) {
  int minutes = d.inMinutes % 60, seconds = d.inSeconds % 60;
  String minutesPadding = minutes < 10 ? '0' : '';
  String secondsPadding = seconds < 10 ? '0' : '';
  return '$minutesPadding$minutes:$secondsPadding$seconds';
}
