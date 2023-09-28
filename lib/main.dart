import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

import './components/control_section.dart';
import './components/button_section.dart';

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

    void load() {
      assetsAudioPlayer.open(
        Audio("assets/audios/ColBreakz - 10.000.mp3"),
      );
    }

    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(25.0),
                child: Container(
                  decoration: const BoxDecoration(color: Color(0xFF1D1D1D)),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(25.0),
                child: const Text(
                  'REAPER - BLACK FIRES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 0,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(color: Color(0xFF36081B)),
                child: Column(
                  children: [
                    const ControlSection(),
                    const ButtonSection(),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
