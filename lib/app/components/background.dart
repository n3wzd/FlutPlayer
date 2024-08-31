import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:math';
import 'dart:io';
import 'dart:async';
import '../global.dart' as global;
import '../utils/background_manager.dart';
import '../utils/playlist.dart';
import '../utils/preference.dart';
import '../utils/stream_controller.dart';
import '../components/stream_builder.dart';
import '../models/color.dart';
import '../models/enum.dart';
import '../models/data.dart';

class Background extends StatelessWidget {
  const Background({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      AudioStreamBuilder.backgroundFile((context, value) {
        BackgroundData? background;
        if (Preference.backgroundMethod == BackgroundMethod.specific) {
          background = PlayList.instance.currentAudioBackground;
        } else if (Preference.backgroundMethod == BackgroundMethod.random) {
          if (BackgroundManager.instance.isListNotEmpty) {
            background = BackgroundManager.instance.currentBackgroundData;
          }
        }
        if (background != null) {
          File imageFile = File(background.path);
          if (imageFile.existsSync()) {
            const videoExtensions = ['mp4'];
            return FileBackground(
              background: background,
              child: videoExtensions.contains(background.path.split('.').last)
                  ? VideoBackground(path: background.path)
                  : ImageBackground(background: background),
            );
          }
        }
        return const DefaultBackground();
      });
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
      Color startColor = stringToColor(global.currentVisualizerColor);
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
  const ImageBackground({Key? key, required this.background}) : super(key: key);
  final BackgroundData background;

  @override
  State<ImageBackground> createState() => _ImageBackgroundState();
}

class _ImageBackgroundState extends State<ImageBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late StreamSubscription<void> _triggerRotation;
  late StreamSubscription<void> _triggerScale;
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
      if (widget.background.rotate) {
        _angle += value * _rotateSpeed * _rotateDirection;
        _angle = _angle % 1;
        setState(() {});
      }
      if (widget.background.scale) {
        _scale += value * _scaleSpeed;
        setState(() {});
      }
    });

    _triggerRotation = setRotationTrigger();
    _triggerScale = setScaleTrigger();

    AudioStreamController.imageBackgroundAnimation.stream.listen((data) {
      reset();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _triggerRotation.cancel();
    _triggerScale.cancel();
    super.dispose();
  }

  StreamSubscription<void> setRotationTrigger() {
    return Stream<void>.fromFuture(Future<void>.delayed(
            Duration(seconds: 15 + Random().nextInt(15)), () {}))
        .listen((x) {
      if (widget.background.rotate) {
        _rotateSpeed = 0.25 + Random().nextDouble() * 1.5;
        _rotateDirection *= -1;
      }
      _triggerRotation = setRotationTrigger();
    });
  }

  StreamSubscription<void> setScaleTrigger() {
    return Stream<void>.fromFuture(
            Future<void>.delayed(const Duration(seconds: 10), () {}))
        .listen((x) {
      if (widget.background.scale) {
        _scale = 1;
        _toggleImage = !_toggleImage;
      }
      _triggerScale = setScaleTrigger();
    });
  }

  void reset() async {
    await _triggerRotation.cancel();
    await _triggerScale.cancel();
    _angle = 0;
    _scale = 1;
    _triggerRotation = setRotationTrigger();
    _triggerScale = setScaleTrigger();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double rotationScale = 1;
      if (widget.background.rotate) {
        double a = min(constraints.maxWidth, constraints.maxHeight);
        double b = max(constraints.maxWidth, constraints.maxHeight);
        rotationScale = (a > 0) ? sqrt(a * a + b * b) / a : 1;
      }
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
                  image: FileImage(File(widget.background.path)),
                ),
              ),
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

class FileBackground extends StatelessWidget {
  const FileBackground(
      {Key? key, required this.child, required this.background})
      : super(key: key);
  final Widget child;
  final BackgroundData background;

  static Color getColor() {
    String color = PlayList.instance.currentAudioColor ?? 'ffffff';
    color = (color != 'null') ? color : 'ffffff';
    return stringToColor(color);
  }

  @override
  Widget build(BuildContext context) => child;
}
