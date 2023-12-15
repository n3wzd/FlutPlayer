import 'package:flutbeat/app/components/stream_builder.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../utils/audio_manager.dart';
import '../utils/preference.dart';
import '../utils/playlist.dart';
import '../widgets/listtile.dart';
import '../widgets/button.dart';
import '../widgets/text.dart';
import '../models/color.dart';
import '../models/play_list_order.dart';
import './item_add_actions.dart';

class ListSheet extends StatefulWidget {
  const ListSheet({Key? key}) : super(key: key);

  @override
  State<ListSheet> createState() => _ListSheetState();
}

class _ListSheetState extends State<ListSheet> {
  final _controller = DraggableScrollableController();
  final _expandController = StreamController<bool>.broadcast();
  double _minChildSize = 0;
  double _maxChildSize = 0;
  bool _isExpand = false;

  void _toggleSheetExpanding() async {
    if (_controller.size == _minChildSize) {
      _isExpand = true;
    } else if (_controller.size == _maxChildSize) {
      _isExpand = false;
    }
    await _animateExpand();
  }

  void _onEndScroll(ScrollMetrics metrics) async {
    _isExpand =
        _controller.size - _minChildSize < _maxChildSize - _controller.size
            ? false
            : true;

    await _animateExpand();
  }

  Future<void> _animateExpand() async {
    _expandController.add(_isExpand);
    await _controller.animateTo(!_isExpand ? _minChildSize : _maxChildSize,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutQuart);
  }

  @override
  Widget build(BuildContext context) {
    _minChildSize = 50.0 / MediaQuery.of(context).size.height;
    _maxChildSize = 0.9;

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollEndNotification) {
          _onEndScroll(scrollNotification.metrics);
        }
        return true;
      },
      child: DraggableScrollableSheet(
        initialChildSize: _minChildSize,
        minChildSize: _minChildSize,
        maxChildSize: _maxChildSize,
        controller: _controller,
        builder: (context, scrollController) => AudioStreamBuilder.playList(
          (context, value) => Scaffold(
            backgroundColor: ColorPalette.black,
            appBar: AppBar(
              leading: StreamBuilder(
                stream: _expandController.stream,
                builder: (context, value) => Visibility(
                  visible: _isExpand && Preference.showPlayListDeleteButton,
                  child: ButtonFactory.iconButton(
                    icon:
                        const Icon(Icons.delete, color: ColorPalette.lightGrey),
                    iconSize: 25,
                    onPressed: PlayList.instance.clear,
                    outline: false,
                  ),
                ),
              ),
              title: GestureDetector(
                onTap: _toggleSheetExpanding,
                child: StreamBuilder(
                  stream: _expandController.stream,
                  builder: (context, value) => Icon(
                    _isExpand ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                    size: 36,
                    color: ColorPalette.lightGrey,
                  ),
                ),
              ),
              centerTitle: true,
              backgroundColor: ColorPalette.darkWine,
              flexibleSpace: GestureDetector(
                onTap: _toggleSheetExpanding,
              ),
              automaticallyImplyLeading: false,
              actions: [
                StreamBuilder(
                  stream: _expandController.stream,
                  builder: (context, value) => Visibility(
                    visible: _isExpand && Preference.showPlayListOrderButton,
                    child: ButtonFactory.iconButton(
                      icon: Icon(
                        AudioManager.instance.playListOrderState ==
                                PlayListOrderState.ascending
                            ? Icons.vertical_align_top
                            : (AudioManager.instance.playListOrderState ==
                                    PlayListOrderState.descending
                                ? Icons.vertical_align_bottom
                                : Icons.sort),
                        size: 25,
                        color: ColorPalette.lightGrey,
                      ),
                      iconSize: 24,
                      onPressed: PlayList.instance.sort,
                    ),
                  ),
                ),
              ],
            ),
            body: AudioStreamBuilder.playListSheet(
              (context, value) => StatefulBuilder(
                builder: (context, setListState) => ReorderableListView.builder(
                  scrollController: scrollController,
                  onReorder: (oldIndex, newIndex) {
                    setListState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      PlayList.instance.shift(oldIndex, newIndex);
                    });
                  },
                  itemCount: AudioManager.instance.playListLength,
                  itemBuilder: (context, index) => Dismissible(
                    key: Key(AudioManager.instance.audioTitle(index)),
                    onDismissed: (DismissDirection direction) {
                      setListState(() {
                        AudioManager.instance.removePlayListItem(index);
                      });
                    },
                    child: ListTileFactory.multiItem(
                      key: Key(AudioManager.instance.audioTitle(index)),
                      index: index,
                      text: AudioManager.instance.audioTitle(index),
                      onTap: () async {
                        await AudioManager.instance.seekTrack(index);
                      },
                      selected:
                          AudioManager.instance.compareIndexWithCurrent(index),
                      trailing: PopupMenuButton(
                        color: ColorPalette.lightBlack,
                        icon: const Icon(Icons.add, color: ColorPalette.grey),
                        onSelected: (value) {
                          if (value == 0) {
                            Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (context) => TagSelector(
                                    trackTitle:
                                        AudioManager.instance.audioTitle(index),
                                  ),
                                ));
                          } else if (value == 1) {
                            Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (context) => ColorSelector(
                                    trackIndex: index,
                                  ),
                                ));
                          } else if (value == 2) {
                            backgroundSelector(
                              index,
                            );
                          }
                        },
                        itemBuilder: (context) => <PopupMenuEntry>[
                          PopupMenuItem(
                            value: 0,
                            child: TextFactory.text('tag'),
                          ),
                          PopupMenuItem(
                            value: 1,
                            child: TextFactory.text('color'),
                          ),
                          PopupMenuItem(
                            value: 2,
                            child: TextFactory.text('background'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
