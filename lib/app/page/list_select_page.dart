import 'package:flutter/material.dart';

import '../collection/audio_player.dart';
import '../component/listtile.dart';
import '../component/button.dart';
import '../style/color.dart';

class ListSelectPage extends StatefulWidget {
  const ListSelectPage({Key? key, required this.audioPlayerKit})
      : super(key: key);
  final AudioPlayerKit audioPlayerKit;

  @override
  State<ListSelectPage> createState() => _ListSelectPageState();
}

class _ListSelectPageState extends State<ListSelectPage> {
  List<Map> playList = [];
  List<bool> selectedList = [];

  @override
  void initState() {
    super.initState();
    setPlayList();
  }

  void setPlayList() async {
    playList = await widget.audioPlayerKit.selectAllPlayList() ?? [];
    selectedList = List<bool>.filled(playList.length, false, growable: false);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    int length = playList.length;
    return Scaffold(
      backgroundColor: ColorMaker.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: length,
                itemBuilder: (context, index) => ListTileMaker.multiItem(
                  index: index,
                  text: playList[index]['name'],
                  onTap: () async {
                    selectedList[index] = !selectedList[index];
                    setState(() {});
                  },
                  selected: selectedList[index],
                ),
              ),
            ),
            Container(
                alignment: Alignment.bottomCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ButtonMaker.text(
                        onPressed: () {
                          for (int index = 0; index < length; index++) {
                            if (selectedList[index]) {
                              widget.audioPlayerKit.importCustomPlayList(
                                  playList[index]['name']);
                            }
                          }
                          Navigator.pop(context);
                        },
                        text: 'ok',
                        fontSize: 24),
                    ButtonMaker.text(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        text: 'cancel',
                        fontSize: 24,
                        backgroundTransparent: true),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
