import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/audio_manager.dart';
import '../utils/database_manager.dart';
import '../widgets/listtile.dart';
import '../widgets/button.dart';
import '../widgets/text.dart';
import '../widgets/dialog.dart';
import '../models/color.dart';

class MixSelectPage extends StatefulWidget {
  const MixSelectPage({Key? key}) : super(key: key);

  @override
  State<MixSelectPage> createState() => _MixSelectState();
}

class _MixSelectState extends State<MixSelectPage> {
  List<Map> _groupList = [];
  List<bool> _selectedList = [];
  int _selectedItemCount = 0;

  @override
  void initState() {
    super.initState();
    setList();
  }

  Future<void> setList() async {
    _groupList = await DatabaseManager.instance.selectAllMix();
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
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                allowMultiple: true,
                type: FileType.custom,
                allowedExtensions: ['json'],
              );
              if (result != null) {
                String? path = result.files[0].path;
                if(path != null) {
                  await DatabaseManager.instance.insertMix(path);
                  addListItem(path);
                  setState(() {});
                }
              }
            },
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
                    String path = _groupList[selectedItemIndex]['path'];
                    DatabaseManager.instance.deleteMix(path);
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
                          List<String> paths = [
                            for (int index = 0; index < length; index++) 
                              if (_selectedList[index])
                                _groupList[index]['path']
                          ];
                          AudioManager.instance.importCustomMixs(paths);
                          Navigator.pop(context);
                        },
                        text: 'ok',
                        fontSize: 24),
                    ButtonFactory.textButton(
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
