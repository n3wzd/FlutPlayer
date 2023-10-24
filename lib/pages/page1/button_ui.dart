import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../style/colors.dart';

class ButtonUI extends StatelessWidget {
  const ButtonUI({Key? key, required this.audioPlayer}) : super(key: key);
  final AudioPlayer audioPlayer;

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
          IconButton(
            icon: const Icon(Icons.shuffle),
            iconSize: 35,
            onPressed: () async {},
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 35,
            onPressed: () async {
              await audioPlayer.seekToPrevious();
            },
          ),
          const SizedBox(width: 20),
          StreamBuilder<bool>(
            stream: audioPlayer.playingStream,
            builder: (context, isPlaying) => IconButton(
              isSelected: isPlaying.data,
              icon: const Icon(Icons.play_arrow),
              selectedIcon: const Icon(Icons.pause),
              iconSize: 55,
              onPressed: () async {
                if (audioPlayer.playing) {
                  await audioPlayer.pause();
                } else {
                  await audioPlayer.play();
                }
              },
            ),
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: 35,
            onPressed: () async {
              await audioPlayer.seekToNext();
            },
          ),
          const SizedBox(width: 20),
          StreamBuilder<LoopMode>(
            stream: audioPlayer.loopModeStream,
            builder: (context, loopMode) => IconButton(
              icon: loopMode.data == LoopMode.one
                  ? const Icon(Icons.repeat_one)
                  : Icon(Icons.repeat,
                      color: loopMode.data == LoopMode.off
                          ? ColorTheme.disableGrey
                          : ColorTheme.lightGrey),
              iconSize: 35,
              onPressed: () {
                if (audioPlayer.loopMode == LoopMode.off) {
                  audioPlayer.setLoopMode(LoopMode.one);
                } else if (audioPlayer.loopMode == LoopMode.one) {
                  audioPlayer.setLoopMode(LoopMode.all);
                } else {
                  audioPlayer.setLoopMode(LoopMode.off);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
