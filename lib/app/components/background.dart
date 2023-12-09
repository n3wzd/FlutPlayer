import 'package:flutter/material.dart';
import 'dart:math';

import '../utils/audio_player.dart';
import '../components/stream_builder.dart';
import '../models/color.dart';

class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      const Opacity(opacity: 0.25, child: GradientBackground());
}

class GradientBackground extends StatefulWidget {
  const GradientBackground({Key? key}) : super(key: key);

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
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
      Color startColor = Color(AudioPlayerKit.instance.currentAudioColor ??
          ColorPalette.white.value);
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
