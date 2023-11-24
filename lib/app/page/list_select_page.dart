import 'package:flutter/material.dart';

import '../collection/audio_player.dart';
import '../component/listtile.dart';
import '../component/button.dart';
import '../style/color.dart';
import '../style/text.dart';

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
  int _selectedItemIndex = 0;
  bool _isSelectedItemFavorite = false;
  int _selectedPageIndex = 0;

  @override
  void initState() {
    super.initState();
    setPlayList();
  }

  void setPlayList() async {
    _playList = await widget.audioPlayerKit.selectAllPlayList(
            favoriteFilter: _selectedPageIndex == 1 ? false : true) ??
        [];
    _selectedList = List<bool>.filled(_playList.length, false, growable: false);
    setState(() {});
  }

  void deletePlayListItem(int index) {
    _playList.removeAt(index);
    _selectedList.removeAt(index);
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
                    widget.audioPlayerKit.toggleDBTableFavorite(
                        _playList[_selectedItemIndex]['name']);
                    _isSelectedItemFavorite = !_isSelectedItemFavorite;
                    if (_selectedPageIndex == 0 && !_isSelectedItemFavorite) {
                      deletePlayListItem(_selectedItemIndex);
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
                    widget.audioPlayerKit.updateCustomPlayList(
                        _playList[_selectedItemIndex]['name']);
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
                    widget.audioPlayerKit.deleteCustomPlayList(
                        _playList[_selectedItemIndex]['name']);
                    _selectedItemCount--;
                    deletePlayListItem(_selectedItemIndex);
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
                onDestinationSelected: (index) {
                  _selectedPageIndex = index;
                  _selectedItemCount = 0;
                  setPlayList();
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
                                  _playList[index]['name']) ??
                          false;
                      _selectedItemIndex = index;
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
