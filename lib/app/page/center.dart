import 'package:flutter/material.dart';

import '../collection/audio_player.dart';
import '../component/text_scroll.dart';
import '../component/text.dart';

import '../component/button.dart';
import 'dart:async';
import '../global.dart' as globals;

class CenterSection extends StatelessWidget {
  CenterSection({super.key, required this.audioPlayerKit});
  final AudioPlayerKit audioPlayerKit;
  final _controller = StreamController<void>.broadcast();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const SizedBox(
            height: 45,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 45),
              child: StreamBuilder(
                  stream: _controller.stream,
                  builder: (context, data) => TextMaker.normal(globals.debugLog,
                      fontSize: 8,
                      allowLineBreak:
                          true)), /*Container(
                decoration: const BoxDecoration(color: ColorMaker.darkGrey),
              ),*/
            ),
          ),
          ButtonMaker.text(
              text: 'dd',
              onPressed: () {
                _controller.add(null);
              }),
          SizedBox(
            height: 80,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Center(
                child: audioPlayerKit.trackStreamBuilder((context, duration) =>
                    ScrollAnimationText(
                        text: audioPlayerKit.currentAudioTitle, fontSize: 30)),
              ),
            ),
          ),
        ],
      );
}
