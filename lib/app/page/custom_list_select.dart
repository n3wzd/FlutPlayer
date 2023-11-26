import 'package:flutter/material.dart';

import '../collection/audio_player.dart';
import '../component/listtile.dart';
import '../component/button.dart';
import '../style/color.dart';
import '../style/text.dart';

import '../global.dart' as glo;

class ListSelectPage extends StatefulWidget {
  const ListSelectPage({Key? key, required this.audioPlayerKit})
      : super(key: key);
  final AudioPlayerKit audioPlayerKit;

  @override
  State<ListSelectPage> createState() => _ListSelectPageState();
}

class _ListSelectPageState extends State<ListSelectPage> {
  List<Map> _playList = [];
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
    _playList = await widget.audioPlayerKit.selectAllDBTable(
            favoriteFilter: _selectedPageIndex == 1 ? false : true) ??
        [];
    _selectedList = List<bool>.filled(_playList.length, false, growable: true);
    setState(() {});
  }

  void deletePlayListItem(int index) {
    _playList.removeAt(index);
    _selectedList.removeAt(index);
    _selectedItemCount--;

    glo.debugLog += _playList.toString();
    glo.debugLogStreamController.add(null);
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
    int length = _playList.length;
    return Scaffold(
      backgroundColor: ColorMaker.black,
      appBar: AppBar(
        backgroundColor: ColorMaker.darkWine,
        actions: [
          ButtonMaker.icon(
            icon: const Icon(Icons.star),
            color: _isSelectedItemFavorite
                ? ColorMaker.lightWine
                : ColorMaker.lightGrey,
            onPressed: _selectedItemCount == 1
                ? () {
                    int selectedItemIndex = findUniqueItemIndex();
                    widget.audioPlayerKit.toggleDBTableFavorite(
                        _playList[selectedItemIndex]['name']);
                    _isSelectedItemFavorite = !_isSelectedItemFavorite;
                    if (_selectedPageIndex == 0 && !_isSelectedItemFavorite) {
                      deletePlayListItem(selectedItemIndex);
                    }
                    setState(() {});
                  }
                : null,
            outline: false,
          ),
          ButtonMaker.icon(
            icon: const Icon(Icons.change_circle),
            color: ColorMaker.lightGrey,
            onPressed: _selectedItemCount == 1
                ? () {
                    int selectedItemIndex = findUniqueItemIndex();
                    widget.audioPlayerKit.updateCustomPlayList(
                        _playList[selectedItemIndex]['name']);
                    setState(() {});
                  }
                : null,
            outline: false,
          ),
          ButtonMaker.icon(
            icon: const Icon(Icons.delete),
            color: ColorMaker.lightGrey,
            onPressed: _selectedItemCount == 1
                ? () {
                    glo.debugLog = '';
                    try {
                      int selectedItemIndex = findUniqueItemIndex();
                      widget.audioPlayerKit.deleteCustomPlayList(
                          _playList[selectedItemIndex]['name']);
                      deletePlayListItem(selectedItemIndex);
                    } catch (e) {
                      glo.debugLog += e.toString();
                      glo.debugLogStreamController.add(null);
                    }

                    setState(() {});
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
                    MaterialStateProperty.all(TextStyleMaker.normal()),
                iconTheme: MaterialStateProperty.all(
                    const IconThemeData(color: ColorMaker.lightGrey)),
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
                backgroundColor: ColorMaker.transparent,
                selectedIndex: _selectedPageIndex,
                indicatorColor: ColorMaker.lightWine,
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
                itemBuilder: (context, index) => ListTileMaker.multiItem(
                  index: index,
                  text: _playList[index]['name'],
                  onTap: () async {
                    _selectedList[index] = !_selectedList[index];
                    _selectedList[index]
                        ? _selectedItemCount++
                        : _selectedItemCount--;
                    if (_selectedItemCount == 1) {
                      _isSelectedItemFavorite = await widget.audioPlayerKit
                              .selectDBTableFavorite(
                                  _playList[findUniqueItemIndex()]['name']) ??
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
                    ButtonMaker.text(
                        onPressed: () {
                          for (int index = 0; index < length; index++) {
                            if (_selectedList[index]) {
                              widget.audioPlayerKit.importCustomPlayList(
                                  _playList[index]['name']);
                            }
                          }
                          Navigator.pop(context);
                        },
                        text: 'ok',
                        fontSize: 24),
                    ButtonMaker.text(
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
