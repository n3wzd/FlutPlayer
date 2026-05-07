import 'package:file_picker/file_picker.dart';

class AudioTrack {
  AudioTrack({
    required this.title,
    required this.path,
    required this.modifiedDateTime,
    this.color,
    this.file,
  });
  final String title;
  final String path;
  final String modifiedDateTime;
  final PlatformFile? file;
  String? color;
}

class BackgroundData {
  BackgroundData({
    required this.path,
    this.rotate = false,
    this.scale = false,
    this.color = false,
    this.value = 75,
  });
  final String path;
  bool rotate;
  bool scale;
  bool color;
  int value;
}

String dateTimeToString(DateTime data) => data.toString().substring(0, 19);
DateTime stringToDateTime(String data) => DateTime.parse(data);

class CustomMixData {
  CustomMixData({
    required this.track,
    required this.start,
    required this.duration,
    required this.buildUpTime,
  });
  final AudioTrack track;
  final int start;
  final int duration;
  final int buildUpTime;
}

int stringTimeToInt(String time) {
  List<String> timeParts = time.split(':');
  int hours = int.parse(timeParts[0]);
  int minutes = int.parse(timeParts[1]);
  return hours * 60 + minutes;
}
