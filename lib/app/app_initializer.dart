import 'package:flutter/foundation.dart';

import './app_state.dart';
import './utils/audio_handler.dart';
import './utils/audio_manager.dart';
import './utils/background_manager.dart';
import './utils/database_manager.dart';
import './utils/permission_handler.dart';
import './utils/platform_support.dart';
import './utils/preference.dart';

class AppInitializer {
  AppInitializer._();

  static Future<void>? _initializing;
  static bool _initialized = false;
  static bool _preferenceLoaded = false;

  static bool get initialized => _initialized;
  static bool get preferenceLoaded => _preferenceLoaded;

  static Future<void> initialize({
    bool loadPreference = true,
    VoidCallback? onPreferenceLoaded,
  }) {
    if (_initialized) {
      onPreferenceLoaded?.call();
      return Future.value();
    }

    final initializing = _initializing ??= _initialize(
      loadPreference: loadPreference,
      onPreferenceLoaded: onPreferenceLoaded,
    );
    return initializing.whenComplete(() {
      if (_initialized) {
        return;
      }
      _initializing = null;
    });
  }

  static Future<void> _initialize({
    required bool loadPreference,
    VoidCallback? onPreferenceLoaded,
  }) async {
    if (loadPreference && !_preferenceLoaded) {
      await Preference.init();
      _preferenceLoaded = true;
      onPreferenceLoaded?.call();
    } else if (_preferenceLoaded || !loadPreference) {
      onPreferenceLoaded?.call();
    }

    await DatabaseManager.instance.init();
    await PermissionHandler.instance.init();
    await AudioManager.instance.init();
    if (PlatformSupport.isMobile) {
      await createAudioSerivce();
    }
    await BackgroundManager.instance.init();
    BackgroundTransitionTimer.instance.init();
    AppState.instance.updateVisualizerColor();
    _initialized = true;
  }
}
