import 'package:shared_preferences/shared_preferences.dart';
import '../models/enum.dart';

class Preference {
  Preference._();
  static final Preference _instance = Preference._();
  static Preference get instance => _instance;

  static late final SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    load();
  }

  static Future<void> save(String target) async {
    switch (target) {
      case 'volumeMasterRate':
        await prefs.setDouble(target, volumeMasterRate);
        break;

      case 'showPlayListOrderButton':
        await prefs.setBool(target, showPlayListOrderButton);
        break;
      case 'playListOrderMethod':
        await prefs.setString(target, playListOrderMethod.toString());
        break;

      case 'mashupTransitionTime':
        await prefs.setInt(target, mashupTransitionTime);
        break;
      case 'mashupNextTriggerMinTime':
        await prefs.setInt(target, mashupNextTriggerMinTime);
        break;
      case 'mashupNextTriggerMaxTime':
        await prefs.setInt(target, mashupNextTriggerMaxTime);
        break;

      case 'enableEqualizer':
        await prefs.setBool(target, enableEqualizer);
        break;
      case 'smoothSliderEqualizer':
        await prefs.setBool(target, smoothSliderEqualizer);
        break;

      case 'enableBackground':
        await prefs.setBool(target, enableBackground);
        break;
      case 'backgroundMethod':
        await prefs.setString(target, backgroundMethod.toString());
        break;
      case 'backgroundDirectoryPath':
        await prefs.setString(target, backgroundDirectoryPath);
        break;
      case 'rotateBackground':
        await prefs.setBool(target, rotateBackground);
        break;
      case 'scaleBackground':
        await prefs.setBool(target, scaleBackground);
        break;

      case 'enableVisualizer':
        await prefs.setBool(target, enableVisualizer);
        break;
      case 'enableNCSLogo':
        await prefs.setBool(target, enableNCSLogo);
        break;

      case 'instantlyPlay':
        await prefs.setBool(target, instantlyPlay);
        break;
      case 'shuffleReload':
        await prefs.setBool(target, shuffleReload);
        break;
      case 'showPlayListDeleteButton':
        await prefs.setBool(target, showPlayListDeleteButton);
        break;
    }
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

    enableBackground = prefs.getBool('enableBackground') ?? enableBackground;
    backgroundMethod = BackgroundMethod.toEnum(
        prefs.getString('BackgroundMethod') ?? backgroundMethod.toString());
    backgroundDirectoryPath =
        prefs.getString('backgroundDirectoryPath') ?? backgroundDirectoryPath;
    rotateBackground = prefs.getBool('rotateBackground') ?? rotateBackground;
    scaleBackground = prefs.getBool('scaleBackground') ?? scaleBackground;

    enableEqualizer = prefs.getBool('enableVisualizer') ?? enableEqualizer;
    enableNCSLogo = prefs.getBool('enableNCSLogo') ?? enableNCSLogo;

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

  // Equalizer
  static bool enableEqualizer = false;
  static bool smoothSliderEqualizer = true;

  // Background
  static bool enableBackground = true;
  static BackgroundMethod backgroundMethod = BackgroundMethod.normal;
  static String backgroundDirectoryPath = '';
  static bool rotateBackground = false;
  static bool scaleBackground = false;

  // Visualizer
  static bool enableVisualizer = true;
  static bool enableNCSLogo = true;

  // Other
  static bool instantlyPlay = true;
  static bool shuffleReload = true;
  static bool showPlayListDeleteButton = true;
}

class PreferenceConstant {
  static int mashupTransitionTimeMin = 1;
  static int mashupTransitionTimeMax = 10;
  static int mashupNextTriggerTimeRangeMin = 10;
  static int mashupNextTriggerTimeRangeMax = 60;
}
