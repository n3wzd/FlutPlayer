import 'package:flutter/material.dart';

import '../utils/audio_manager.dart';
import '../utils/database_manager.dart';
import '../widgets/listtile.dart';
import '../widgets/button.dart';
import '../models/color.dart';

class TagSelectPage extends StatefulWidget {
  const TagSelectPage({super.key});

  @override
  State<TagSelectPage> createState() => _TagSelectPageState();
}

class _TagSelectPageState extends State<TagSelectPage> {
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

  @override
  Widget build(BuildContext context) {
    int length = _tagList.length;
    return Scaffold(
      backgroundColor: ColorPalette.black,
      appBar: AppBar(
        backgroundColor: ColorPalette.darkWine,
        actions: [
          ButtonFactory.iconButton(
            icon: const Icon(Icons.refresh),
            iconColor: ColorPalette.lightGrey,
            onPressed: () async {
              await setPlayList();
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
                  text: _tagList[index]['name'],
                  onTap: () async {
                    _selectedList[index] = !_selectedList[index];
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
                    onPressed: () async {
                      for (int index = 0; index < length; index++) {
                        if (_selectedList[index]) {
                          await AudioManager.instance.importTagList(
                            _tagList[index]['name'],
                          );
                        }
                      }
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.pop(context);
                    },
                    text: 'ok',
                    fontSize: 24,
                  ),
                  ButtonFactory.textButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    text: 'cancel',
                    fontSize: 24,
                    backgroundTransparent: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
