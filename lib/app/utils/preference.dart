import 'package:shared_preferences/shared_preferences.dart';
import '../models/enum.dart';

class Preference {
  Preference._();
  static final Preference _instance = Preference._();
  static Preference get instance => _instance;

  static SharedPreferences? _prefs;
  static SharedPreferences get prefs {
    final preferences = _prefs;
    if (preferences == null) {
      throw StateError('Preference.init() must be called before using prefs.');
    }
    return preferences;
  }

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
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
      case 'equalizerGains':
        await prefs.setStringList(
          target,
          equalizerGains.map((gain) => gain.toString()).toList(),
        );
        break;

      case 'enableBackground':
        await prefs.setBool(target, enableBackground);
        break;
      case 'backgroundMethod':
        await prefs.setString(target, backgroundMethod.toString());
        break;
      case 'enableBackgroundTransition':
        await prefs.setBool(target, enableBackgroundTransition);
        break;
      case 'backgroundNextTriggerMinTime':
        await prefs.setInt(target, backgroundNextTriggerMinTime);
        break;
      case 'backgroundNextTriggerMaxTime':
        await prefs.setInt(target, backgroundNextTriggerMaxTime);
        break;

      case 'enableVisualizer':
        await prefs.setBool(target, enableVisualizer);
        break;
      case 'randomColorVisualizer':
        await prefs.setBool(target, randomColorVisualizer);
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

      case 'tagRootPath':
        await prefs.setString(target, tagRootPath);
        break;
      case 'resourceRootPath':
        await prefs.setString(target, resourceRootPath);
        break;
    }
  }

  static void load() {
    volumeMasterRate = prefs.getDouble('volumeMasterRate') ?? volumeMasterRate;

    showPlayListOrderButton =
        prefs.getBool('showPlayListOrderButton') ?? showPlayListOrderButton;
    playListOrderMethod = PlayListOrderMethod.toEnum(
      prefs.getString('playListOrderMethod') ?? playListOrderMethod.toString(),
    );

    mashupTransitionTime =
        prefs.getInt('mashupTransitionTime') ?? mashupTransitionTime;
    mashupNextTriggerMinTime =
        prefs.getInt('mashupNextTriggerMinTime') ?? mashupNextTriggerMinTime;
    mashupNextTriggerMaxTime =
        prefs.getInt('mashupNextTriggerMaxTime') ?? mashupNextTriggerMaxTime;

    enableEqualizer = prefs.getBool('enableEqualizer') ?? enableEqualizer;
    smoothSliderEqualizer =
        prefs.getBool('smoothSliderEqualizer') ?? smoothSliderEqualizer;
    final savedEqualizerGains = prefs.getStringList('equalizerGains');
    if (savedEqualizerGains != null &&
        savedEqualizerGains.length == equalizerGains.length) {
      equalizerGains = savedEqualizerGains
          .map(
            (gain) => (double.tryParse(gain) ?? equalizerDefaultGain)
                .clamp(equalizerMinGain, equalizerMaxGain)
                .toDouble(),
          )
          .toList();
    }

    enableBackground = prefs.getBool('enableBackground') ?? enableBackground;
    backgroundMethod = BackgroundMethod.toEnum(
      prefs.getString('backgroundMethod') ?? backgroundMethod.toString(),
    );
    enableBackgroundTransition =
        prefs.getBool('enableBackgroundTransition') ??
        enableBackgroundTransition;
    backgroundNextTriggerMinTime =
        prefs.getInt('backgroundNextTriggerMinTime') ??
        backgroundNextTriggerMinTime;
    backgroundNextTriggerMaxTime =
        prefs.getInt('backgroundNextTriggerMaxTime') ??
        backgroundNextTriggerMaxTime;

    enableVisualizer = prefs.getBool('enableVisualizer') ?? enableVisualizer;
    randomColorVisualizer =
        prefs.getBool('randomColorVisualizer') ?? randomColorVisualizer;
    enableNCSLogo = prefs.getBool('enableNCSLogo') ?? enableNCSLogo;

    instantlyPlay = prefs.getBool('instantlyPlay') ?? instantlyPlay;
    shuffleReload = prefs.getBool('shuffleReload') ?? shuffleReload;
    showPlayListDeleteButton =
        prefs.getBool('showPlayListDeleteButton') ?? showPlayListDeleteButton;

    tagRootPath = prefs.getString('tagRootPath') ?? tagRootPath;
    resourceRootPath = prefs.getString('resourceRootPath') ?? resourceRootPath;
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
  static const int equalizerBandsLength = 10;
  static const double equalizerMinGain = 0.0;
  static const double equalizerMaxGain = 4.0;
  static const double equalizerDefaultGain = 1.0;
  static bool enableEqualizer = false;
  static bool smoothSliderEqualizer = true;
  static List<double> equalizerGains = List<double>.filled(
    equalizerBandsLength,
    equalizerDefaultGain,
  );

  // Background
  static bool enableBackground = true;
  static BackgroundMethod backgroundMethod = BackgroundMethod.specific;
  static bool enableBackgroundTransition = true;
  static int backgroundNextTriggerMinTime = 4;
  static int backgroundNextTriggerMaxTime = 6;

  // Visualizer
  static bool enableVisualizer = true;
  static bool randomColorVisualizer = true;
  static bool enableNCSLogo = true;

  // Other
  static bool instantlyPlay = true;
  static bool shuffleReload = true;
  static bool showPlayListDeleteButton = true;
  static String tagRootPath = '';
  static String resourceRootPath = '';
}

class PreferenceConstant {
  static int mashupTransitionTimeMin = 1;
  static int mashupTransitionTimeMax = 9;
  static int mashupNextTriggerTimeRangeMin = 10;
  static int mashupNextTriggerTimeRangeMax = 60;
  static int backgroundNextTriggerTimeRangeMin = 1;
  static int backgroundNextTriggerTimeRangeMax = 9;
}
