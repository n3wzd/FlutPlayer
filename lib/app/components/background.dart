import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:math';
import 'dart:io';
import 'dart:async';
import '../global.dart' as global;
import '../utils/playlist.dart';
import '../utils/preference.dart';
import '../components/stream_builder.dart';
import '../models/color.dart';
import '../models/enum.dart';

class Background extends StatelessWidget {
  const Background({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Opacity(
      opacity: 0.75,
      child: AudioStreamBuilder.backgroundFile((context, value) {
        String? backgroundPath;
        if (Preference.backgroundMethod == BackgroundMethod.specific) {
          backgroundPath = PlayList.instance.currentAudioBackground;
        } else if (Preference.backgroundMethod == BackgroundMethod.random) {
          if (global.backgroundPathList.isNotEmpty) {
            backgroundPath = global
                .backgroundPathList[global.backgroundPathListCurrentIndex];
          }
        }

        if (backgroundPath != null && backgroundPath != 'null') {
          File file = File(backgroundPath);
          if (file.existsSync()) {
            const videoExtensions = ['mp4'];
            if (videoExtensions.contains(backgroundPath.split('.').last)) {
              return VideoBackground(path: backgroundPath);
            } else {
              return ImageBackground(file: file);
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
      String value = PlayList.instance.currentAudioColor ?? 'ffffff';
      value = (value != 'null') ? value : 'ffffff';

      Color startColor = stringToColor(value);
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

class ImageBackground extends StatefulWidget {
  const ImageBackground({Key? key, required this.file}) : super(key: key);
  final File file;

  @override
  State<ImageBackground> createState() => _ImageBackgroundState();
}

class _ImageBackgroundState extends State<ImageBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  StreamSubscription<void>? _triggerRotation;
  StreamSubscription<void>? _triggerScale;
  double _rotateSpeed = 1;
  double _rotateDirection = 1;
  double _angle = 0;
  double _scale = 1;
  final double _scaleSpeed = 1.5;
  double _prevControllerValue = 0;
  bool _toggleImage = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _controller.addListener(() {
      var value = _controller.value - _prevControllerValue;
      _prevControllerValue = _controller.value;
      value = (value < 0) ? value + 1 : value;
      if (Preference.rotateBackground) {
        _angle += value * _rotateSpeed * _rotateDirection;
        _angle = _angle % 1;
        setState(() {});
      }
      if (Preference.scaleBackground) {
        _scale += value * _scaleSpeed;
        setState(() {});
      }
    });

    _triggerRotation = setRotationTrigger();
    _triggerScale = setScaleTrigger();
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_triggerRotation != null) {
      _triggerRotation!.cancel();
    }
    if (_triggerScale != null) {
      _triggerScale!.cancel();
    }
    super.dispose();
  }

  StreamSubscription<void>? setRotationTrigger() {
    return Stream<void>.fromFuture(Future<void>.delayed(
            Duration(seconds: 20 + Random().nextInt(20)), () {}))
        .listen((x) {
      if (Preference.rotateBackground) {
        _rotateSpeed = 0.25 + Random().nextDouble() * 1.5;
        _rotateDirection *= -1;
      }
      _triggerRotation = setRotationTrigger();
    });
  }

  StreamSubscription<void>? setScaleTrigger() {
    return Stream<void>.fromFuture(
            Future<void>.delayed(const Duration(seconds: 10), () {}))
        .listen((x) {
      if (Preference.scaleBackground) {
        _scale = 1;
        _toggleImage = !_toggleImage;
      }
      _triggerScale = setScaleTrigger();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double rotationScale = 1;
      if (Preference.rotateBackground) {
        double a = min(constraints.maxWidth, constraints.maxHeight);
        double b = max(constraints.maxWidth, constraints.maxHeight);
        rotationScale = (a > 0) ? sqrt(a * a + b * b) / a : 1;
      }
      return AudioStreamBuilder.imageBackgroundAnimation((context, data) {
        _angle = 0;
        _scale = 1;
        return AnimatedSwitcher(
          duration: const Duration(seconds: 1),
          child: Transform.scale(
            key: ValueKey<bool>(_toggleImage),
            scale: _scale * rotationScale,
            child: Transform.rotate(
              angle: _angle * 2 * pi,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: FileImage(widget.file),
                  ),
                ),
              ),
            ),
          ),
        );
      });
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
