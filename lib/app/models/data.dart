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

/// A single background file (image/video) with the brightness inherited from
/// its group.
class BackgroundData {
  BackgroundData({
    required this.path,
    this.brightness = backgroundDefaultBrightness,
    this.ncsLogo,
    this.visualizer,
  });
  final String path;

  /// 0 = fully dark, 100 = original. Applied as a black overlay.
  final int brightness;

  /// Per-group overrides for the global setting. null = inherit default.
  final bool? ncsLogo;
  final bool? visualizer;
}

/// A labelled group of folders controlled by a single switch. One group maps to
/// one row in the background list UI and one entry in the JSON store.
class BackgroundGroupData {
  BackgroundGroupData({
    required this.label,
    this.active = true,
    this.brightness = backgroundDefaultBrightness,
    this.ncsLogo,
    this.visualizer,
    List<String>? folders,
  }) : folders = folders ?? [];

  /// Unique identifier shown on the switch row.
  String label;
  bool active;
  int brightness;

  /// Per-group overrides for the global setting. null = inherit default.
  bool? ncsLogo;
  bool? visualizer;
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
