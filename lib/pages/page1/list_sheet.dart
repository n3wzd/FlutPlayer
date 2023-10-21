import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

import '../style/colors.dart';
import '../style/text.dart';

class ListSheet extends StatefulWidget {
  const ListSheet({Key? key, required this.assetsAudioPlayer})
      : super(key: key);
  final AssetsAudioPlayer assetsAudioPlayer;

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
          child: PlayerBuilder.current(
            player: widget.assetsAudioPlayer,
            builder: (context, current) => ListView.builder(
              controller: scrollController,
              itemExtent: 60.0,
              itemCount: widget.assetsAudioPlayer.playlist!.audios.length + 1,
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
                              '${widget.assetsAudioPlayer.playlist!.audios[index - 1].metas.title}'),
                        ),
                        tileColor: index % 2 == 0
                            ? ColorTheme.darkGrey
                            : ColorTheme.black,
                        titleTextStyle: TextStyleMaker.defaultTextStyle(
                          color: current.index == index - 1
                              ? ColorTheme.lightWine
                              : ColorTheme.white,
                          fontSize: 20,
                        ),
                        selectedColor: ColorTheme.white,
                        selectedTileColor: ColorTheme.lightWine,
                        hoverColor: ColorTheme.lightGrey,
                      );
              },
            ),
          ),
        );
      },
    );
  }
}
