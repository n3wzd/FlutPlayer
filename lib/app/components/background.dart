import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:math';
import 'dart:io';

import '../utils/playlist.dart';
import '../components/stream_builder.dart';
import '../models/color.dart';

class Background extends StatelessWidget {
  const Background({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Opacity(
      opacity: 0.4,
      child: AudioStreamBuilder.backgroundFile((context, value) {
        const videoExtensions = ['mp4'];
        var backgroundPath = PlayList.instance.currentAudioBackground;
        if (backgroundPath != null) {
          var file = File(backgroundPath);
          if (file.existsSync()) {
            if (videoExtensions.contains(backgroundPath.split('.').last)) {
              return VideoBackground(path: backgroundPath);
            } else {
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: FileImage(file),
                  ),
                ),
              );
            }
          }
        }
        return const DefaultBackground();
      }));
}

class DefaultBackground extends StatefulWidget {
  const DefaultBackground({Key? key}) : super(key: key);

  @override
  State<DefaultBackground> createState() => _DefaultBackgroundState();
}

class _DefaultBackgroundState extends State<DefaultBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final r = sqrt(2) / 4;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..repeat();

    _animation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AudioStreamBuilder.visualizerColor((context, value) {
      int colorValue =
          PlayList.instance.currentAudioColor ?? ColorPalette.white.value;
      if (colorValue == 0) {
        colorValue = ColorPalette.white.value;
      }
      Color startColor = Color(colorValue);
      Color endColor = ColorPalette.black;
      if (startColor == ColorPalette.black) {
        startColor = ColorPalette.black;
        endColor = ColorPalette.white;
      }

      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                startColor,
                endColor,
              ],
              stops: const [0, 0.5],
              center: Alignment(
                (0.5 - r) +
                    r * cos(_animation.value) +
                    r * cos(_animation.value * 4),
                (0.5 - r) +
                    r * sin(_animation.value) +
                    r * sin(_animation.value * 4),
              ),
              radius: 1.5,
            ),
          ),
        ),
      );
    });
  }
}

class VideoBackground extends StatefulWidget {
  const VideoBackground({Key? key, required this.path}) : super(key: key);
  final String path;

  @override
  State<VideoBackground> createState() => VideoBackgroundState();
}

class VideoBackgroundState extends State<VideoBackground> {
  late final player = Player();
  late final controller = VideoController(player);

  @override
  void initState() {
    super.initState();
    player.setPlaylistMode(PlaylistMode.single);
    player.setVolume(0);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    player.open(Media(widget.path));
    return Center(
      child: Video(
        controller: controller,
        controls: (state) {
          return Container();
        },
        fit: BoxFit.cover,
      ),
    );
  }
}
