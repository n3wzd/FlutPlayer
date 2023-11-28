import 'package:flutter/material.dart';

import 'dart:async';
import '../component/dialog.dart';
import '../component/text.dart';
import '../component/text_field.dart';
import '../collection/audio_player.dart';

Future<void> tagExportDialog(
    BuildContext context, AudioPlayerKit audioPlayerKit,
    {bool autoAddPlaylist = true}) async {
  String listName = '';
  String toolTipText = '';
  final textFieldStreamController = StreamController<void>.broadcast();
  await DialogMaker.alertDialog(
    context: context,
    onPressed: () async {
      listName = listName.trim();
      bool? checkDBTableExist =
          await audioPlayerKit.checkDBTableExist(listName);
      if (checkDBTableExist != null) {
        if (!checkDBTableExist) {
          if (listName != '') {
            if (autoAddPlaylist) {
              audioPlayerKit.exportCustomPlayList(listName);
            }
            return true;
          } else {
            toolTipText = 'the name is empty.';
          }
        } else {
          toolTipText = 'This tag already exists.';
        }
      } else {
        toolTipText = 'DB Error.';
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
            child: TextFieldMaker.normal(
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
                child: TextMaker.normal(toolTipText, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
