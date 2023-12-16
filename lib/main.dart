import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import './app/main_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();
    MediaKit.ensureInitialized();
    return const MaterialApp(
      home: MainPage(),
    );
  }
}
