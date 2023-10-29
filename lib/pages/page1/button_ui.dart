import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../components/audio_player_kit.dart';
import '../style/colors.dart';

class ButtonUI extends StatelessWidget {
  const ButtonUI({Key? key, required this.audioPlayerKit}) : super(key: key);
  final AudioPlayerKit audioPlayerKit;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            iconColor: MaterialStateProperty.all(ColorTheme.lightGrey),
            backgroundColor: MaterialStateProperty.all(ColorTheme.transparent),
            shape: MaterialStateProperty.all(const CircleBorder(
                side: BorderSide(color: ColorTheme.lightGrey, width: 1))),
            overlayColor:
                MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return ColorTheme.overlayPressedGrey;
              } else if (states.contains(MaterialState.hovered)) {
                return ColorTheme.overlayHoveredGrey;
              }
              return ColorTheme.transparent;
            }),
          ),
        ),
        useMaterial3: true,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) => IconButton(
              icon: Icon(Icons.shuffle,
                  color: audioPlayerKit.shuffleMode == true
                      ? ColorTheme.lightGrey
                      : ColorTheme.disableGrey),
              iconSize: 35,
              onPressed: () {
                audioPlayerKit.toggleShuffleMode();
                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 35,
            onPressed: () async {
              await audioPlayerKit.seekToPrevious();
            },
          ),
          const SizedBox(width: 20),
          audioPlayerKit.playingStreamBuilder(
            (context, isPlaying) => IconButton(
              isSelected: isPlaying.data,
              icon: const Icon(Icons.play_arrow),
              selectedIcon: const Icon(Icons.pause),
              iconSize: 55,
              onPressed: () async {
                if (audioPlayerKit.isPlaying) {
                  await audioPlayerKit.pause();
                } else {
                  await audioPlayerKit.play();
                }
              },
            ),
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: 35,
            onPressed: () async {
              await audioPlayerKit.seekToNext();
            },
          ),
          const SizedBox(width: 20),
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) => IconButton(
              icon: audioPlayerKit.loopMode == LoopMode.one
                  ? const Icon(Icons.repeat_one, color: ColorTheme.lightGrey)
                  : Icon(Icons.repeat,
                      color: audioPlayerKit.loopMode == LoopMode.off
                          ? ColorTheme.disableGrey
                          : ColorTheme.lightGrey),
              iconSize: 35,
              onPressed: () {
                audioPlayerKit.toggleLoopMode();
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}
