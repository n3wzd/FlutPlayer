import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:file_picker/file_picker.dart';

import './page1/center.dart';
import './page1/bottom.dart';
import './page1/list_sheet.dart';

class Page1 extends StatefulWidget {
  const Page1({super.key});

  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> {
  final assetsAudioPlayer = AssetsAudioPlayer.newPlayer();
  Playlist audioList = Playlist(audios: [
    Audio("assets/audios/Carola-BeatItUp.mp3",
        metas: Metas(title: 'Carola - Beat It Up')),
    Audio("assets/audios/Savoy-LetYouGo.mp3",
        metas: Metas(title: 'Savoy - Let You Go')),
    Audio("assets/audios/ColBreakz-10.000.mp3",
        metas: Metas(title: 'ColBreakz - 10.000')),
    Audio("assets/audios/RomeinSilver-Inferno.mp3",
        metas: Metas(title: 'Rome in Silver - Inferno')),
  ]);

  void filesOpen() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg'],
    );

    if (result != null) {
      List<Audio> newList = [];
      for (PlatformFile track in result.files) {
        newList.add(Audio(track.path!, metas: Metas(title: track.name)));
      }
      audioList.addAll(newList);
    }
  }

  void openPlayer() async {
    await assetsAudioPlayer.open(audioList);
  }

  @override
  void initState() {
    super.initState();
    openPlayer();
  }

  @override
  void dispose() {
    assetsAudioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              PlayerBuilder.current(
                player: assetsAudioPlayer,
                builder: (context, playing) => Container(
                  color: Colors.black,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 2,
                        child: CenterSection(
                          assetsAudioPlayer: assetsAudioPlayer,
                          filesOpen: filesOpen,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: BottomSection(
                          assetsAudioPlayer: assetsAudioPlayer,
                          playing: playing,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListSheet(assetsAudioPlayer: assetsAudioPlayer),
            ],
          ),
        ),
      ),
    );
  }
}
