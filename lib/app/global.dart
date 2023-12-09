import 'dart:async';

import './utils/audio_player.dart';
import './utils/database_manager.dart';
import './utils/audio_handler.dart';
import './utils/preference.dart';
import './utils/permission_handler.dart';

String debugLog = '';
final debugLogStreamController = StreamController<void>.broadcast();

void initApp() async {
  await Preference.init();
  DatabaseManager.instance.init();
  PermissionHandler.instance.init();
  AudioPlayerKit.instance.init();
  createAudioSerivce();
}

bool isFullScreen = false;
