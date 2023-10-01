import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

import './page1/center.dart';
import './page1/bottom.dart';

class Page1 extends StatefulWidget {
  const Page1({super.key});

  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> {
  final assetsAudioPlayer = AssetsAudioPlayer();

  void openPlayer() async {
    await assetsAudioPlayer.open(
      Audio(
        "assets/audios/ColBreakz - 10.000.mp3",
        metas: Metas(
          title: 'ColBreakz - 10.000',
        ),
      ),
      autoStart: true,
    );
  }

  @override
  void initState() {
    super.initState();
    openPlayer();
  }

  @override
  void dispose() {
    assetsAudioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
