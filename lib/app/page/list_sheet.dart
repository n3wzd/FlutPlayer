import 'package:flutter/material.dart';

import '../collection/audio_player.dart';
import '../component/text.dart';
import '../style/color.dart';

class ListSheet extends StatefulWidget {
  const ListSheet({Key? key, required this.audioPlayerKit}) : super(key: key);
  final AudioPlayerKit audioPlayerKit;

  @override
  State<ListSheet> createState() => _ListSheetState();
}

class _ListSheetState extends State<ListSheet> {
  final _controller = DraggableScrollableController();
  double _minChildSize = 0;
  double _maxChildSize = 0;
  bool _isExpand = false;

  void toggleSheetExpanding() async {
    setState(() {
      _isExpand = !_isExpand;
    });
    await _controller.animateTo(!_isExpand ? _minChildSize : _maxChildSize,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutQuart);
  }

  @override
  Widget build(BuildContext context) {
    _minChildSize = 50.0 / MediaQuery.of(context).size.height;
    _maxChildSize = 0.9;

    return DraggableScrollableSheet(
      initialChildSize: _minChildSize,
      minChildSize: _minChildSize,
      maxChildSize: _maxChildSize,
      controller: _controller,
      builder: (context, scrollController) {
        return widget.audioPlayerKit.playListStreamBuilder(
          (context, playListIndex) => Scaffold(
            backgroundColor: ColorMaker.black,
            appBar: AppBar(
              title: GestureDetector(
                onTap: toggleSheetExpanding,
                child: Icon(
                  _isExpand ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                  size: 36,
                  color: ColorMaker.lightGrey,
                ),
              ),
              centerTitle: true,
              backgroundColor: ColorMaker.darkWine,
              flexibleSpace: GestureDetector(
                onTap: toggleSheetExpanding,
              ),
            ),
            body: widget.audioPlayerKit.trackStreamBuilder(
              (context, duration) => StatefulBuilder(
                builder: (context, setListState) => ReorderableListView.builder(
                  scrollController: scrollController,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    widget.audioPlayerKit.shiftPlayListItem(oldIndex, newIndex);
                  },
                  itemCount: widget.audioPlayerKit.playListLength,
                  itemBuilder: (context, index) => Dismissible(
                    key: Key(widget.audioPlayerKit.audioTitle(index)),
                    onDismissed: (DismissDirection direction) {
                      setListState(() {
                        widget.audioPlayerKit.removePlayListItem(index);
                      });
                    },
                    child: ListTile(
                      key: Key(widget.audioPlayerKit.audioTitle(index)),
                      title: SizedBox(
                        height: 60,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextMaker.normal(
                            widget.audioPlayerKit.audioTitle(index),
                            fontSize: 18,
                          ),
                        ),
                      ),
                      minVerticalPadding: 0,
                      onTap: () async {
                        await widget.audioPlayerKit.seekTrack(index);
                      },
                      tileColor:
                          widget.audioPlayerKit.compareIndexWithCurrent(index)
                              ? ColorMaker.lightWine
                              : (index % 2 == 1
                                  ? ColorMaker.darkGrey
                                  : ColorMaker.black),
                      hoverColor: ColorMaker.lightWine,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
