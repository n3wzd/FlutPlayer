import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

class CenterSection extends StatelessWidget {
  const CenterSection({Key? key, required this.assetsAudioPlayer})
      : super(key: key);
  final AssetsAudioPlayer assetsAudioPlayer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 80,
          child: SizedBox(height: 1),
        ),
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 35.0, vertical: 10.0),
            child: Container(
              decoration: const BoxDecoration(color: Color(0xFF1D1D1D)),
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: Container(
            alignment: Alignment.center,
            child: Text(
              assetsAudioPlayer.getCurrentAudioTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
