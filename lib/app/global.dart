import './app_initializer.dart';
import './app_state.dart';

bool get isFullScreen => AppState.instance.isFullScreen;
String get currentVisualizerColor => AppState.instance.visualizerColor;
double get playListSavedScrollPosition =>
    AppState.instance.playListSavedScrollPosition;

set playListSavedScrollPosition(double value) {
  AppState.instance.playListSavedScrollPosition = value;
}

Future<void> initApp({bool loadPreference = true}) async {
  await AppInitializer.initialize(loadPreference: loadPreference);
}

void setVisualizerColor() {
  AppState.instance.updateVisualizerColor();
}
