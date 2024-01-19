class AudioTrack {
  AudioTrack(
      {required this.title,
      required this.path,
      required this.modifiedDateTime,
      this.color,
      this.background});
  final String title;
  final String path;
  final String modifiedDateTime;
  String? color;
  BackgroundData? background;
}

class BackgroundData {
  BackgroundData(
      {required this.path,
      this.rotate = false,
      this.scale = false,
      this.color = false,
      this.value = 75});
  final String path;
  bool rotate;
  bool scale;
  bool color;
  int value;
}

String dateTimeToString(DateTime data) => data.toString().substring(0, 19);
DateTime stringToDateTime(String data) => DateTime.parse(data);
