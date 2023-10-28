import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';

import './track_meta.dart';
import './file_audio_source.dart';

class AudioPlayerKit {
  final audioPlayer = AudioPlayer();
  final List<IndexedAudioSource> playList = [
    AudioSource.asset(
      'assets/audios/Carola-BeatItUp.mp3',
      tag: TrackMeta(
        title: 'Carola - Beat It Up',
      ),
    ),
    AudioSource.asset(
      'assets/audios/Savoy-LetYouGo.mp3',
      tag: TrackMeta(
        title: 'Savoy - Let You Go',
      ),
    ),
  ];
  int _currentIndex = 0;
  LoopMode loopMode = LoopMode.off;

  int get currentIndex => _currentIndex;
  String get currentAudioTitle => playList[_currentIndex].tag.title;
  bool get isPlaying => audioPlayer.playing;
  Duration get duration => audioPlayer.duration ?? const Duration();

  void init() {
    audioPlayer.processingStateStream
        .where((state) => state == ProcessingState.completed)
        .listen((state) {
      nextEventWhenPlayerCompleted();
    });
    seekTrack(_currentIndex);
  }

  void dispose() {
    audioPlayer.dispose();
  }

  void nextEventWhenPlayerCompleted() {
    if (loopMode == LoopMode.one) {
      seekPosition(const Duration());
    } else {
      if (_currentIndex == playList.length - 1 && loopMode == LoopMode.off) {
        audioPlayer.stop();
      } else {
        seekToNext();
      }
    }
  }

  Future<void> seekTrack(int index) async {
    index %= playList.length;
    _currentIndex = index;
    await audioPlayer.setAudioSource(playList[_currentIndex]);
  }

  Future<void> seekPosition(Duration duration) async {
    await audioPlayer.seek(duration);
  }

  Future<void> seekToPrevious() async {
    await seekTrack(_currentIndex - 1);
  }

  Future<void> seekToNext() async {
    await seekTrack(_currentIndex + 1);
  }

  Future<void> play() async {
    await audioPlayer.play();
  }

  Future<void> pause() async {
    await audioPlayer.pause();
  }

  void filesOpen() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg'],
    );

    if (result != null) {
      for (PlatformFile track in result.files) {
        playList.add(
          FileAudioSource(
            bytes: track.bytes!.cast<int>(),
            tag: TrackMeta(
              title: track.name,
            ),
          ),
        );
      }
    }
  }

  void toggleLoopMode() {
    if (loopMode == LoopMode.off) {
      loopMode = LoopMode.all;
    } else if (loopMode == LoopMode.all) {
      loopMode = LoopMode.one;
    } else {
      loopMode = LoopMode.off;
    }
  }

  StreamBuilder<bool> playingStreamBuilder(builder) {
    return StreamBuilder<bool>(
      stream: audioPlayer.playingStream,
      builder: builder,
    );
  }

  StreamBuilder<LoopMode> loopModeStreamBuilder(builder) {
    return StreamBuilder<LoopMode>(
      stream: audioPlayer.loopModeStream,
      builder: builder,
    );
  }

  StreamBuilder<Duration> durationStreamBuilder(builder) {
    return StreamBuilder<Duration>(
      stream: audioPlayer.positionStream,
      builder: builder,
    );
  }

  StreamBuilder<ProcessingState> processingStateStreamBuilder(builder) {
    return StreamBuilder<ProcessingState>(
      stream: audioPlayer.processingStateStream,
      builder: builder,
    );
  }
}
