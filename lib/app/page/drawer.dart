import 'package:flutter/material.dart';

import '../component/text.dart';
import '../component/dialog.dart';
import '../collection/audio_player.dart';
import '../style/decoration.dart';
import '../style/color.dart';

class PageDrawer extends StatelessWidget {
  const PageDrawer({Key? key, required this.audioPlayerKit}) : super(key: key);
  final AudioPlayerKit audioPlayerKit;

  @override
  Widget build(BuildContext context) => Drawer(
        backgroundColor: ColorMaker.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            ListTile(
              title: TextMaker.normal('PlayList', fontSize: 18),
              tileColor: ColorMaker.lightWine,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: ColorMaker.lightGrey, width: 1),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            ListTile(
              title: TextMaker.normal('Export', fontSize: 18),
              onTap: () {
                String listName = '';
                DialogMaker.alertDialog(
                  context: context,
                  onPressed: () {
                    audioPlayerKit.exportPlayList(listName);
                  },
                  content: TextField(
                    onChanged: (value) {
                      listName = value;
                    },
                    decoration: DecorationMaker.textField(),
                  ),
                );
              },
              hoverColor: ColorMaker.darkGrey,
            ),
            ListTile(
              title: TextMaker.normal('Import', fontSize: 18),
              onTap: () {
                String listName = '';
                DialogMaker.alertDialog(
                  context: context,
                  onPressed: () {
                    audioPlayerKit.importPlayList(listName);
                  },
                  content: TextField(
                    onChanged: (value) {
                      listName = value;
                    },
                    decoration: DecorationMaker.textField(),
                  ),
                );
              },
              hoverColor: ColorMaker.darkGrey,
            ),
            ListTile(
              title: TextMaker.normal('Update', fontSize: 18),
              onTap: () {
                String listName = '';
                DialogMaker.alertDialog(
                  context: context,
                  onPressed: () {
                    audioPlayerKit.updatePlayList(listName);
                  },
                  content: TextField(
                    onChanged: (value) {
                      listName = value;
                    },
                    decoration: DecorationMaker.textField(),
                  ),
                );
              },
              hoverColor: ColorMaker.darkGrey,
            ),
            ListTile(
              title: TextMaker.normal('Delete', fontSize: 18),
              onTap: () {
                String listName = '';
                DialogMaker.alertDialog(
                  context: context,
                  onPressed: () {
                    audioPlayerKit.deletePlayList(listName);
                  },
                  content: TextField(
                    onChanged: (value) {
                      listName = value;
                    },
                    decoration: DecorationMaker.textField(),
                  ),
                );
              },
              hoverColor: ColorMaker.darkGrey,
            ),
          ],
        ),
      );
}
