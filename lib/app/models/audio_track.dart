import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';

class AudioTrack {
  AudioTrack(
      {required this.title,
      required this.path,
      required this.modifiedDateTime,
      this.color,
      this.background,
      this.file});
  final String title;
  final String path;
  final String modifiedDateTime;
  final PlatformFile? file;
  String? color;
  String? background;
}

class FileAudioSource extends StreamAudioSource {
  final List<int> bytes;
  FileAudioSource({required this.bytes});

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}

String dateTimeToString(DateTime data) => data.toString().substring(0, 19);
DateTime stringToDateTime(String data) => DateTime.parse(data);
