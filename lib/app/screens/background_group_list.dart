import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/background_manager.dart';
import '../utils/database_manager.dart';
import '../utils/stream_controller.dart';
import '../widgets/listtile.dart';
import '../widgets/button.dart';
import '../widgets/switch.dart';
import '../widgets/slider.dart';
import '../widgets/text.dart';
import '../widgets/dialog.dart';
import '../models/color.dart';
import '../models/data.dart';

class BackgroundGroupPage extends StatefulWidget {
  const BackgroundGroupPage({Key? key}) : super(key: key);

  @override
  State<BackgroundGroupPage> createState() => _BackgroundGroupPageState();
}

class _BackgroundGroupPageState extends State<BackgroundGroupPage> {
  List<Map> _groupList = [];
  List<bool> _selectedList = [];
  int _selectedItemCount = 0;

  @override
  void initState() {
    super.initState();
    setList();
  }

  Future<void> setList() async {
    _groupList = await DatabaseManager.instance.selectAllBackgroundGroup();
    _selectedList = List<bool>.filled(_groupList.length, false, growable: true);
    setState(() {});
  }

  void addListItem(String path) {
    _groupList.add(<String, String> {
      'path': path,
    });
    _selectedList.add(false);
  }

  void deleteListItem(int index) {
    _groupList.removeAt(index);
    _selectedList.removeAt(index);
    _selectedItemCount--;
  }

  int getUniqueItemIndex() {
    for (int i = 0; i < _selectedList.length; i++) {
      if (_selectedList[i]) {
        return i;
      }
    }
    return 0;
  }

  List<int> getSelectedItemIndex() {
    List<int> selected = [];
    for (int i = 0; i < _selectedList.length; i++) {
      if (_selectedList[i]) {
        selected.add(i);
      }
    }
    return selected;
  }

  @override
  Widget build(BuildContext context) {
    int length = _groupList.length;
    return Scaffold(
      backgroundColor: ColorPalette.black,
      appBar: AppBar(
        backgroundColor: ColorPalette.darkWine,
        actions: [
          ButtonFactory.iconButton(
            icon: const Icon(Icons.add_circle),
            iconColor: ColorPalette.lightGrey,
            onPressed: () async {
              String? path =
                  await FilePicker.platform.getDirectoryPath();
              if (path != null) {
                await DatabaseManager.instance.insertBackgroundGroup(BackgroundData(path: path));
                addListItem(path);
                setState(() {});
              }
            },
            outline: false,
          ),
          ButtonFactory.iconButton(
            icon: const Icon(Icons.change_circle),
            iconColor: ColorPalette.lightGrey,
            onPressed: _selectedItemCount == 1 ? () async {
              String path = _groupList[getUniqueItemIndex()]['path'];
              Navigator.push(context, MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return BackgroundGroupSelectPage(path: path);
                  })
              );
            } : null,
            outline: false,
          ),
          ButtonFactory.iconButton(
            icon: const Icon(Icons.delete),
            iconColor: ColorPalette.lightGrey,
            onPressed: () {
              DialogFactory.choiceDialog(
                context: context,
                onOkPressed: () {
                  List<int> selected = getSelectedItemIndex();
                  for(int i = selected.length -
                      1; i >= 0; i--) {
                    int selectedItemIndex = selected[i];
                    DatabaseManager.instance
                        .deleteBackgroundGroup(_groupList[selectedItemIndex]['path']);
                    deleteListItem(selectedItemIndex);
                  }
                  setState(() {});
                },
                onCancelPressed: () {},
                content: TextFactory.text('delete?'),
              );
            },
            outline: false,
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
                  text: _groupList[index]['path'],
                  onTap: () async {
                    _selectedList[index] = !_selectedList[index];
                    _selectedList[index]
                        ? _selectedItemCount++
                        : _selectedItemCount--;
                    setState(() {});
                  },
                  selected: _selectedList[index],
                ),
              ),
            ),
            Container(
                alignment: Alignment.bottomCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ButtonFactory.textButton(
                        onPressed: () {
                          BackgroundManager.instance.updateBackgroundList();
                          AudioStreamController.backgroundFile.add(null);
                          Navigator.pop(context);
                        },
                        text: 'close',
                        fontSize: 24),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}

class BackgroundGroupSelectPage extends StatefulWidget {
  const BackgroundGroupSelectPage({Key? key, required this.path})
      : super(key: key);
  final String path;

  @override
  State<BackgroundGroupSelectPage> createState() => _BackgroundGroupSelectPageState();
}

class _BackgroundGroupSelectPageState extends State<BackgroundGroupSelectPage> {
  final double valueSliderMax = 100;
  final double valueSliderMin = 0;
  bool rotateSwitchValue = false;
  bool scaleSwitchValue = false;
  bool tintSwitchValue = false;
  double valueSliderValue = 75;

  @override
  void initState() {
    super.initState();
    loadSetting();
  }

  void loadSetting() async {
    BackgroundData data = await DatabaseManager.instance.selectBackgroundGroup(widget.path);
    rotateSwitchValue = data.rotate;
    scaleSwitchValue = data.scale;
    tintSwitchValue = data.color;
    valueSliderValue = data.value.toDouble();
    setState(() {});
  }

  void applySetting () async {
    BackgroundData background = BackgroundData(
      path: widget.path,
      rotate: rotateSwitchValue,
      scale: scaleSwitchValue,
      color: tintSwitchValue,
      value: valueSliderValue.toInt(),
    );
    await DatabaseManager.instance.updateBackgroundGroup(
        widget.path, background);
    BackgroundManager.instance.updateBackgroundList();
    AudioStreamController.backgroundFile.add(null);
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
                              setState(() {});
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
                              setState(() {});
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
                              setState(() {});
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
                            );
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
                      applySetting();
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

