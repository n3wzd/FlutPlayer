import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import './page/center.dart';
import './page/bottom.dart';
import './page/list_sheet.dart';

import './components/audio_player_kit.dart';
import './components/dialog.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  final audioPlayerKit = AudioPlayerKit();

  List<String> list = [];

  @override
  void initState() {
    super.initState();
    audioPlayerKit.init();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    audioPlayerKit.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.paused:
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.abc),
              onPressed: () {
                DialogMaker.alertDialog(
                    context: context, onPressed: () {}, text: list.toString());
              },
            ),
            title: IconButton(
              icon: const Icon(Icons.abc),
              onPressed: () async {
                Directory dir = await getApplicationDocumentsDirectory();
                File file = File('${dir.path}/nahida.txt');

                list = await audioPlayerKit.directoryOpen();
                for (var line in list) {
                  await file.writeAsString("${line.toString()}\n",
                      mode: FileMode.writeOnlyAppend);
                }
                file.create();
              },
            )),
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                color: Colors.black,
                child: Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CenterSection(
                        audioPlayerKit: audioPlayerKit,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: BottomSection(
                        audioPlayerKit: audioPlayerKit,
                      ),
                    ),
                  ],
                ),
              ),
              ListSheet(audioPlayerKit: audioPlayerKit),
            ],
          ),
        ),
      ),
      onWillPop: () {
        DialogMaker.choiceDialog(
            context: context,
            onOkPressed: () {
              audioPlayerKit.dispose();
              SystemNavigator.pop();
            },
            onCancelPressed: () {},
            text: 'Exit?');
        return Future<bool>.value(false);
      },
    );
  }
}