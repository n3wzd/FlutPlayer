import 'package:flutter/material.dart';
import 'dart:math';

import '../utils/audio_player.dart';
import '../models/color.dart';

class VisualizerController extends StatefulWidget {
  const VisualizerController(
      {Key? key, required this.widgetWidth, required this.widgetHeight})
      : super(key: key);
  final double widgetWidth;
  final double widgetHeight;

  @override
  State<VisualizerController> createState() => _VisualizerControllerState();
}

class _VisualizerControllerState extends State<VisualizerController>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: Duration(milliseconds: sampleLength))
    ..forward();
  late double maxSize;
  late double minSize;
  final double maxSampleDepth = 32768;
  final int sampleLength = 100;
  late Animation<double> _animation;
  late double _currentSize = minSize;
  late double _previousSize = minSize;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        List<int> bytes = AudioPlayerKit.instance.currentByteData;
        double sample = 0;
        if (bytes.isNotEmpty) {
          sample = extractRMS(bytes);
        }
        _previousSize = _currentSize;
        _currentSize =
            (1 - sample / maxSampleDepth) * (maxSize - minSize) + minSize;
        setState(() {});

        _controller.reset();
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double extractRMS(List<int> bytes) {
    double sample = 0;
    int position = AudioPlayerKit.instance.position.inMilliseconds;
    int duration = AudioPlayerKit.instance.duration.inMilliseconds;
    if (position > duration) {
      position = duration;
    }
    for (int p = position; p > position - sampleLength && p >= 0; p--) {
      sample += pow(
          extractSample(
              bytes, ((position / duration) * (bytes.length - 1)).toInt()),
          2);
    }
    return sqrt(sample / sampleLength);
  }

  int extractSample(List<int> bytes, int idx) {
    idx = idx ~/ 2 * 2;
    int sample = bytes[idx];
    if (idx < bytes.length - 1) {
      sample += (bytes[idx + 1] << 8); // little endian
    }
    if (sample & 0x8000 != 0) {
      sample = (~sample & 0xFFFF) + 1;
    }
    return sample;
  }

  void setAnimation() {
    _animation = Tween<double>(
      begin: _previousSize / minSize,
      end: _currentSize / minSize,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));
  }

  void updateVisualizerSize() {
    maxSize = min(widget.widgetWidth, widget.widgetHeight) * 0.75;
    minSize = maxSize * 0.88;
  }

  Color getColor() {
    int? color = AudioPlayerKit.instance.currentAudioColor;
    if (color != null) {
      if (color != 0) {
        return Color(color);
      }
    }
    return ColorPalette.white;
  }

  @override
  Widget build(BuildContext context) {
    updateVisualizerSize();
    setAnimation();

    return ScaleTransition(
      scale: _animation,
      child: CircleVisualizer(size: _currentSize, color: getColor()),
    );
  }
}

class CircleVisualizer extends StatelessWidget {
  const CircleVisualizer({Key? key, required this.size, required this.color})
      : super(key: key);
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size, // Adjust the size as needed
        height: size, // Adjust the size as needed
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: 5.0,
          ),
        ),
      );
}