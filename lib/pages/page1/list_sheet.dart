import 'package:flutter/material.dart';

import '../components/audio_player_kit.dart';
import '../components/text.dart';
import '../style/colors.dart';

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
    await _controller.animateTo(_isExpand ? _minChildSize : _maxChildSize,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutQuart);
    setState(() {
      _isExpand = !_isExpand;
    });
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
        return Scaffold(
          backgroundColor: ColorTheme.black,
          appBar: AppBar(
            title: GestureDetector(
              onTap: toggleSheetExpanding,
              child: Icon(
                _isExpand ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                size: 36,
                color: ColorTheme.lightGrey,
              ),
            ),
            centerTitle: true,
            backgroundColor: ColorTheme.darkWine,
            flexibleSpace: GestureDetector(
              onTap: toggleSheetExpanding,
            ),
          ),
          body: widget.audioPlayerKit.durationStreamBuilder(
            (context, duration) => ListView.builder(
              controller: scrollController,
              itemExtent: 60.0,
              itemCount: widget.audioPlayerKit.playListLength,
              itemBuilder: (context, index) => ListTile(
                title: Align(
                  alignment: Alignment.centerLeft,
                  child: TextMaker.defaultText(
                    '${widget.audioPlayerKit.playListAt(index).tag.title}',
                    color: ColorTheme.white,
                    fontSize: 18,
                  ),
                ),
                minVerticalPadding: 0,
                onTap: () async {
                  await widget.audioPlayerKit.seekTrack(index);
                },
                tileColor: widget.audioPlayerKit.currentIndex == index
                    ? ColorTheme.lightWine
                    : (index % 2 == 1 ? ColorTheme.darkGrey : ColorTheme.black),
                hoverColor: ColorTheme.lightWine,
              ),
            ),
          ),
        );
      },
    );
  }
}
