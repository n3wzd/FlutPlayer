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
  VisualizerColor(name: "red", value: const Color(0xFFFF0000).value),
  VisualizerColor(name: "orange", value: const Color(0xFFFF6F2C).value),
  VisualizerColor(name: "yellow", value: const Color(0xFFFFFF00).value),
  VisualizerColor(name: "mint", value: const Color(0xFF22FF98).value),
  VisualizerColor(name: "green", value: const Color(0xFF09FF0B).value),
  VisualizerColor(name: "cyan", value: const Color(0xFF00FFFF).value),
  VisualizerColor(name: "blue", value: const Color(0xFF1865F9).value),
  VisualizerColor(name: "purple", value: const Color(0xFF8B46FF).value),
  VisualizerColor(name: "lavender", value: const Color(0xFF9570FF).value),
  VisualizerColor(name: "pink", value: const Color(0xFFFF08C2).value),
  VisualizerColor(name: "teal", value: const Color(0xFF488485).value),
  VisualizerColor(name: "brown", value: const Color(0xFF84002B).value),
  VisualizerColor(name: "ocher", value: const Color(0xFFD1720B).value),
  VisualizerColor(name: "white", value: Colors.white.value),
  VisualizerColor(name: "black", value: Colors.black.value),
];
