import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../utils/background_manager.dart';
import '../utils/playlist.dart';
import '../utils/database_manager.dart';
import '../utils/stream_controller.dart';
import '../models/data.dart';
import '../models/color.dart';
import '../widgets/button.dart';
import '../app_state.dart';

class ColorSelector extends StatefulWidget {
  const ColorSelector({super.key, required this.trackIndex});
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
          child: GridView.builder(
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
                      border: Border.all(color: Colors.white, width: 1.0),
                    ),
                  ),
                ),
                onTap: () {
                  AudioTrack? audio = PlayList.instance.audioTrack(
                    widget.trackIndex,
                  );
                  if (audio != null) {
                    DatabaseManager.instance.updateDBTrackColor(
                      audio,
                      _colorList[index],
                    );
                    PlayList.instance.setAudioColor(
                      widget.trackIndex,
                      _colorList[index],
                    );
                    AudioStreamController.emitVisualizerColorChanged();
                    AudioStreamController.emitBackgroundFileChanged();
                    AppState.instance.updateVisualizerColor();
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

void backgroundSelector(int trackIndex) async {
  String? path;
  FilePickerResult? result = await FilePicker.pickFiles(
    allowMultiple: false,
    type: FileType.custom,
    allowedExtensions: backgroundAllowedExtensions,
  );
  if (result != null) {
    path = result.files[0].path;
    AudioTrack? audio = PlayList.instance.audioTrack(trackIndex);
    if (audio != null && path != null) {
      DatabaseManager.instance.updateDBTrackBackground(
        audio.title,
        BackgroundData(path: path),
      );
      PlayList.instance.setAudioBackground(
        trackIndex,
        BackgroundData(path: path),
      );
      AudioStreamController.emitBackgroundFileChanged();
    }
  }
}
