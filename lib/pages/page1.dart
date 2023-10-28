import 'package:flutter/material.dart';

import './page1/center.dart';
import './page1/bottom.dart';
import './page1/list_sheet.dart';

import './components/audio_player_kit.dart';

class Page1 extends StatefulWidget {
  const Page1({super.key});

  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> {
  final audioPlayerKit = AudioPlayerKit();

  @override
  void initState() {
    super.initState();
    audioPlayerKit.init();
  }

  @override
  void dispose() {
    audioPlayerKit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                color: Colors.black,
                child: Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CenterSection(
                        audioPlayerKit: audioPlayerKit,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: BottomSection(
                        audioPlayerKit: audioPlayerKit,
                      ),
                    ),
                  ],
                ),
              ),
              ListSheet(audioPlayerKit: audioPlayerKit),
            ],
          ),
        ),
      ),
    );
  }
}
