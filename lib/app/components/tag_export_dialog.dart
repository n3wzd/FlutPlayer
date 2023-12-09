import 'package:flutter/material.dart';

import 'dart:async';
import '../widgets/dialog.dart';
import '../widgets/text.dart';
import '../widgets/text_field.dart';
import '../utils/database_manager.dart';

Future<void> tagExportDialog(BuildContext context,
    {bool autoAddPlaylist = true, void Function(String)? onCompleted}) async {
  String listName = '';
  String toolTipText = '';
  final textFieldStreamController = StreamController<void>.broadcast();
  await DialogFactory.alertDialog(
    context: context,
    onPressed: () async {
      listName = listName.trim();
      bool? checkDBTableExist =
          await DatabaseManager.instance.checkDBTableExist(listName);
      if (!checkDBTableExist) {
        if (listName != '') {
          DatabaseManager.instance.exportList(listName, autoAddPlaylist);
          if (onCompleted != null) {
            onCompleted(listName);
          }
          return true;
        } else {
          toolTipText = 'the name is empty.';
        }
      } else {
        toolTipText = 'This tag already exists.';
      }
      textFieldStreamController.add(null);
      return false;
    },
    content: SizedBox(
      height: 64,
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: TextFieldFactory.textField(
              onChanged: (value) {
                listName = value;
                toolTipText = '';
                textFieldStreamController.add(null);
              },
            ),
          ),
          StreamBuilder(
            stream: textFieldStreamController.stream,
            builder: (context, data) => SizedBox(
              height: 24,
              child: Center(
                child: TextFactory.text(toolTipText, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
