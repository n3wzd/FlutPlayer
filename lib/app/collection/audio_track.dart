import 'package:file_picker/file_picker.dart';

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
  final int? color;
  final int? id;
  final PlatformFile? file;
}

class VisualizerColor {
  VisualizerColor({required this.name, required this.value, this.id});
  final String name;
  final int value;
  final int? id;
}
