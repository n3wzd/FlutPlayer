import 'dart:async';

import './utils/audio_manager.dart';
import './utils/database_manager.dart';
import './utils/audio_handler.dart';
import './utils/preference.dart';
import './utils/permission_handler.dart';

String debugLog = '';
final debugLogStreamController = StreamController<void>.broadcast();

void initApp() async {
  await Preference.init();
  if (!isWeb) {
    DatabaseManager.instance.init();
  }
  if (isAndroid) {
    PermissionHandler.instance.init();
  }
  AudioManager.instance.init();
  if (isAndroid) {
    createAudioSerivce();
  }
}

/*bool get isAndroid => Platform.isAndroid;
bool get isWindows => Platform.isWindows;
bool get isWeb => !isAndroid && !isWindows;*/
bool get isAndroid => false;
bool get isWindows => true;
bool get isWeb => false;

bool isFullScreen = false;
