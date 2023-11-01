import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';

import './track_meta.dart';
import './file_audio_source.dart';

class AudioPlayerKit {
  final _audioPlayer = AudioPlayer();
  final _audioPlayerSub = AudioPlayer();
  final List<IndexedAudioSource> _playList = [];
  final List<IndexedAudioSource> _playListBackup = [];
  int _currentIndex = 0;
  LoopMode _loopMode = LoopMode.off;
  bool _shuffleMode = false;
  bool _mashupMode = true;
  double _volumeMasterRate = 1.0;
  final int _mashupTransitionTime = 100;

  int get currentIndex => _currentIndex;
  LoopMode get loopMode => _loopMode;
  bool get shuffleMode => _shuffleMode;
  int get playListLength => _playList.length;
  String get currentAudioTitle => _playList[_currentIndex].tag.title;
  bool get isPlaying => _audioPlayer.playing;
  Duration? get duration => _audioPlayer.duration;

  void init() async {
    _audioPlayer.processingStateStream
        .where((state) => state == ProcessingState.completed)
        .listen((state) {
      nextEventWhenPlayerCompleted();
    });

    playListAddList([
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
    ]);
    await seekTrack(_currentIndex);
  }

  void dispose() {
    _audioPlayer.dispose();
    _audioPlayerSub.dispose();
  }

  void playListAddList(List<IndexedAudioSource> newList) async {
    _playList.addAll(newList);
    _playListBackup.addAll(newList);
  }

  void nextEventWhenPlayerCompleted() async {
    if (_mashupMode) {
      await seekToNext();
    } else {
      if (_loopMode == LoopMode.one) {
        await replay();
      } else {
        if (_currentIndex == _playList.length - 1 &&
            _loopMode == LoopMode.off) {
          await _audioPlayer.stop();
        } else {
          await seekToNext();
        }
      }
    }
  }

  Future<void> seekTrack(int index) async {
    if (index != _currentIndex) {
      if (_mashupMode) {
        Stream<double> volumeTransition = Stream.periodic(
            const Duration(milliseconds: 100),
            (x) => x * 1.0 / _mashupTransitionTime).take(_mashupTransitionTime);
        volumeTransition.listen((x) async {
          _audioPlayer.setVolume(x * _volumeMasterRate);
          _audioPlayerSub.setVolume((1.0 - x) * _volumeMasterRate);
        });
        await _audioPlayerSub.setAudioSource(_playList[_currentIndex],
            initialPosition: _audioPlayer.position);
      }
      index %= _playList.length;
      _currentIndex = index;
      await _audioPlayer.setAudioSource(_playList[_currentIndex]);
      await play();
    }
  }

  Future<void> seekPosition(Duration duration) async {
    await _audioPlayer.seek(duration);
    await play();
  }

  Future<void> seekToPrevious() async {
    await seekTrack(_currentIndex - 1);
  }

  Future<void> seekToNext() async {
    await seekTrack(_currentIndex + 1);
  }

  Future<void> play() async {
    await _audioPlayer.play();
    if (_mashupMode) {
      await _audioPlayerSub.play();
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    if (_mashupMode) {
      await _audioPlayerSub.pause();
    }
  }

  Future<void> replay() async {
    await seekPosition(const Duration());
    await pause();
    await play();
  }

  IndexedAudioSource playListAt(int index) {
    return _playList[index];
  }

  void shuffleOn() {
    IndexedAudioSource currentTrack = _playList[_currentIndex];
    _playList.shuffle();
    for (int i = 0; i < _playList.length; i++) {
      if (currentTrack == _playList[i]) {
        IndexedAudioSource tempTrack = _playList[0];
        _playList[0] = _playList[i];
        _playList[i] = tempTrack;
        break;
      }
    }
    _currentIndex = 0;
  }

  void shuffleOff() {
    IndexedAudioSource currentTrack = _playList[_currentIndex];
    for (int i = 0; i < _playList.length; i++) {
      _playList[i] = _playListBackup[i];
      if (currentTrack == _playList[i]) {
        _currentIndex = i;
      }
    }
  }

  void filesOpen() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg'],
    );

    if (result != null) {
      List<IndexedAudioSource> newList = [];
      for (PlatformFile track in result.files) {
        newList.add(
          FileAudioSource(
            bytes: track.bytes!.cast<int>(),
            tag: TrackMeta(
              title: track.name.substring(0, track.name.length - 4),
            ),
          ),
        );
      }
      playListAddList(newList);
    }
  }

  void toggleLoopMode() {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.all;
    } else if (_loopMode == LoopMode.all) {
      _loopMode = LoopMode.one;
    } else {
      _loopMode = LoopMode.off;
    }
  }

  void toggleShuffleMode() {
    if (_shuffleMode) {
      shuffleOff();
    } else {
      shuffleOn();
    }
    _shuffleMode = !_shuffleMode;
  }

  StreamBuilder<bool> playingStreamBuilder(builder) {
    return StreamBuilder<bool>(
      stream: _audioPlayer.playingStream,
      builder: builder,
    );
  }

  StreamBuilder<Duration> durationStreamBuilder(builder) {
    return StreamBuilder<Duration>(
      stream: _audioPlayer.positionStream,
      builder: builder,
    );
  }

  StreamBuilder<Duration> positionStreamBuilder(builder) {
    return StreamBuilder<Duration>(
      stream: _audioPlayer.positionStream,
      builder: builder,
    );
  }
}
