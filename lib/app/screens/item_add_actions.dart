import 'package:flutter/material.dart';
import 'dart:async';

import '../components/tag_export_dialog.dart';
import '../utils/audio_player.dart';
import '../utils/playlist.dart';
import '../utils/database_manager.dart';
import '../utils/stream_controller.dart';
import '../models/audio_track.dart';
import '../models/visualizer_color.dart';
import '../widgets/listtile.dart';
import '../widgets/button.dart';
import '../widgets/text.dart';
import '../models/color.dart';

class TagSelector extends StatefulWidget {
  const TagSelector({Key? key, required this.trackTitle}) : super(key: key);
  final String trackTitle;

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  List<Map> _tagList = [];
  List<bool> _selectedList = [];

  @override
  void initState() {
    super.initState();
    setPlayList();
  }

  Future<void> setPlayList() async {
    _tagList = await DatabaseManager.instance.selectAllDBTable();
    _selectedList = List<bool>.filled(_tagList.length, false, growable: true);
    setState(() {});
  }

  Future<void> addItem(String item) async {
    _tagList.add({"name": item});
    _selectedList.add(false);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    int length = _tagList.length;
    return Scaffold(
      backgroundColor: ColorPalette.black,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: ColorPalette.darkWine,
        actions: [
          ButtonFactory.iconButton(
            icon: const Icon(Icons.add),
            iconColor: ColorPalette.lightWine,
            onPressed: () {
              tagExportDialog(context, autoAddPlaylist: false,
                  onCompleted: (listName) {
                addItem(listName);
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: length,
                itemBuilder: (context, index) => ListTileFactory.multiItem(
                  index: index,
                  text: _tagList[index]['name'],
                  onTap: () {
                    _selectedList[index] = !_selectedList[index];
                    setState(() {});
                  },
                  selected: _selectedList[index],
                ),
              ),
            ),
            ButtonFactory.textButton(
                onPressed: () {
                  for (int index = 0; index < length; index++) {
                    if (_selectedList[index]) {
                      DatabaseManager.instance.addItemInDBTable(
                          tableName: _tagList[index]['name'],
                          trackTitle: widget.trackTitle);
                    }
                  }
                  Navigator.pop(context);
                },
                text: 'ok',
                fontSize: 24),
          ],
        ),
      ),
    );
  }
}

class ColorSelector extends StatefulWidget {
  const ColorSelector({Key? key, required this.trackIndex}) : super(key: key);
  final int trackIndex;

  @override
  State<ColorSelector> createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  List<Map> _colorList = [];

  @override
  void initState() {
    super.initState();
    setPlayList();
  }

  Future<void> setPlayList() async {
    _colorList = await DatabaseManager.instance.selectAllDBColor();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: ColorPalette.black,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          backgroundColor: ColorPalette.darkWine,
          actions: const [],
        ),
        body: Wrap(
          children: _colorList.map((data) {
            return GestureDetector(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Chip(
                    label: TextFactory.outlineText(data["name"], fontSize: 24),
                    backgroundColor: Color(data["value"]),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                onTap: () {
                  AudioTrack? audio =
                      AudioPlayerKit.instance.audioTrack(widget.trackIndex);
                  if (audio != null) {
                    DatabaseManager.instance.updateDBTrackColor(
                        audio,
                        VisualizerColor(
                            name: data["name"], value: data["value"]));
                    PlayList.instance.setCurrentAudioColor(data["value"]);
                    AudioStreamController.visualizerColor.add(null);
                    Navigator.pop(context);
                  }
                });
          }).toList(),
        ),
      ),
    );
  }
}
