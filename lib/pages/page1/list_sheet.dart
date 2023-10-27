import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../style/colors.dart';
import '../style/text.dart';

class ListSheet extends StatefulWidget {
  const ListSheet({Key? key, required this.audioPlayer}) : super(key: key);
  final AudioPlayer audioPlayer;

  @override
  State<ListSheet> createState() => _ListSheetState();
}

class _ListSheetState extends State<ListSheet> {
  final minChildSize = 0.075;
  final maxChildSize = 0.9;
  final controller = DraggableScrollableController();
  bool _isExpand = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: minChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      controller: controller,
      builder: (context, scrollController) {
        return Material(
          color: ColorTheme.black,
          child: StreamBuilder<SequenceState?>(
            stream: widget.audioPlayer.sequenceStateStream,
            builder: (context, sequenceState) => ListView.builder(
              controller: scrollController,
              itemExtent: 60.0,
              itemCount: widget.audioPlayer.sequence!.length + 1,
              itemBuilder: (context, index) {
                return index == 0
                    ? ListTile(
                        title: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Icon(
                              _isExpand
                                  ? Icons.arrow_drop_down
                                  : Icons.arrow_drop_up,
                              size: 36,
                              color: ColorTheme.lightGrey,
                            ),
                          ),
                        ),
                        onTap: () async {
                          await controller.animateTo(
                              _isExpand ? minChildSize : maxChildSize,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOutQuart);
                          setState(() {
                            _isExpand = !_isExpand;
                          });
                        },
                        tileColor: ColorTheme.darkWine,
                      )
                    : ListTile(
                        title: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${widget.audioPlayer.sequence![index - 1].tag.title}',
                            style: TextStyleMaker.defaultTextStyle(
                              color: ColorTheme.white,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        onTap: () async {
                          await widget.audioPlayer
                              .seek(Duration.zero, index: index - 1);
                        },
                        tileColor: widget.audioPlayer.currentIndex! == index - 1
                            ? ColorTheme.lightWine
                            : (index % 2 == 0
                                ? ColorTheme.darkGrey
                                : ColorTheme.black),
                        hoverColor: ColorTheme.lightWine,
                      );
              },
            ),
          ),
        );
      },
    );
  }
}
