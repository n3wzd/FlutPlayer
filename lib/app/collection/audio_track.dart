import 'package:file_picker/file_picker.dart';

class AudioTrack {
  AudioTrack({required this.title, required this.path, this.file});
  final String title;
  final String path;
  final PlatformFile? file;

  static empty() => AudioTrack(title: '', path: '');
}
