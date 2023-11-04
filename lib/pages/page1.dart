import 'package:flutter/material.dart';

import './page1/center.dart';
import './page1/bottom.dart';
import './page1/list_sheet.dart';

import './components/audio_player_kit.dart';
import './components/text.dart';
import './components/button.dart';
import './style/colors.dart';

class Page1 extends StatefulWidget {
  const Page1({super.key});

  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> with WidgetsBindingObserver {
  final audioPlayerKit = AudioPlayerKit();

  @override
  void initState() {
    super.initState();
    audioPlayerKit.init();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    audioPlayerKit.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      audioPlayerKit.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WillPopScope(
        child: Scaffold(
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
          bool willPop = false;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: ColorTheme.darkGrey,
              content: TextMaker.defaultText("Exit?", fontSize: 20),
              actions: <Widget>[
                ButtonMaker.defaultButton(
                  onPressed: () {
                    willPop = true;
                    Navigator.of(context).pop();
                  },
                  text: 'ok',
                ),
                ButtonMaker.defaultButton(
                  onPressed: () {
                    willPop = false;
                    Navigator.of(context).pop();
                  },
                  text: 'cancel',
                ),
              ],
            ),
          );
          return Future<bool>.value(willPop);
        },
      ),
    );
  }
}
