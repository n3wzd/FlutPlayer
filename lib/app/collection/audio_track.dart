import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AudioTrack {
  AudioTrack(
      {required this.title,
      required this.path,
      required this.modifiedDateTime,
      this.color,
      this.id,
      this.file});
  final String title;
  final String path;
  final DateTime modifiedDateTime;
  final int? id;
  final PlatformFile? file;
  int? color;
}

class VisualizerColor {
  VisualizerColor({required this.name, required this.value, this.id});
  final String name;
  final int value;
  final int? id;
}

List<VisualizerColor> defaultVisualizerColors = [
  VisualizerColor(name: "red", value: Colors.red.value),
  VisualizerColor(name: "orange", value: Colors.orange.value),
  VisualizerColor(name: "yellow", value: Colors.yellow.value),
  VisualizerColor(name: "green", value: Colors.green.value),
  VisualizerColor(name: "cyan", value: Colors.cyan.value),
  VisualizerColor(name: "blue", value: Colors.blue.value),
  VisualizerColor(name: "purple", value: Colors.purple.value),
  VisualizerColor(name: "pink", value: Colors.pink.value),
  VisualizerColor(name: "teal", value: Colors.teal.value),
  VisualizerColor(name: "grey", value: Colors.grey.value),
  VisualizerColor(name: "white", value: Colors.white.value),
  VisualizerColor(name: "black", value: Colors.black.value),
];
