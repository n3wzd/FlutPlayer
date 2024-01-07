import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../utils/playlist.dart';
import '../utils/database_manager.dart';
import '../utils/stream_controller.dart';
import '../components/background.dart';
import '../models/color.dart';
import '../models/data.dart';
import '../widgets/button.dart';
import '../widgets/text.dart';
import '../widgets/switch.dart';
import '../global.dart' as global;

class BackgroundSelectPage extends StatefulWidget {
  const BackgroundSelectPage({Key? key, required this.trackIndex})
      : super(key: key);
  final int trackIndex;

  @override
  State<BackgroundSelectPage> createState() => _BackgroundSelectPageState();
}

class _BackgroundSelectPageState extends State<BackgroundSelectPage> {
  bool rotateSwitchValue = false;
  bool scaleSwitchValue = false;
  bool tintSwitchValue = false;
  String? backgroundPath;

  @override
  void initState() {
    super.initState();
    setBackground();
  }

  void setBackground() {
    BackgroundData? data = PlayList.instance.currentAudioBackground;
    if (data != null) {
      backgroundPath = data.path;
      rotateSwitchValue = data.rotate;
      scaleSwitchValue = data.scale;
      tintSwitchValue = data.color;
    }
  }

  Future<void> applyBackground() async {
    if (backgroundPath != null) {
      BackgroundData background = BackgroundData(
        path: backgroundPath ?? '',
        rotate: rotateSwitchValue,
        scale: scaleSwitchValue,
        color: tintSwitchValue,
      );
      await DatabaseManager.instance.updateDBTrackBackground(
          PlayList.instance.audioTitle(widget.trackIndex), background);
      PlayList.instance.setAudioBackground(widget.trackIndex, background);
      AudioStreamController.backgroundFile.add(null);
      AudioStreamController.imageBackgroundAnimation.add(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(
                    height: 200,
                    child: ClipRRect(
                      child: Background(),
                    ),
                  ),
                  ButtonFactory.textButton(
                      text: 'change',
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          allowMultiple: false,
                          type: FileType.custom,
                          allowedExtensions: global.backgroundAllowedExtensions,
                        );
                        if (result != null) {
                          backgroundPath = result.files[0].path;
                        }
                        await applyBackground();
                        setState(() {});
                      }),
                  ListTile(
                    title: TextFactory.text('Rotate'),
                    trailing: SwitchFactory.normal(
                      value: rotateSwitchValue,
                      onChanged: (newValue) async {
                        rotateSwitchValue = newValue;
                        await applyBackground();
                        setState(() {});
                      },
                    ),
                  ),
                  ListTile(
                    title: TextFactory.text('Scale'),
                    trailing: SwitchFactory.normal(
                      value: scaleSwitchValue,
                      onChanged: (newValue) async {
                        scaleSwitchValue = newValue;
                        await applyBackground();
                        setState(() {});
                      },
                    ),
                  ),
                  ListTile(
                    title: TextFactory.text('Tint'),
                    trailing: SwitchFactory.normal(
                      value: tintSwitchValue,
                      onChanged: (newValue) async {
                        tintSwitchValue = newValue;
                        await applyBackground();
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
            ButtonFactory.textButton(
                onPressed: () {
                  applyBackground();
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
