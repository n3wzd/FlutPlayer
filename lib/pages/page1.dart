import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';

import './page1/center.dart';
import './page1/bottom.dart';
import './page1/list_sheet.dart';
import './components/meta_track.dart';
import './components/file_audio_source.dart';

class Page1 extends StatefulWidget {
  const Page1({super.key});

  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> {
  final audioPlayer = AudioPlayer();
  List<AudioSource> sourceList = [
    AudioSource.asset(
      'assets/audios/Carola-BeatItUp.mp3',
      tag: MetaTrack(
        title: 'Carola - Beat It Up',
      ),
    ),
    AudioSource.asset(
      'assets/audios/Savoy-LetYouGo.mp3',
      tag: MetaTrack(
        title: 'Savoy - Let You Go',
      ),
    ),
  ];

  void filesOpen() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg'],
    );

    if (result != null) {
      List<FileAudioSource> trackList = [];
      for (PlatformFile track in result.files) {
        trackList.add(
          FileAudioSource(
            bytes: track.bytes!.cast<int>(),
            tag: MetaTrack(
              title: track.name,
            ),
          ),
        );
      }
      ConcatenatingAudioSource audioList =
          ConcatenatingAudioSource(children: audioPlayer.sequence!);
      audioList.addAll(trackList);
      await audioPlayer.setAudioSource(audioList);
    }
  }

  void openPlayer() async {
    ConcatenatingAudioSource audioList =
        ConcatenatingAudioSource(children: sourceList);
    await audioPlayer.setAudioSource(audioList);
  }

  @override
  void initState() {
    super.initState();
    openPlayer();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
                        audioPlayer: audioPlayer,
                        filesOpen: filesOpen,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: BottomSection(
                        audioPlayer: audioPlayer,
                      ),
                    ),
                  ],
                ),
              ),
              ListSheet(audioPlayer: audioPlayer),
            ],
          ),
        ),
      ),
    );
  }
}
