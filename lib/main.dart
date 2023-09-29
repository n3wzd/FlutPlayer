import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

import './pages/screen1/center.dart';
import './pages/screen1/bottom.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final assetsAudioPlayer = AssetsAudioPlayer();

    void load() {
      assetsAudioPlayer.open(
        Audio("assets/audios/ColBreakz - 10.000.mp3"),
      );
    }

    return Scaffold(
      body: Container(
        color: Colors.black,
        child: const Column(
          children: [
            Expanded(
              flex: 2,
              child: CenterSection(),
            ),
            Expanded(
              flex: 1,
              child: BottomSection(),
            )
          ],
        ),
      ),
    );
  }
}
