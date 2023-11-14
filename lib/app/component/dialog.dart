import 'package:flutter/material.dart';

import './text.dart';
import './button.dart';
import '../style/color.dart';

class DialogMaker {
  static const _buttonWidth = 80.0;
  static const _dialogTextSize = 20.0;

  static void alertDialog(
          {required context, required onPressed, required text}) =>
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                backgroundColor: ColorMaker.darkGrey,
                content: TextMaker.normal(text, fontSize: 6),
                actions: <Widget>[
                  Center(
                    child: SizedBox(
                      width: _buttonWidth,
                      child: ButtonMaker.text(
                        onPressed: () {
                          onPressed();
                          Navigator.of(context).pop();
                        },
                        text: 'ok',
                      ),
                    ),
                  ),
                ],
              ));

  static void choiceDialog(
          {required BuildContext context,
          required VoidCallback onOkPressed,
          required VoidCallback onCancelPressed,
          required String text}) =>
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                backgroundColor: ColorMaker.darkGrey,
                content: TextMaker.normal(text, fontSize: _dialogTextSize),
                actions: <Widget>[
                  SizedBox(
                    width: _buttonWidth,
                    child: ButtonMaker.text(
                      onPressed: () {
                        onOkPressed();
                        Navigator.of(ctx).pop();
                      },
                      text: 'ok',
                    ),
                  ),
                  SizedBox(
                    width: _buttonWidth,
                    child: ButtonMaker.text(
                      onPressed: () {
                        onCancelPressed();
                        Navigator.of(ctx).pop();
                      },
                      text: 'cancel',
                    ),
                  ),
                ],
              ));
}
