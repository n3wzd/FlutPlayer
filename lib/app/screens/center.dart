import 'package:flutter/material.dart';
import '../utils/playlist.dart';
import '../widgets/text.dart';
import '../components/visualizer.dart';
import '../components/optional_visibility.dart';
import '../components/stream_builder.dart';
import 'dart:math';

class CenterSection extends StatelessWidget {
  const CenterSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  OptionalVisibility.logoNCS(
                    context,
                    Expanded(
                      child: Center(
                          child: LayoutBuilder(
                        builder: (context, constraints) => Image.asset(
                          'assets/images/NoCopyrightSounds_logo.png',
                          width: min(constraints.maxWidth * 0.6,
                              constraints.maxHeight * 0.25 * 2.5),
                        ),
                      )),
                    ),
                  ),
                  OptionalVisibility.visualizer(
                    context,
                    Expanded(
                      child: Center(
                          child: LayoutBuilder(
                        builder: (context, constraints) => VisualizerController(
                            widgetWidth: constraints.maxWidth,
                            widgetHeight: constraints.maxHeight),
                      )),
                    ),
                  ),
                ],
              ),
            ),
          ),
          OptionalVisibility.fullScreen(
            context,
            SizedBox(
              height: 80,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Center(
                  child: AudioStreamBuilder.track((context, duration) =>
                      TextFactory.scrollAnimationText(
                          text: PlayList.instance.currentAudioTitle,
                          fontSize: 30)),
                ),
              ),
            ),
          ),
        ],
      );
}
