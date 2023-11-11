import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';

import './page/center.dart';
import './page/bottom.dart';
import './page/list_sheet.dart';
import './components/audio_player_kit.dart';
import './components/audio_service.dart';
import './components/dialog.dart';
import './style/colors.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  final audioPlayerKit = AudioPlayerKit();

  @override
  void initState() {
    super.initState();
    audioPlayerKit.init();
    createAudioSerivce();
  }

  @override
  void dispose() {
    audioPlayerKit.dispose();
    super.dispose();
  }

  void createAudioSerivce() async {
    CustomAudioHandler _audioHandler = await AudioService.init(
      builder: () => CustomAudioHandler(audioPlayerKit: audioPlayerKit),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'FlutBeat.myapp.channel.audio',
        androidNotificationChannelName: 'Music playback',
      ),
    );
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
