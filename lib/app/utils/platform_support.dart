import 'dart:io' show Platform;

abstract final class PlatformSupport {
  static bool get isWindows => Platform.isWindows;
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;
}
