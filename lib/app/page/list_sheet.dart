import 'package:flutter/material.dart';
import 'dart:async';

import '../collection/audio_player.dart';
import '../collection/audio_playlist.dart';
import '../collection/preference.dart';
import '../component/listtile.dart';
import '../component/button.dart';
import '../style/color.dart';

class ListSheet extends StatefulWidget {
  const ListSheet({Key? key, required this.audioPlayerKit}) : super(key: key);
  final AudioPlayerKit audioPlayerKit;

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
        builder: (context, scrollController) =>
            widget.audioPlayerKit.playListStreamBuilder(
          (context, value) => Scaffold(
            backgroundColor: ColorMaker.black,
            appBar: AppBar(
              leading: StreamBuilder(
                stream: _expandController.stream,
                builder: (context, value) => Visibility(
                  visible: _isExpand && Preference.showPlayListDeleteButton,
                  child: ButtonMaker.icon(
                    icon: const Icon(Icons.delete, color: ColorMaker.lightGrey),
                    iconSize: 25,
                    onPressed: widget.audioPlayerKit.clearPlayList,
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
                    color: ColorMaker.lightGrey,
                  ),
                ),
              ),
              centerTitle: true,
              backgroundColor: ColorMaker.darkWine,
              flexibleSpace: GestureDetector(
                onTap: _toggleSheetExpanding,
              ),
              automaticallyImplyLeading: false,
              actions: [
                StreamBuilder(
                  stream: _expandController.stream,
                  builder: (context, value) => Visibility(
                    visible: _isExpand && Preference.showPlayListOrderButton,
                    child: ButtonMaker.icon(
                      icon: Icon(
                        widget.audioPlayerKit.playListOrderState ==
                                PlayListOrderState.ascending
                            ? Icons.vertical_align_top
                            : (widget.audioPlayerKit.playListOrderState ==
                                    PlayListOrderState.descending
                                ? Icons.vertical_align_bottom
                                : Icons.sort),
                        size: 25,
                        color: ColorMaker.lightGrey,
                      ),
                      iconSize: 24,
                      onPressed: widget.audioPlayerKit.sortPlayList,
                    ),
                  ),
                ),
              ],
            ),
            body: widget.audioPlayerKit.playListSheetStreamBuilder(
              (context, value) => StatefulBuilder(
                builder: (context, setListState) => ReorderableListView.builder(
                  scrollController: scrollController,
                  onReorder: (oldIndex, newIndex) {
                    setListState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      widget.audioPlayerKit
                          .shiftPlayListItem(oldIndex, newIndex);
                    });
                  },
                  itemCount: widget.audioPlayerKit.playListLength,
                  itemBuilder: (context, index) => Dismissible(
                    key: Key(widget.audioPlayerKit.audioTitle(index)),
                    onDismissed: (DismissDirection direction) {
                      setListState(() {
                        widget.audioPlayerKit.removePlayListItem(index);
                      });
                    },
                    child: ListTileMaker.multiItem(
                      key: Key(widget.audioPlayerKit.audioTitle(index)),
                      index: index,
                      text: widget.audioPlayerKit.audioTitle(index),
                      onTap: () async {
                        await widget.audioPlayerKit.seekTrack(index);
                      },
                      selected:
                          widget.audioPlayerKit.compareIndexWithCurrent(index),
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
