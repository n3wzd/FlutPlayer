import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:math';
import 'dart:io';
import 'dart:async';
import '../app_state.dart';
import '../utils/background_manager.dart';
import '../components/stream_builder.dart';
import '../models/color.dart';
import '../models/data.dart';

class Background extends StatelessWidget {
  const Background({super.key});

  @override
  Widget build(BuildContext context) => AudioStreamBuilder.backgroundFile((
    context,
    value,
  ) {
    final BackgroundData? background = BackgroundManager.instance.isListNotEmpty
        ? BackgroundManager.instance.currentBackgroundData
        : null;
    if (background == null) {
      debugPrint(
        '[Background] fallback to default: background pool is empty '
        '(groups=${BackgroundManager.instance.groups.length}, '
        'active=${BackgroundManager.instance.groups.where((g) => g.active).length}).',
      );
    }
    if (background != null) {
      File backgroundFile = File(background.path);
      if (backgroundFile.existsSync()) {
        const videoExtensions = ['mp4'];
        bool isVideo = videoExtensions.contains(
          background.path.split('.').last,
        );
        if (isVideo) {
          VideoBackgroundManager.instance.load(background.path);
        } else {
          ImageBackgroundManager.instance.load(background);
        }
        return FileBackground(
          background: background,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Visibility(
                visible: !isVideo,
                replacement: const SizedBox(height: 0, width: 0),
                child: Expanded(child: ImageBackgroundManager.instance.widget),
              ),
              Visibility(
                visible: isVideo,
                replacement: const SizedBox(height: 0, width: 0),
                child: Expanded(child: VideoBackgroundManager.instance.widget),
              ),
            ],
          ),
        );
      }
      debugPrint(
        '[Background] fallback to default: file not found -> "${background.path}".',
      );
    }
    return const DefaultBackground();
  });
}

class DefaultBackground extends StatefulWidget {
  const DefaultBackground({super.key});

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

    _animation = Tween<double>(begin: 0, end: 2 * pi).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AudioStreamBuilder.visualizerColor((context, value) {
      Color startColor = stringToColor(AppState.instance.visualizerColor);
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
              colors: [startColor, endColor],
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

  ImageBackground imageBackground = ImageBackground(
    background: BackgroundData(path: ""),
    imageFile: null,
  );

  ImageBackground get widget => imageBackground;

  void load(BackgroundData background) {
    final imageFile = FileImage(File(background.path));
    imageBackground = ImageBackground(
      background: background,
      imageFile: imageFile,
    );
  }
}

class ImageBackground extends StatelessWidget {
  const ImageBackground({
    super.key,
    required this.background,
    required this.imageFile,
  });
  final BackgroundData background;
  final FileImage? imageFile;

  @override
  Widget build(BuildContext context) {
    if (imageFile == null) {
      return const SizedBox(height: 0, width: 0);
    }
    // Decode at screen resolution instead of the image's native resolution to
    // cap memory: a high-res wallpaper would otherwise decode to tens of MB.
    // longestSide keeps it sharp under BoxFit.cover regardless of orientation.
    final media = MediaQuery.of(context);
    final decodeSize = (media.size.longestSide * media.devicePixelRatio)
        .round();
    return SizedBox.expand(
      child: Image(
        image: ResizeImage.resizeIfNeeded(decodeSize, null, imageFile!),
        gaplessPlayback: true,
        fit: BoxFit.cover,
      ),
    );
  }
}

class VideoBackgroundManager {
  VideoBackgroundManager._();
  static final VideoBackgroundManager _instance = VideoBackgroundManager._();
  static VideoBackgroundManager get instance => _instance;

  final Player _player = Player();
  late final VideoController _controller = VideoController(_player);
  String _path = "";
  Future<void>? _opening;

  VideoController get controller => _controller;
  Widget get widget => const MediaKitVideoBackground();

  void load(String path) {
    if (_path == path) {
      return;
    }
    _path = path;
    _opening = _open(path);
  }

  Future<void> play() async {
    await _opening;
    await _player.play();
  }

  Future<void> dispose() => _player.dispose();

  Future<void> _open(String path) async {
    if (path.isEmpty) {
      return;
    }
    await _player.setPlaylistMode(PlaylistMode.single);
    await _player.setVolume(0);
    await _player.open(Media(Uri.file(path).toString()), play: true);
  }
}

class MediaKitVideoBackground extends StatefulWidget {
  const MediaKitVideoBackground({super.key});

  @override
  State<MediaKitVideoBackground> createState() =>
      _MediaKitVideoBackgroundState();
}

class _MediaKitVideoBackgroundState extends State<MediaKitVideoBackground>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(VideoBackgroundManager.instance.play());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Video(
        controller: VideoBackgroundManager.instance.controller,
        controls: (state) => const SizedBox.shrink(),
        fit: BoxFit.cover,
      ),
    );
  }
}

class FileBackground extends StatelessWidget {
  const FileBackground({
    super.key,
    required this.child,
    required this.background,
  });
  final Widget child;
  final BackgroundData background;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey<String>(background.path),
    child: Stack(
      children: [
        child,
        Opacity(
          opacity: (100 - background.brightness).clamp(0, 100) / 100,
          child: Container(color: ColorPalette.black),
        ),
      ],
    ),
  );
}
