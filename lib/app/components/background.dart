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
        BackgroundTransitionTimer.instance.reset();
        BackgroundData? background;
        if (Preference.backgroundMethod == BackgroundMethod.specific) {
          background = PlayList.instance.currentAudioBackground;
        } else if (Preference.backgroundMethod == BackgroundMethod.random) {
          if (BackgroundManager.instance.isListNotEmpty) {
            background = BackgroundManager.instance.currentBackgroundData;
          }
        }
        if (background != null) {
          File backgroundFile = File(background.path);
          if (backgroundFile.existsSync()) {
            const videoExtensions = ['mp4'];
            bool isVideo = videoExtensions.contains(background.path.split('.').last);
            if(isVideo) {
              VideoBackgroundManager.instance.load(background.path);
            } else {
              ImageBackgroundManager.instance.load(background);
            }
            return ImageBackgroundManager.instance.widget;
            /*FileBackground(
              background: background,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Visibility(
                    visible: !isVideo,
                    replacement: const SizedBox(height: 0, width: 0),
                    child: Expanded (
                      child: ImageBackgroundManager.instance.widget,
                    ),
                  ),
                  Visibility(
                    visible: isVideo,
                    replacement: const SizedBox(height: 0, width: 0),
                    child: Expanded (
                      child: VideoBackgroundManager.instance.widget,
                    ),
                  ),
                ],
              ),
            );*/
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

class ImageBackgroundManager {
  ImageBackgroundManager._();
  static final ImageBackgroundManager _instance = ImageBackgroundManager._();
  static ImageBackgroundManager get instance => _instance;

  late final List<ImageBackground> _viewerList = List.generate(2, 
      (_) => ImageBackground(background: BackgroundData(path: ""), imageFile: null));
  int _currentIndexViewerList = 0;

  ImageBackground get viewer => _viewerList[_currentIndexViewerList];
  ImageBackground get viewerSub =>
      _viewerList[(_currentIndexViewerList + 1) % 2];

  get widget => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _viewerList.length,
          (index) => Visibility(
            visible: _currentIndexViewerList == index,
            replacement: const SizedBox(height: 0, width: 0),
            child: Expanded (
              child: _viewerList[index],
            ),
          ),
        ),
      ),
    );

  Future<void> load(BackgroundData background) async {
    final imageFile = FileImage(File(background.path));
    await imageFile.obtainKey(const ImageConfiguration());
    _viewerList[(_currentIndexViewerList + 1) % 2] = ImageBackground(background: background, imageFile: imageFile);
    _currentIndexViewerList = (_currentIndexViewerList + 1) % 2;
  }
}

class ImageBackground extends StatefulWidget {
  const ImageBackground({Key? key, required this.background, required this.imageFile}) : super(key: key);
  final BackgroundData background;
  final FileImage? imageFile;

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
    if(widget.imageFile != null) {
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
                    image: widget.imageFile!,
                  ),
                ),
              ),
            ),
          ),
        );
      });
    } else {
      return const SizedBox(height: 0, width: 0);
    }
  }
}

class VideoBackgroundManager {
  VideoBackgroundManager._();
  static final VideoBackgroundManager _instance = VideoBackgroundManager._();
  static VideoBackgroundManager get instance => _instance;

  late final List<Player> _playerList = List.generate(2, (_) => Player());
  late final List<VideoController> _controllerList = 
      _playerList.map((player) => VideoController(player)).toList();
  int _currentIndexPlayerList = 0;

  Player get player => _playerList[_currentIndexPlayerList];
  Player get playerSub =>
      _playerList[(_currentIndexPlayerList + 1) % 2];

  get widget => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _controllerList.length,
          (index) => Visibility(
            visible: _currentIndexPlayerList == index,
            replacement: const SizedBox(height: 0, width: 0),
            child: Expanded (
              child: Video(
                controller: _controllerList[_currentIndexPlayerList],
                controls: (state) => Container(),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );

  void init() {
    _playerList[0].setPlaylistMode(PlaylistMode.single);
    _playerList[0].setVolume(0);
    _playerList[1].setPlaylistMode(PlaylistMode.single);
    _playerList[1].setVolume(0);
  }

  void dispose() {
    _playerList[0].dispose();
    _playerList[1].dispose();
  }

  Future<void> load(String path) async {
    await playerSub.open(Media(path));
    _currentIndexPlayerList = (_currentIndexPlayerList + 1) % 2;
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
