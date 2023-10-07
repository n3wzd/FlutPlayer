import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

import '../components/button.dart';

class ButtonUI extends StatelessWidget {
  const ButtonUI({Key? key, required this.assetsAudioPlayer}) : super(key: key);
  final AssetsAudioPlayer assetsAudioPlayer;

  void onPlay() {
    assetsAudioPlayer.playOrPause();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Button(
          buttonRadius: 50,
          onPressed: onPlay,
          icon: const Icon(
            Icons.shuffle,
            color: Colors.white,
            size: 35,
          ),
        ),
        const SizedBox(width: 20),
        Button(
          buttonRadius: 50,
          onPressed: onPlay,
          icon: const Icon(
            Icons.skip_previous,
            color: Colors.white,
            size: 35,
          ),
        ),
        const SizedBox(width: 20),
        Button(
          buttonRadius: 70,
          onPressed: onPlay,
          icon: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 55,
          ),
        ),
        const SizedBox(width: 20),
        Button(
          buttonRadius: 50,
          onPressed: onPlay,
          icon: const Icon(
            Icons.skip_next,
            color: Colors.white,
            size: 35,
          ),
        ),
        const SizedBox(width: 20),
        Button(
          buttonRadius: 50,
          onPressed: onPlay,
          icon: const Icon(
            Icons.repeat,
            color: Colors.white,
            size: 35,
          ),
        ),
      ],
    );
  }
}
