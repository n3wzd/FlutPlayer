import './audio_playlist.dart';

class Preference {
  // Volume
  static double volumeMasterRate = 1.0;

  // Sort
  static bool showPlayListOrderButton = true;
  static PlayListOrderMethod playListOrderMethod = PlayListOrderMethod.title;

  // Mashup
  static int mashupTransitionTime = 5000;
  static int mashupNextTriggerMinTime = 20000;
  static int mashupNextTriggerMaxTime = 40000;

  static int mashupTransitionTimeMin = 1000;
  static int mashupTransitionTimeMax = 10000;
  static int mashupNextTriggerTimeRangeMin = 10000;
  static int mashupNextTriggerTimeRangeMax = 60000;

  // Other
  static bool instantlyPlay = true;
  static bool shuffleReload = true;
  static bool showPlayListDeleteButton = true;
}
