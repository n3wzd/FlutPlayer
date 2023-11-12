import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import './page/center.dart';
import './page/bottom.dart';
import './page/list_sheet.dart';
import './components/audio_player.dart';
import './components/audio_handler.dart';
import './components/dialog.dart';
import './style/colors.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  final _audioPlayerKit = AudioPlayerKit();

  @override
  void initState() {
    super.initState();
    _audioPlayerKit.init();
    createAudioSerivce(_audioPlayerKit);
  }

  @override
  void dispose() {
    _audioPlayerKit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                color: ColorTheme.black,
                child: Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CenterSection(
                        audioPlayerKit: _audioPlayerKit,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: BottomSection(
                        audioPlayerKit: _audioPlayerKit,
                      ),
                    ),
                  ],
                ),
              ),
              ListSheet(audioPlayerKit: _audioPlayerKit),
            ],
          ),
        ),
      ),
      onWillPop: () {
        DialogMaker.choiceDialog(
            context: context,
            onOkPressed: () {
              _audioPlayerKit.dispose();
              SystemNavigator.pop();
            },
            onCancelPressed: () {},
            text: 'Exit?');
        return Future<bool>.value(false);
      },
    );
  }
}
