import 'package:file_picker/file_picker.dart';

class AudioTrack {
  AudioTrack(
      {required this.title,
      required this.path,
      required this.modifiedDateTime,
      this.file});
  final String title;
  final String path;
  final DateTime modifiedDateTime;
  final PlatformFile? file;
}
