import 'package:permission_handler/permission_handler.dart';
import './platform_support.dart';

class PermissionHandler {
  PermissionHandler._();
  static final PermissionHandler _instance = PermissionHandler._();
  static PermissionHandler get instance => _instance;

  PermissionStatus _permissionStatus = PermissionStatus.granted;
  bool get isPermissionAccepted => _permissionStatus.isDenied ? false : true;

  Future<void> init() async {
    if (PlatformSupport.isAndroid) {
      await activePermission();
    }
  }

  Future<void> activePermission() async {
    _permissionStatus = await Permission.manageExternalStorage.request();
  }
}
