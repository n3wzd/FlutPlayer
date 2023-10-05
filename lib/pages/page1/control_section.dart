import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

import './control_slider.dart';
import '../components/time_text.dart';

class ControlSection extends StatefulWidget {
  const ControlSection({Key? key, required this.assetsAudioPlayer})
      : super(key: key);
  final AssetsAudioPlayer assetsAudioPlayer;

  String getTimeFormat(Duration d) {
    int minutes = d.inMinutes % 60, seconds = d.inSeconds % 60;
    String minutesPadding = minutes < 10 ? '0' : '';
    String secondsPadding = seconds < 10 ? '0' : '';
    return '$minutesPadding$minutes:$secondsPadding$seconds';
  }

  @override
  State<ControlSection> createState() => _ControlSectionState();
}

class _ControlSectionState extends State<ControlSection> {
  Duration trackDuration = const Duration();
  Duration trackCurrentPosition = const Duration();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Playing?>(
      stream: widget.assetsAudioPlayer.current,
      builder: (context, playing) {
        if (playing.data != null) {
          trackDuration = playing.data!.audio.duration;
        }
        return StreamBuilder(
          stream: widget.assetsAudioPlayer.currentPosition,
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.data != null) {
              trackCurrentPosition = asyncSnapshot.data!;
            }
            return Column(
              children: [
                Container(
                  height: 24,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: ControlSlider(
                    trackDuration: trackDuration,
                    trackCurrentPosition: trackCurrentPosition,
                    assetsAudioPlayer: widget.assetsAudioPlayer,
                    onUpdated: (int value) {
                      trackCurrentPosition =
                          Duration(milliseconds: value.toInt());
                    },
                  ),
                ),
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 35.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: TimeText(
                              text: widget.getTimeFormat(trackCurrentPosition)),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerRight,
                          child: TimeText(
                              text: widget.getTimeFormat(trackDuration)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
