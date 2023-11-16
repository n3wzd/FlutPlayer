import 'package:flutter/material.dart';

import './button.dart';
import '../style/color.dart';

class DialogMaker {
  static const double _buttonWidth = 80.0;

  static void alertDialog(
          {required BuildContext context,
          required VoidCallback onPressed,
          required Widget content}) =>
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                backgroundColor: ColorMaker.darkGrey,
                content: content,
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
          required Widget content}) =>
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                backgroundColor: ColorMaker.darkGrey,
                content: content,
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
