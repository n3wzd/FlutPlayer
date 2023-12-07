import 'package:flutter/material.dart';

import '../collection/audio_player.dart';
import '../collection/preference.dart';
import '../component/text_scroll.dart';
import './visualizer.dart';

// import '../component/text.dart';
// import '../log.dart' as global;

class CenterSection extends StatelessWidget {
  const CenterSection({super.key, required this.audioPlayerKit});
  final AudioPlayerKit audioPlayerKit;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          /*Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 45),
              child: StreamBuilder(
                  stream: globals.debugLogStreamController.stream,
                  builder: (context, data) => TextMaker.normal(global.debugLog,
                      fontSize: 8, allowLineBreak: true)),
            ),
          ),*/
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Visibility(
                    visible: Preference.enableNCSLogo,
                    child: Expanded(
                      child: Center(
                          child: LayoutBuilder(
                        builder: (context, constraints) => Image.asset(
                          'assets/images/NoCopyrightSounds_logo.png',
                          width: constraints.maxWidth * 0.6,
                        ),
                      )),
                    ),
                  ),
                  Visibility(
                    visible: Preference.enableVisualizer,
                    child: Expanded(
                      child: Center(
                          child: LayoutBuilder(
                        builder: (context, constraints) => VisualizerController(
                            audioPlayerKit: audioPlayerKit,
                            widgetWidth: constraints.maxWidth,
                            widgetHeight: constraints.maxHeight),
                      )),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: !Preference.enableFullScreen,
            child: SizedBox(
              height: 80,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Center(
                  child: audioPlayerKit.trackStreamBuilder(
                      (context, duration) => ScrollAnimationText(
                          text: audioPlayerKit.currentAudioTitle,
                          fontSize: 30)),
                ),
              ),
            ),
          ),
        ],
      );
}
