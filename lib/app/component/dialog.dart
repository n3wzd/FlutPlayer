import 'package:flutter/material.dart';

import './button.dart';
import '../style/color.dart';

class DialogMaker {
  static const double _buttonWidth = 80.0;

  static alertDialog(
          {required BuildContext context,
          required Future<bool> Function() onPressed,
          required Widget content}) =>
      showDialog(
          context: context,
          builder: (context) => Dialog(
                backgroundColor: ColorMaker.darkGrey,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      content,
                      SizedBox(
                        width: 80,
                        child: ButtonMaker.text(
                          onPressed: () async {
                            bool isPop = await onPressed();
                            if (isPop && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          text: 'ok',
                        ),
                      )
                    ],
                  ),
                ),
              ));

  static choiceDialog(
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
