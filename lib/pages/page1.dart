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
  final assetsAudioPlayer = AssetsAudioPlayer.newPlayer();

  void openPlayer() async {
    await assetsAudioPlayer.open(
      Audio(
        "assets/audios/abc.mp3",
        metas: Metas(
          title: 'ColBreakz - 10.000',
        ),
      ),
      autoStart: true,
      showNotification: true,
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
        body: StreamBuilder<Playing?>(
            stream: assetsAudioPlayer.current,
            builder: (context, playing) {
              String title = assetsAudioPlayer.getCurrentAudioTitle;
              Duration duration = const Duration();
              Duration currentPosition = const Duration();

              if (playing.data != null) {
                duration = playing.data!.audio.duration;
              }
              return StreamBuilder(
                stream: assetsAudioPlayer.currentPosition,
                builder: (context, asyncSnapshot) {
                  if (asyncSnapshot.data != null) {
                    currentPosition = asyncSnapshot.data!;
                  }
                  return Container(
                    color: Colors.black,
                    child: Column(
                      children: [
                        Expanded(
                          flex: 2,
                          child: CenterSection(
                            title: title,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: BottomSection(
                            currentPosition: currentPosition,
                            duration: duration,
                            onPlay: () {
                              assetsAudioPlayer.playOrPause();
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
      ),
    );
  }
}
