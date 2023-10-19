import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

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
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          color: Colors.grey[100],
          child: ListView.builder(
            controller: scrollController,
            itemCount: widget.assetsAudioPlayer.playlist!.audios.length + 1,
            itemBuilder: (BuildContext context, int index) {
              return index == 0
                  ? Center(
                      child: ListTile(
                          title: Icon(_isExpand
                              ? Icons.arrow_drop_down
                              : Icons.arrow_drop_up),
                          onTap: () async {
                            await controller.animateTo(
                                _isExpand ? minChildSize : maxChildSize,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutQuart);
                            setState(() {
                              _isExpand = !_isExpand;
                            });
                          }),
                    )
                  : ListTile(
                      title: Text(
                          '${widget.assetsAudioPlayer.playlist!.audios[index - 1].metas.title}'),
                    );
            },
          ),
        );
      },
    );
  }
}
