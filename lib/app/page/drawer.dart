import 'package:flutter/material.dart';

import '../page/list_select_page.dart';
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
        child: ListView.separated(
          itemCount: 10,
          separatorBuilder: (BuildContext context, int index) => const Divider(
              color: ColorMaker.lightGreySeparator, height: 1, thickness: 1),
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return ListTile(
                title: TextMaker.normal('PlayList',
                    fontSize: 22, fontWeight: FontWeight.bold),
                tileColor: ColorMaker.darkWine,
              );
            } else if (index == 1) {
              return ListTile(
                  title: TextMaker.normal('Export', fontSize: 18),
                  subtitle: TextMaker.normal(
                      'create new playlist from the current.',
                      fontSize: 14,
                      color: ColorMaker.grey,
                      allowLineBreak: true),
                  onTap: () {
                    String listName = '';
                    DialogMaker.alertDialog(
                      context: context,
                      onPressed: () {
                        audioPlayerKit.exportCustomPlayList(listName);
                      },
                      content: TextField(
                        onChanged: (value) {
                          listName = value;
                        },
                        decoration: DecorationMaker.textField(),
                      ),
                    );
                  });
            } else if (index == 2) {
              return ListTile(
                  title: TextMaker.normal('Import', fontSize: 18),
                  subtitle: TextMaker.normal(
                      'load playlist and place on the current.',
                      fontSize: 14,
                      color: ColorMaker.grey,
                      allowLineBreak: true),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return ListSelectPage(
                          audioPlayerKit: audioPlayerKit,
                        );
                      },
                    ));
                  });
            } else if (index == 3) {
              return ListTile(
                  title: TextMaker.normal('Update', fontSize: 18),
                  subtitle: TextMaker.normal('change playlist to the current.',
                      fontSize: 14,
                      color: ColorMaker.grey,
                      allowLineBreak: true),
                  onTap: () {
                    String listName = '';
                    DialogMaker.alertDialog(
                      context: context,
                      onPressed: () {
                        audioPlayerKit.updateCustomPlayList(listName);
                      },
                      content: TextField(
                        onChanged: (value) {
                          listName = value;
                        },
                        decoration: DecorationMaker.textField(),
                      ),
                    );
                  });
            } else if (index == 4) {
              return ListTile(
                  title: TextMaker.normal('Delete', fontSize: 18),
                  subtitle: TextMaker.normal('delete playlist.',
                      fontSize: 14,
                      color: ColorMaker.grey,
                      allowLineBreak: true),
                  onTap: () {
                    String listName = '';
                    DialogMaker.alertDialog(
                      context: context,
                      onPressed: () {
                        audioPlayerKit.deleteCustomPlayList(listName);
                      },
                      content: TextField(
                        onChanged: (value) {
                          listName = value;
                        },
                        decoration: DecorationMaker.textField(),
                      ),
                    );
                  });
            } else if (index == 5) {
              return ListTile(
                title: TextMaker.normal('Sort',
                    fontSize: 22, fontWeight: FontWeight.bold),
                tileColor: ColorMaker.darkWine,
              );
            } else if (index == 6) {
              return ListTile(
                  title: TextMaker.normal('Title', fontSize: 18),
                  subtitle: TextMaker.normal('by ascending.',
                      fontSize: 14,
                      color: ColorMaker.grey,
                      allowLineBreak: true),
                  onTap: () {
                    audioPlayerKit.sortPlayList(0);
                  });
            } else if (index == 7) {
              return ListTile(
                  title: TextMaker.normal('Title', fontSize: 18),
                  subtitle: TextMaker.normal('by descending.',
                      fontSize: 14,
                      color: ColorMaker.grey,
                      allowLineBreak: true),
                  onTap: () {
                    audioPlayerKit.sortPlayList(1);
                  });
            } else if (index == 8) {
              return ListTile(
                  title: TextMaker.normal('Changed DateTime', fontSize: 18),
                  subtitle: TextMaker.normal('by ascending.',
                      fontSize: 14,
                      color: ColorMaker.grey,
                      allowLineBreak: true),
                  onTap: () {
                    audioPlayerKit.sortPlayList(2);
                  });
            } else {
              return ListTile(
                  title: TextMaker.normal('Changed DateTime', fontSize: 18),
                  subtitle: TextMaker.normal('by descending.',
                      fontSize: 14,
                      color: ColorMaker.grey,
                      allowLineBreak: true),
                  onTap: () {
                    audioPlayerKit.sortPlayList(3);
                  });
            }
          },
        ),
      );
}
