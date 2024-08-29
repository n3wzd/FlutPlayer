import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../utils/playlist.dart';
import '../utils/database_manager.dart';
import '../utils/stream_controller.dart';
import '../components/background.dart';
import '../models/color.dart';
import '../models/data.dart';
import '../widgets/button.dart';
import '../widgets/text.dart';
import '../widgets/switch.dart';
import '../widgets/text_field.dart';
import '../widgets/slider.dart';
import '../global.dart' as global;

class BackgroundSelectPage extends StatefulWidget {
  const BackgroundSelectPage({Key? key, required this.trackIndex})
      : super(key: key);
  final int trackIndex;

  @override
  State<BackgroundSelectPage> createState() => _BackgroundSelectPageState();
}

class _BackgroundSelectPageState extends State<BackgroundSelectPage> {
  final TextEditingController _textEditingController = TextEditingController();
  final double valueSliderMax = 100;
  final double valueSliderMin = 0;
  bool rotateSwitchValue = false;
  bool scaleSwitchValue = false;
  bool tintSwitchValue = false;
  double valueSliderValue = 75;
  String? backgroundPath;
  String currentText = '';

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
      valueSliderValue = data.value.toDouble();
      if (valueSliderValue > valueSliderMax) {
        valueSliderValue = valueSliderMax;
      }
      if (valueSliderValue < valueSliderMin) {
        valueSliderValue = valueSliderMin;
      }
      updateText(backgroundPath);
    }
  }

  Future<void> applyBackground() async {
    if (backgroundPath != null) {
      BackgroundData background = BackgroundData(
        path: backgroundPath ?? '',
        rotate: rotateSwitchValue,
        scale: scaleSwitchValue,
        color: tintSwitchValue,
        value: valueSliderValue.toInt(),
      );
      await DatabaseManager.instance.updateDBTrackBackground(
          PlayList.instance.audioTitle(widget.trackIndex), background);
      PlayList.instance.setAudioBackground(widget.trackIndex, background);
      AudioStreamController.backgroundFile.add(null);
      AudioStreamController.imageBackgroundAnimation.add(null);
      setState(() {});
    }
  }

  void updateText(String? text) {
    if (text != null) {
      setState(() {
        _textEditingController.text = text;
        currentText = text;
      });
    }
  }

  bool isVailedBackgroundFile(String path) {
    File file = File(path);
    String extension = path.split('.').last;
    return file.existsSync() &&
        global.backgroundAllowedExtensions.contains(extension);
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
            const SizedBox(
              height: 200,
              child: ClipRRect(
                child: Background(),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  TextFactory.text('url: '),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFieldFactory.textField(
                      controller: _textEditingController,
                      onChanged: (text) {
                        currentText = text;
                        if (isVailedBackgroundFile(text)) {
                          backgroundPath = text;
                          applyBackground();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ButtonFactory.textButton(
                    text: 'add',
                    onPressed: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles(
                        allowMultiple: false,
                        type: FileType.custom,
                        allowedExtensions: global.backgroundAllowedExtensions,
                      );
                      if (result != null) {
                        backgroundPath = result.files[0].path;
                        updateText(backgroundPath);
                        applyBackground();
                      }
                    }),
                const SizedBox(width: 20),
                ButtonFactory.textButton(
                    text: 'remove',
                    onPressed: () {
                      backgroundPath = '';
                      updateText(backgroundPath);
                      applyBackground();
                    }),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                        children: <Widget>[
                          SizedBox(
                            width: 64,
                            child: TextFactory.text('Rotate'),
                          ),
                          SwitchFactory.normal(
                            value: rotateSwitchValue,
                            onChanged: (newValue) {
                              rotateSwitchValue = newValue;
                              applyBackground();
                            },
                          ),
                        ]
                    ),
                    Row(
                        children: <Widget>[
                          SizedBox(
                            width: 64,
                            child: TextFactory.text('Scale'),
                          ),
                          SwitchFactory.normal(
                            value: scaleSwitchValue,
                            onChanged: (newValue) {
                              scaleSwitchValue = newValue;
                              applyBackground();
                            },
                          ),
                        ]
                    ),
                    Row(
                        children: <Widget>[
                          SizedBox(
                            width: 64,
                            child: TextFactory.text('Tint'),
                          ),
                          SwitchFactory.normal(
                            value: tintSwitchValue,
                            onChanged: (newValue) {
                              tintSwitchValue = newValue;
                              applyBackground();
                            },
                          ),
                        ]
                    ),
                    Row(
                        children: <Widget>[
                          SizedBox(
                            width: 64,
                            child: TextFactory.text('Value'),
                          ),
                          StatefulBuilder(builder: (context, setSliderState) {
                            return SliderFactory.slider(
                                value: valueSliderValue,
                                max: valueSliderMax,
                                onChanged: (value) {
                                  valueSliderValue = value;
                                  setSliderState(() {});
                                },
                                onChangeEnd: (value) {
                                  valueSliderValue = value;
                                  applyBackground();
                                });
                          }),
                        ]
                    ),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ButtonFactory.textButton(
                    onPressed: () {
                      applyBackground();
                      Navigator.pop(context);
                    },
                    text: 'ok',
                    fontSize: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
