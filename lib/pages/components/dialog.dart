import 'package:flutter/material.dart';

import './text.dart';
import './button.dart';
import '../style/colors.dart';

class DialogMaker {
  static const double _buttonWidth = 80;
  static const double _dialogTextSize = 20;

  static void alertDialog(
          {required BuildContext context,
          required VoidCallback onPressed,
          required String text}) =>
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                backgroundColor: ColorTheme.darkGrey,
                content: TextMaker.defaultText(text, fontSize: 6),
                actions: <Widget>[
                  Center(
                    child: SizedBox(
                      width: _buttonWidth,
                      child: ButtonMaker.defaultButton(
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
                backgroundColor: ColorTheme.darkGrey,
                content: TextMaker.defaultText(text, fontSize: _dialogTextSize),
                actions: <Widget>[
                  SizedBox(
                    width: _buttonWidth,
                    child: ButtonMaker.defaultButton(
                      onPressed: () {
                        onOkPressed();
                        Navigator.of(ctx).pop();
                      },
                      text: 'ok',
                    ),
                  ),
                  SizedBox(
                    width: _buttonWidth,
                    child: ButtonMaker.defaultButton(
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
