import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

class ButtonUI extends StatelessWidget {
  const ButtonUI({Key? key, required this.assetsAudioPlayer}) : super(key: key);
  final AssetsAudioPlayer assetsAudioPlayer;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            iconColor: MaterialStateProperty.all(const Color(0xCCFFFFFF)),
            backgroundColor: MaterialStateProperty.all(Colors.transparent),
            shape: MaterialStateProperty.all(const CircleBorder(
                side: BorderSide(color: Color(0xCCFFFFFF), width: 1))),
            overlayColor:
                MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return const Color(0x44FFFFFF);
              } else if (states.contains(MaterialState.hovered)) {
                return const Color(0x33FFFFFF);
              }
              return Colors.transparent;
            }),
          ),
        ),
        useMaterial3: true,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StreamBuilder<bool>(
            stream: assetsAudioPlayer.isShuffling,
            builder: (context, isShuffling) => IconButton(
              isSelected: isShuffling.data,
              icon: const Icon(Icons.moving),
              selectedIcon: const Icon(Icons.shuffle),
              iconSize: 35,
              onPressed: () {
                assetsAudioPlayer.toggleShuffle();
              },
            ),
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 35,
            onPressed: () async {
              await assetsAudioPlayer.previous();
            },
          ),
          const SizedBox(width: 20),
          PlayerBuilder.isPlaying(
            player: assetsAudioPlayer,
            builder: (context, isPlaying) => IconButton(
              isSelected: isPlaying,
              icon: const Icon(Icons.play_arrow),
              selectedIcon: const Icon(Icons.pause),
              iconSize: 55,
              onPressed: () {
                assetsAudioPlayer.playOrPause();
              },
            ),
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: 35,
            onPressed: () async {
              await assetsAudioPlayer.next();
            },
          ),
          const SizedBox(width: 20),
          PlayerBuilder.loopMode(
            player: assetsAudioPlayer,
            builder: (context, loopMode) => IconButton(
              icon: loopMode == LoopMode.playlist
                  ? const Icon(Icons.repeat)
                  : (loopMode == LoopMode.single
                      ? const Icon(Icons.repeat_one)
                      : const Icon(Icons.arrow_forward)),
              iconSize: 35,
              onPressed: () {
                assetsAudioPlayer.toggleLoop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
