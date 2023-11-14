import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../collection/audio_player.dart';
import '../style/theme.dart';
import '../style/color.dart';

class ButtonUI extends StatelessWidget {
  const ButtonUI({Key? key, required this.audioPlayerKit}) : super(key: key);
  final AudioPlayerKit audioPlayerKit;

  @override
  Widget build(BuildContext context) => ThemeMaker.iconButton(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            audioPlayerKit.shuffleModeStreamBuilder(
              (context, shuffleMode) => IconButton(
                icon: Icon(Icons.shuffle,
                    color: audioPlayerKit.shuffleMode == true
                        ? ColorMaker.lightGrey
                        : ColorMaker.disableGrey),
                iconSize: 35,
                onPressed: () {
                  audioPlayerKit.toggleShuffleMode();
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
                isSelected: audioPlayerKit.isPlaying,
                icon: const Icon(Icons.play_arrow),
                selectedIcon: const Icon(Icons.pause),
                iconSize: 55,
                onPressed: audioPlayerKit.togglePlayMode,
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
            audioPlayerKit.loopModeStreamBuilder(
              (context, loopMode) => IconButton(
                icon: audioPlayerKit.loopMode == LoopMode.one
                    ? const Icon(Icons.repeat_one, color: ColorMaker.lightGrey)
                    : Icon(Icons.repeat,
                        color: audioPlayerKit.loopMode == LoopMode.off
                            ? ColorMaker.disableGrey
                            : ColorMaker.lightGrey),
                iconSize: 35,
                onPressed: () {
                  audioPlayerKit.toggleLoopMode();
                },
              ),
            ),
          ],
        ),
      );
}