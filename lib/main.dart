import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEW BEAT',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final assetsAudioPlayer = AssetsAudioPlayer();

    void load() {}

    return Scaffold(
      appBar: AppBar(
        title: const Text('NEWBEAT'),
      ),
      body: Center(
        child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: 10,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {
                  assetsAudioPlayer.open(
                    Audio("assets/audios/ColBreakz - 10.000.mp3"),
                  );
                  print('GO!!');
                },
                child: Container(
                  color: Colors.blue,
                  child: Text('Item $index'),
                ),
              );
            }),
      ),
    );
  }
}
