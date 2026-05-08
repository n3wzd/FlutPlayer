import 'package:shared_preferences/shared_preferences.dart';
import '../models/enum.dart';

class Preference {
  Preference._();
  static final Preference _instance = Preference._();
  static Preference get instance => _instance;

  static SharedPreferences? _prefs;
  static bool get initialized => _prefs != null;

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
      case PreferenceKey.volumeMasterRate:
        await prefs.setDouble(target, volumeMasterRate);
        break;

      case PreferenceKey.showPlayListOrderButton:
        await prefs.setBool(target, showPlayListOrderButton);
        break;
      case PreferenceKey.playListOrderMethod:
        await prefs.setString(target, playListOrderMethod.toString());
        break;

      case PreferenceKey.mashupTransitionTime:
        await prefs.setInt(target, mashupTransitionTime);
        break;
      case PreferenceKey.mashupNextTriggerMinTime:
        await prefs.setInt(target, mashupNextTriggerMinTime);
        break;
      case PreferenceKey.mashupNextTriggerMaxTime:
        await prefs.setInt(target, mashupNextTriggerMaxTime);
        break;

      case PreferenceKey.enableEqualizer:
        await prefs.setBool(target, enableEqualizer);
        break;
      case PreferenceKey.smoothSliderEqualizer:
        await prefs.setBool(target, smoothSliderEqualizer);
        break;
      case PreferenceKey.equalizerGains:
        await prefs.setStringList(
          target,
          equalizerGains.map((gain) => gain.toString()).toList(),
        );
        break;

      case PreferenceKey.enableBackground:
        await prefs.setBool(target, enableBackground);
        break;

      case PreferenceKey.enableVisualizer:
        await prefs.setBool(target, enableVisualizer);
        break;
      case PreferenceKey.randomColorVisualizer:
        await prefs.setBool(target, randomColorVisualizer);
        break;
      case PreferenceKey.enableNCSLogo:
        await prefs.setBool(target, enableNCSLogo);
        break;

      case PreferenceKey.instantlyPlay:
        await prefs.setBool(target, instantlyPlay);
        break;
      case PreferenceKey.shuffleReload:
        await prefs.setBool(target, shuffleReload);
        break;
      case PreferenceKey.showPlayListDeleteButton:
        await prefs.setBool(target, showPlayListDeleteButton);
        break;

      case PreferenceKey.tagRootPath:
        await prefs.setString(target, tagRootPath);
        break;
      case PreferenceKey.resourceRootPath:
        await prefs.setString(target, resourceRootPath);
        break;
    }
  }

  static void load() {
    volumeMasterRate =
        prefs.getDouble(PreferenceKey.volumeMasterRate) ?? volumeMasterRate;

    showPlayListOrderButton =
        prefs.getBool(PreferenceKey.showPlayListOrderButton) ??
        showPlayListOrderButton;
    playListOrderMethod = PlayListOrderMethod.toEnum(
      prefs.getString(PreferenceKey.playListOrderMethod) ??
          playListOrderMethod.toString(),
    );

    mashupTransitionTime =
        prefs.getInt(PreferenceKey.mashupTransitionTime) ??
        mashupTransitionTime;
    mashupNextTriggerMinTime =
        prefs.getInt(PreferenceKey.mashupNextTriggerMinTime) ??
        mashupNextTriggerMinTime;
    mashupNextTriggerMaxTime =
        prefs.getInt(PreferenceKey.mashupNextTriggerMaxTime) ??
        mashupNextTriggerMaxTime;

    enableEqualizer =
        prefs.getBool(PreferenceKey.enableEqualizer) ?? enableEqualizer;
    smoothSliderEqualizer =
        prefs.getBool(PreferenceKey.smoothSliderEqualizer) ??
        smoothSliderEqualizer;
    final savedEqualizerGains = prefs.getStringList(
      PreferenceKey.equalizerGains,
    );
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

    enableBackground =
        prefs.getBool(PreferenceKey.enableBackground) ?? enableBackground;

    enableVisualizer =
        prefs.getBool(PreferenceKey.enableVisualizer) ?? enableVisualizer;
    randomColorVisualizer =
        prefs.getBool(PreferenceKey.randomColorVisualizer) ??
        randomColorVisualizer;
    enableNCSLogo = prefs.getBool(PreferenceKey.enableNCSLogo) ?? enableNCSLogo;

    instantlyPlay = prefs.getBool(PreferenceKey.instantlyPlay) ?? instantlyPlay;
    shuffleReload = prefs.getBool(PreferenceKey.shuffleReload) ?? shuffleReload;
    showPlayListDeleteButton =
        prefs.getBool(PreferenceKey.showPlayListDeleteButton) ??
        showPlayListDeleteButton;

    tagRootPath = prefs.getString(PreferenceKey.tagRootPath) ?? tagRootPath;
    resourceRootPath =
        prefs.getString(PreferenceKey.resourceRootPath) ?? resourceRootPath;
  }

  // Volume
  static double volumeMasterRate = 1.0;

  // Sort
  static bool showPlayListOrderButton = true;
  static PlayListOrderMethod playListOrderMethod =
      PlayListOrderMethod.modifiedDateTime;

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

class PreferenceKey {
  static const volumeMasterRate = 'volumeMasterRate';
  static const showPlayListOrderButton = 'showPlayListOrderButton';
  static const playListOrderMethod = 'playListOrderMethod';
  static const mashupTransitionTime = 'mashupTransitionTime';
  static const mashupNextTriggerMinTime = 'mashupNextTriggerMinTime';
  static const mashupNextTriggerMaxTime = 'mashupNextTriggerMaxTime';
  static const enableEqualizer = 'enableEqualizer';
  static const smoothSliderEqualizer = 'smoothSliderEqualizer';
  static const equalizerGains = 'equalizerGains';
  static const enableBackground = 'enableBackground';
  static const enableVisualizer = 'enableVisualizer';
  static const randomColorVisualizer = 'randomColorVisualizer';
  static const enableNCSLogo = 'enableNCSLogo';
  static const instantlyPlay = 'instantlyPlay';
  static const shuffleReload = 'shuffleReload';
  static const showPlayListDeleteButton = 'showPlayListDeleteButton';
  static const tagRootPath = 'tagRootPath';
  static const resourceRootPath = 'resourceRootPath';
}

class PreferenceConstant {
  static int mashupTransitionTimeMin = 1;
  static int mashupTransitionTimeMax = 9;
  static int mashupNextTriggerTimeRangeMin = 10;
  static int mashupNextTriggerTimeRangeMax = 60;
}
