import 'package:flutter/material.dart';

import '../utils/audio_manager.dart';
import '../utils/database_manager.dart';
import '../widgets/listtile.dart';
import '../widgets/button.dart';
import '../widgets/text.dart';
import '../widgets/dialog.dart';
import '../models/color.dart';

class TagSelectPage extends StatefulWidget {
  const TagSelectPage({Key? key}) : super(key: key);

  @override
  State<TagSelectPage> createState() => _TagSelectPageState();
}

class _TagSelectPageState extends State<TagSelectPage> {
  List<Map> _tagList = [];
  List<bool> _selectedList = [];
  int _selectedItemCount = 0;
  bool _isSelectedItemFavorite = false;
  int _selectedPageIndex = 0;

  @override
  void initState() {
    super.initState();
    setPlayList();
  }

  Future<void> setPlayList() async {
    _tagList = await DatabaseManager.instance.selectAllDBTable(
        favoriteFilter: _selectedPageIndex == 1 ? false : true);
    _selectedList = List<bool>.filled(_tagList.length, false, growable: true);
    setState(() {});
  }

  void deletePlayListItem(int index) {
    _tagList.removeAt(index);
    _selectedList.removeAt(index);
    _selectedItemCount--;
  }

  int findUniqueItemIndex() {
    for (int i = 0; i < _selectedList.length; i++) {
      if (_selectedList[i]) {
        return i;
      }
    }
    return 0;
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
            icon: const Icon(Icons.star),
            iconColor: _isSelectedItemFavorite
                ? ColorPalette.lightWine
                : ColorPalette.lightGrey,
            onPressed: _selectedItemCount == 1
                ? () {
                    int selectedItemIndex = findUniqueItemIndex();
                    DatabaseManager.instance.toggleDBTableFavorite(
                        _tagList[selectedItemIndex]['name']);
                    _isSelectedItemFavorite = !_isSelectedItemFavorite;
                    if (_selectedPageIndex == 0 && !_isSelectedItemFavorite) {
                      deletePlayListItem(selectedItemIndex);
                    }
                    setState(() {});
                  }
                : null,
            outline: false,
          ),
          ButtonFactory.iconButton(
            icon: const Icon(Icons.change_circle),
            iconColor: ColorPalette.lightGrey,
            onPressed: _selectedItemCount == 1
                ? () {
                    int selectedItemIndex = findUniqueItemIndex();
                    String name = _tagList[selectedItemIndex]['name'];
                    DialogFactory.choiceDialog(
                      context: context,
                      onOkPressed: () {
                        DatabaseManager.instance.updateList(name);
                        setState(() {});
                      },
                      onCancelPressed: () {},
                      content: TextFactory.text('update $name?'),
                    );
                  }
                : null,
            outline: false,
          ),
          ButtonFactory.iconButton(
            icon: const Icon(Icons.delete),
            iconColor: ColorPalette.lightGrey,
            onPressed: _selectedItemCount == 1
                ? () {
                    int selectedItemIndex = findUniqueItemIndex();
                    String name = _tagList[selectedItemIndex]['name'];
                    DialogFactory.choiceDialog(
                      context: context,
                      onOkPressed: () {
                        DatabaseManager.instance
                            .deleteList(_tagList[selectedItemIndex]['name']);
                        deletePlayListItem(selectedItemIndex);
                        setState(() {});
                      },
                      onCancelPressed: () {},
                      content: TextFactory.text('delete $name?'),
                    );
                  }
                : null,
            outline: false,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            NavigationBarTheme(
              data: NavigationBarThemeData(
                labelTextStyle:
                    MaterialStateProperty.all(TextStyleFactory.style()),
                iconTheme: MaterialStateProperty.all(
                    const IconThemeData(color: ColorPalette.lightGrey)),
              ),
              child: NavigationBar(
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.star),
                    label: 'Favorite',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.present_to_all),
                    label: 'All',
                  ),
                ],
                backgroundColor: ColorPalette.transparent,
                selectedIndex: _selectedPageIndex,
                indicatorColor: ColorPalette.lightWine,
                onDestinationSelected: (index) async {
                  _selectedPageIndex = index;
                  _selectedItemCount = 0;
                  await setPlayList();
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: length,
                itemBuilder: (context, index) => ListTileFactory.multiItem(
                  index: index,
                  text: _tagList[index]['name'],
                  onTap: () async {
                    _selectedList[index] = !_selectedList[index];
                    _selectedList[index]
                        ? _selectedItemCount++
                        : _selectedItemCount--;
                    if (_selectedItemCount == 1) {
                      _isSelectedItemFavorite = await DatabaseManager.instance
                              .selectDBTableFavorite(
                                  _tagList[findUniqueItemIndex()]['name']) ??
                          false;
                    }
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
                          for (int index = 0; index < length; index++) {
                            if (_selectedList[index]) {
                              AudioManager.instance
                                  .importTagList(_tagList[index]['name']);
                            }
                          }
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
