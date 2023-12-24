import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';

import '../components/tag_export_dialog.dart';
import '../utils/playlist.dart';
import '../utils/database_manager.dart';
import '../utils/stream_controller.dart';
import '../utils/permission_handler.dart';
import '../models/audio_track.dart';
import '../models/color.dart';
import '../widgets/listtile.dart';
import '../widgets/button.dart';
import '../widgets/text.dart';
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
  final List<Map<String, String>> _colorList = [];

  @override
  void initState() {
    super.initState();
    setPlayList();
  }

  void setPlayList() {
    defaultVisualizerColors.forEach((key, value) {
      Map<String, String> map = {'name': key, 'value': value};
      _colorList.add(map);
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
          child: Wrap(
            children: _colorList.map((data) {
              return GestureDetector(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Chip(
                      label: TextFactory.text(data['name']!, fontSize: 24),
                      backgroundColor: stringToColor(data['value']!),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  onTap: () {
                    AudioTrack? audio =
                        PlayList.instance.audioTrack(widget.trackIndex);
                    if (audio != null) {
                      DatabaseManager.instance
                          .updateDBTrackColor(audio, data["value"]!);
                      PlayList.instance
                          .setAudioColor(widget.trackIndex, data["value"]!);
                      AudioStreamController.visualizerColor.add(null);
                      Navigator.pop(context);
                    }
                  });
            }).toList(),
          ),
        ),
      ),
    );
  }
}

void backgroundSelector(int trackIndex) async {
  if (global.isAndroid) {
    if (!PermissionHandler.instance.isPermissionAccepted) {
      return;
    }
  }
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.custom,
    allowedExtensions: global.backgroundAllowedExtensions,
  );
  if (result != null) {
    String path = result.files[0].path ?? '';
    AudioTrack? audio = PlayList.instance.audioTrack(trackIndex);
    if (audio != null) {
      DatabaseManager.instance.updateDBTrackBackground(audio, path);
      PlayList.instance.setAudioBackground(trackIndex, path);
      AudioStreamController.backgroundFile.add(null);
    }
  }
}
