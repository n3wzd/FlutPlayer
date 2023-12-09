import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../global.dart' as global;
import '../utils/stream_controller.dart';
import '../utils/audio_player.dart';
import './stream_builder.dart';
import '../widgets/button.dart';
import '../models/play_list_order.dart';
import '../models/color.dart';

class FullscreenButton extends StatelessWidget {
  const FullscreenButton({super.key});

  static void toggleFullscreen() {
    global.isFullScreen = !global.isFullScreen;
    if (global.isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    }
    AudioStreamController.enabledFullsccreen.add(null);
  }

  @override
  Widget build(BuildContext context) => ButtonFactory.iconButton(
        icon: const Icon(Icons.fullscreen),
        iconSize: 30,
        onPressed: toggleFullscreen,
        outline: false,
      );
}

class SeekToPreviousButton extends StatelessWidget {
  const SeekToPreviousButton({super.key, this.iconSize, this.outline});
  final double? iconSize;
  final bool? outline;

  @override
  Widget build(BuildContext context) => ButtonFactory.iconButton(
        icon: const Icon(Icons.skip_previous),
        iconSize: iconSize ?? 35,
        outline: outline ?? true,
        onPressed: () async {
          await AudioPlayerKit.instance.seekToPrevious();
        },
      );
}

class SeekToNextButton extends StatelessWidget {
  const SeekToNextButton({super.key, this.iconSize, this.outline});
  final double? iconSize;
  final bool? outline;

  @override
  Widget build(BuildContext context) => ButtonFactory.iconButton(
        icon: const Icon(Icons.skip_next),
        iconSize: iconSize ?? 35,
        outline: outline ?? true,
        onPressed: () async {
          await AudioPlayerKit.instance.seekToNext();
        },
      );
}

class PlayButton extends StatelessWidget {
  const PlayButton({super.key, this.iconSize, this.outline});
  final double? iconSize;
  final bool? outline;

  @override
  Widget build(BuildContext context) => AudioStreamBuilder.playing(
        (context, isPlaying) => ButtonFactory.iconButton(
          isSelected: AudioPlayerKit.instance.isPlaying,
          icon: const Icon(Icons.play_arrow),
          selectedIcon: const Icon(Icons.pause),
          iconSize: iconSize ?? 35,
          outline: outline ?? true,
          onPressed: AudioPlayerKit.instance.togglePlayMode,
        ),
      );
}

class ShuffleButton extends StatelessWidget {
  const ShuffleButton({super.key, this.iconSize, this.outline});
  final double? iconSize;
  final bool? outline;

  @override
  Widget build(BuildContext context) => AudioStreamBuilder.playListOrderState(
        (context, value) => ButtonFactory.iconButton(
          icon: Icon(Icons.shuffle,
              color: AudioPlayerKit.instance.playListOrderState ==
                      PlayListOrderState.shuffled
                  ? ColorPalette.lightGrey
                  : ColorPalette.disableGrey),
          iconSize: 35,
          onPressed: () {
            AudioPlayerKit.instance.toggleShuffleMode();
          },
        ),
      );
}

class LoopButton extends StatelessWidget {
  const LoopButton({super.key, this.iconSize, this.outline});
  final double? iconSize;
  final bool? outline;

  @override
  Widget build(BuildContext context) => AudioStreamBuilder.loopMode(
        (context, value) => ButtonFactory.iconButton(
          icon: AudioPlayerKit.instance.loopMode == LoopMode.one
              ? const Icon(Icons.repeat_one, color: ColorPalette.lightGrey)
              : Icon(Icons.repeat,
                  color: AudioPlayerKit.instance.loopMode == LoopMode.off
                      ? ColorPalette.disableGrey
                      : ColorPalette.lightGrey),
          iconSize: 35,
          onPressed: () {
            AudioPlayerKit.instance.toggleLoopMode();
          },
        ),
      );
}
