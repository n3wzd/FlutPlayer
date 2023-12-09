import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  PermissionHandler._();
  static final PermissionHandler _instance = PermissionHandler._();
  static PermissionHandler get instance => _instance;

  late final PermissionStatus _permissionStatus;
  bool get isPermissionAccepted => _permissionStatus.isDenied ? false : true;

  void init() {
    activePermission();
  }

  void activePermission() async {
    _permissionStatus = await Permission.manageExternalStorage.request();
  }
}
