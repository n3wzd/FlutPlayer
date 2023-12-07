import 'package:shared_preferences/shared_preferences.dart';

import './audio_playlist.dart';

class Preference {
  static late final SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    load();
  }

  static Future<void> save() async {
    await prefs.setDouble('volumeMasterRate', volumeMasterRate);

    await prefs.setBool('showPlayListOrderButton', showPlayListOrderButton);
    await prefs.setString(
        'playListOrderMethod', playListOrderMethod.toString());

    await prefs.setInt('mashupTransitionTime', mashupTransitionTime);
    await prefs.setInt('mashupNextTriggerMinTime', mashupNextTriggerMinTime);
    await prefs.setInt('mashupNextTriggerMaxTime', mashupNextTriggerMaxTime);

    await prefs.setBool('enableEqualizer', enableEqualizer);
    await prefs.setBool('smoothSliderEqualizer', smoothSliderEqualizer);

    await prefs.setBool('instantlyPlay', instantlyPlay);
    await prefs.setBool('shuffleReload', shuffleReload);
    await prefs.setBool('showPlayListDeleteButton', showPlayListDeleteButton);
  }

  static void load() {
    volumeMasterRate = prefs.getDouble('volumeMasterRate') ?? volumeMasterRate;

    showPlayListOrderButton =
        prefs.getBool('showPlayListOrderButton') ?? showPlayListOrderButton;
    playListOrderMethod = PlayListOrderMethod.toEnum(
        prefs.getString('playListOrderMethod') ??
            playListOrderMethod.toString());

    mashupTransitionTime =
        prefs.getInt('mashupTransitionTime') ?? mashupTransitionTime;
    mashupNextTriggerMinTime =
        prefs.getInt('mashupNextTriggerMinTime') ?? mashupNextTriggerMinTime;
    mashupNextTriggerMaxTime =
        prefs.getInt('mashupNextTriggerMaxTime') ?? mashupNextTriggerMaxTime;

    enableEqualizer = prefs.getBool('enableEqualizer') ?? enableEqualizer;
    smoothSliderEqualizer =
        prefs.getBool('smoothSliderEqualizer') ?? smoothSliderEqualizer;

    instantlyPlay = prefs.getBool('instantlyPlay') ?? instantlyPlay;
    shuffleReload = prefs.getBool('shuffleReload') ?? shuffleReload;
    showPlayListDeleteButton =
        prefs.getBool('showPlayListDeleteButton') ?? showPlayListDeleteButton;
  }

  // Volume
  static double volumeMasterRate = 1.0;

  // Sort
  static bool showPlayListOrderButton = true;
  static PlayListOrderMethod playListOrderMethod = PlayListOrderMethod.title;

  // Mashup
  static int mashupTransitionTime = 5;
  static int mashupNextTriggerMinTime = 20;
  static int mashupNextTriggerMaxTime = 40;

  static int mashupTransitionTimeMin = 1;
  static int mashupTransitionTimeMax = 10;
  static int mashupNextTriggerTimeRangeMin = 10;
  static int mashupNextTriggerTimeRangeMax = 60;

  // Equalizer
  static bool enableEqualizer = true;
  static bool smoothSliderEqualizer = true;

  // Visualizer
  static bool enableVisualizer = true;
  static bool enableBackground = true;
  static bool enableNCSLogo = true;
  static bool enableFullScreen = false;

  // Other
  static bool instantlyPlay = true;
  static bool shuffleReload = true;
  static bool showPlayListDeleteButton = true;
}
