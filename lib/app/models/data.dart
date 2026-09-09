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

const int backgroundDefaultBrightness = 100;

class BackgroundData {
  BackgroundData({
    required this.path,
    this.brightness = backgroundDefaultBrightness,
    this.ncsLogo,
    this.visualizer,
  });
  final String path;

  final int brightness;

  final bool? ncsLogo;
  final bool? visualizer;
}

class BackgroundGroupData {
  BackgroundGroupData({
    required this.label,
    this.active = true,
    this.brightness = backgroundDefaultBrightness,
    this.ncsLogo,
    this.visualizer,
    this.managed = false,
    List<String>? folders,
  }) : folders = folders ?? [];

  String label;
  bool active;
  int brightness;

  bool? ncsLogo;
  bool? visualizer;
  bool managed;
  List<String> folders;
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
