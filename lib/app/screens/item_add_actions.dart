import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';

import '../components/tag_export_dialog.dart';
import '../utils/playlist.dart';
import '../utils/background_manager.dart';
import '../utils/database_manager.dart';
import '../utils/stream_controller.dart';
import '../models/data.dart';
import '../models/color.dart';
import '../widgets/listtile.dart';
import '../widgets/button.dart';
import '../global.dart' as global;

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
                      DatabaseManager.instance.addTrackInDBTable(
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
  final List<String> _colorList = [];

  @override
  void initState() {
    super.initState();
    setPlayList();
  }

  void setPlayList() {
    defaultVisualizerColors.forEach((key, value) {
      _colorList.add(value);
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: ColorPalette.black,
        appBar: AppBar(
          backgroundColor: ColorPalette.darkWine,
          leading: ButtonFactory.iconButton(
            icon: const Icon(Icons.arrow_back),
            iconColor: ColorPalette.lightGrey,
            outline: false,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(
          child:
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: 15,
            itemBuilder: (itemContext, index) {
              return GestureDetector(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: stringToColor(_colorList[index]),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
                onTap: () {
                  AudioTrack? audio = PlayList.instance.audioTrack(widget.trackIndex);
                  if (audio != null) {
                    DatabaseManager.instance
                        .updateDBTrackColor(audio, _colorList[index]);
                    PlayList.instance
                        .setAudioColor(widget.trackIndex, _colorList[index]);
                    AudioStreamController.visualizerColor.add(null);
                    AudioStreamController.backgroundFile.add(null);
                    global.setVisualizerColor();
                    Navigator.pop(context);
                  }
                });
            },
          ),
        ),
      ),
    );
  }
}

void backgroundSelector(int trackIndex) async {
  String? path;
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.custom,
    allowedExtensions: backgroundAllowedExtensions,
  );
  if (result != null) {
    path = result.files[0].path;
    AudioTrack? audio = PlayList.instance.audioTrack(trackIndex);
    if (audio != null && path != null) {
      DatabaseManager.instance
          .updateDBTrackBackground(audio.title, BackgroundData(path: path));
      PlayList.instance
          .setAudioBackground(trackIndex, BackgroundData(path: path));
      AudioStreamController.backgroundFile.add(null);
    }
  }
}
