import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import './app/main_page.dart';
import './app/utils/platform_support.dart';
import './app/utils/preference.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Preference.init();
  if (PlatformSupport.isWindows) {
    MediaKit.ensureInitialized();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MainPage());
  }
}
