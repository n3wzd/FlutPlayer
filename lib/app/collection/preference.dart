import 'package:shared_preferences/shared_preferences.dart';

import './audio_playlist.dart';

class Preference {
  static late final SharedPreferences prefs;

  static void init() async {
    prefs = await SharedPreferences.getInstance();
    load();
  }

  static void save() async {
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
  static int mashupTransitionTime = 5000;
  static int mashupNextTriggerMinTime = 20000;
  static int mashupNextTriggerMaxTime = 40000;

  static int mashupTransitionTimeMin = 1000;
  static int mashupTransitionTimeMax = 10000;
  static int mashupNextTriggerTimeRangeMin = 10000;
  static int mashupNextTriggerTimeRangeMax = 60000;

  // Equalizer
  static bool enableEqualizer = false;
  static bool smoothSliderEqualizer = true;

  // Other
  static bool instantlyPlay = true;
  static bool shuffleReload = true;
  static bool showPlayListDeleteButton = true;
}
