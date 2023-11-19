import 'package:file_picker/file_picker.dart';

class AudioTrack {
  AudioTrack(
      {required this.title,
      required this.path,
      required this.changedDateTime,
      this.file});
  final String title;
  final String path;
  final DateTime changedDateTime;
  final PlatformFile? file;
}
