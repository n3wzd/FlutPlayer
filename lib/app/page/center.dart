import 'package:flutter/material.dart';

import '../collection/audio_player.dart';
import '../component/text_scroll.dart';
import './visualizer.dart';

// import '../component/text.dart';
// import '../log.dart' as globals;

class CenterSection extends StatelessWidget {
  const CenterSection({super.key, required this.audioPlayerKit});
  final AudioPlayerKit audioPlayerKit;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const SizedBox(
            height: 45,
          ),
          /*Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 45),
              child: StreamBuilder(
                  stream: globals.debugLogStreamController.stream,
                  builder: (context, data) => TextMaker.normal(globals.debugLog,
                      fontSize: 8,
                      allowLineBreak:
                          true)),
            ),
          ),*/
          Expanded(
            child: Center(
              child: VisualizerController(
                audioPlayerKit: audioPlayerKit,
              ),
            ),
          ),
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
