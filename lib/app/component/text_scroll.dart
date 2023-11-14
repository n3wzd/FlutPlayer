import 'package:flutter/material.dart';

import './text.dart';
import '../style/text.dart';
import '../style/color.dart';

class ScrollAnimationText extends StatefulWidget {
  const ScrollAnimationText(
      {super.key,
      required this.text,
      this.color = ColorMaker.white,
      this.fontSize = 16});
  final String text;
  final Color color;
  final double fontSize;
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
            child: TextMaker.normal(
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
          style: TextStyleMaker.normal(fontSize: fontSize),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size.width;
  }
}
