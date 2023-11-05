import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:math';
import 'dart:async';
import 'dart:io';

import './audio_track.dart';
import './file_audio_source.dart';

class AudioPlayerKit {
  final List<AudioPlayer> _audioPlayerList = [AudioPlayer(), AudioPlayer()];
  final List<AudioTrack> _playList = [];
  final List<AudioTrack> _playListBackup = [];
  int _currentIndex = 0;
  LoopMode _loopMode = LoopMode.one;
  bool _shuffleMode = false;
  bool _mashupMode = false;
  int _currentIndexAudioPlayerList = 0;
  final double _volumeMasterRate = 1.0;
  final int _mashupTransitionTime = 5000;
  final int _mashupNextTriggerMinTime = 20000;
  final int _mashupNextTriggerMaxTime = 40000;
  final List<String> _allowedExtensions = ['mp3', 'wav', 'ogg'];

  final StreamController<void> _trackStreamController =
      StreamController<void>.broadcast();
  final StreamController<void> _playListStreamController =
      StreamController<void>.broadcast();
  final StreamController<LoopMode> _loopModeStreamController =
      StreamController<LoopMode>.broadcast();
  final StreamController<bool> _shuffleModeStreamController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _mashupModeStreamController =
      StreamController<bool>.broadcast();
  StreamSubscription<double>? _mashupVolumeTransitionTimer;
  StreamSubscription<void>? _mashupNextTriggerTimer;

  bool androidMode = true; // true - android, false - web

  AudioPlayer get audioPlayer => _audioPlayerList[_currentIndexAudioPlayerList];
  AudioPlayer get audioPlayerSub =>
      _audioPlayerList[(_currentIndexAudioPlayerList + 1) % 2];
  int get currentIndex => _currentIndex;
  LoopMode get loopMode => _loopMode;
  bool get shuffleMode => _shuffleMode;
  bool get mashupMode => _mashupMode;
  int get playListLength => _playList.length;
  String get currentAudioTitle =>
      _playList.isNotEmpty ? _playList[_currentIndex].title : '';
  bool get isPlaying => audioPlayer.playing;
  Duration get duration => audioPlayer.duration ?? const Duration();
  bool get isAudioPlayerEmpty => audioPlayer.audioSource == null;

  void init() {
    audioPlayer.processingStateStream
        .where((state) => state == ProcessingState.completed)
        .listen((state) {
      nextEventWhenPlayerCompleted();
    });
    audioPlayerSub.processingStateStream
        .where((state) => state == ProcessingState.completed)
        .listen((state) {
      nextEventWhenPlayerCompleted();
    });

    audioPlayer.play();
    audioPlayerSub.play();
  }

  void dispose() {
    audioPlayer.dispose();
    audioPlayerSub.dispose();
    _trackStreamController.close();
    _playListStreamController.close();
    _loopModeStreamController.close();
    _shuffleModeStreamController.close();
    _mashupModeStreamController.close();
    cancelMashupTimer();
    FilePicker.platform.clearTemporaryFiles();
  }

  void playListAddList(List<AudioTrack> newList) {
    _playList.addAll(newList);
    _playListBackup.addAll(newList);
  }

  void playListUpdated() {
    _playListStreamController.add(null);
    initPlayListUpdated();
  }

  void initPlayListUpdated() async {
    if (isAudioPlayerEmpty) {
      AudioSource source = audioSource(0);
      await audioPlayer.setAudioSource(source);
    }
  }

  AudioSource audioSource(int index) => androidMode
      ? AudioSource.file(_playList[index].path)
      : FileAudioSource(bytes: _playList[index].file!.bytes!.cast<int>());

  void nextEventWhenPlayerCompleted() async {
    if (_mashupMode) {
      await seekToNext();
    } else {
      if (_loopMode == LoopMode.one) {
        await replay();
      } else {
        if (_currentIndex == _playList.length - 1 &&
            _loopMode == LoopMode.off) {
          await pause();
        } else {
          await seekToNext();
        }
      }
    }
  }

  void setMashupVolumeTransition() {
    Stream<double> mashupVolumeTransition = Stream.periodic(
            const Duration(milliseconds: 500),
            (x) => x * 1.0 / (_mashupTransitionTime / 500))
        .take(_mashupTransitionTime ~/ 500);
    _mashupVolumeTransitionTimer = mashupVolumeTransition.listen((x) {
      audioPlayer.setVolume(x * _volumeMasterRate);
      audioPlayerSub.setVolume((1.0 - x) * _volumeMasterRate);
    }, onDone: () {
      audioPlayer.setVolume(_volumeMasterRate);
      audioPlayerSub.setVolume(0);
    });
  }

  void setMashupNextTrigger() {
    int nextDelay = ((_mashupNextTriggerMaxTime - _mashupNextTriggerMinTime) *
                Random().nextDouble() +
            _mashupNextTriggerMinTime)
        .toInt();
    _mashupNextTriggerTimer = Stream<void>.fromFuture(
            Future<void>.delayed(Duration(milliseconds: nextDelay), () {}))
        .listen((x) {
      seekToNext();
    });
  }

  Future<void> seekTrack(int index) async {
    if (_playList.isNotEmpty && index != _currentIndex) {
      index %= _playList.length;
      if (_mashupMode) {
        _currentIndexAudioPlayerList = (_currentIndexAudioPlayerList + 1) % 2;
        await cancelMashupTimer();
        setMashupVolumeTransition();
        setMashupNextTrigger();

        AudioSource source = audioSource(index);
        Duration? newDuration = await audioPlayer.setAudioSource(source);
        await seekPosition(Duration(
            milliseconds:
                (newDuration!.inMilliseconds * (Random().nextDouble() * 0.75))
                    .toInt()));
        _trackStreamController.add(newDuration);
      } else {
        AudioSource source = audioSource(index);
        Duration? newDuration = await audioPlayer.setAudioSource(source);
        _trackStreamController.add(newDuration!);
      }
      _currentIndex = index;
    }
  }

  Future<void> seekPosition(Duration duration) async {
    if (!isAudioPlayerEmpty) {
      await audioPlayer.seek(duration);
    }
  }

  Future<void> seekToPrevious() async {
    await seekTrack(_currentIndex - 1);
  }

  Future<void> seekToNext() async {
    await seekTrack(_currentIndex + 1);
  }

  Future<void> play() async {
    if (!isAudioPlayerEmpty && !_mashupMode) {
      await audioPlayer.play();
    }
  }

  Future<void> pause() async {
    if (!isAudioPlayerEmpty && !_mashupMode) {
      await audioPlayer.pause();
    }
  }

  Future<void> replay() async {
    await seekPosition(const Duration());
    await pause();
    await play();
  }

  AudioTrack playListAt(int index) =>
      _playList.isNotEmpty ? _playList[index] : AudioTrack.empty();

  void shuffleOn() {
    if (_playList.isNotEmpty) {
      AudioTrack currentTrack = _playList[_currentIndex];
      _playList.shuffle();
      for (int i = 0; i < _playList.length; i++) {
        if (currentTrack == _playList[i]) {
          AudioTrack tempTrack = _playList[0];
          _playList[0] = _playList[i];
          _playList[i] = tempTrack;
          break;
        }
      }
      _currentIndex = 0;
    }
  }

  void shuffleOff() {
    if (_playList.isNotEmpty) {
      AudioTrack currentTrack = _playList[_currentIndex];
      for (int i = 0; i < _playList.length; i++) {
        _playList[i] = _playListBackup[i];
        if (currentTrack == _playList[i]) {
          _currentIndex = i;
        }
      }
    }
  }

  void filesOpen() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
    );

    if (result != null) {
      List<AudioTrack> newList = [];
      for (PlatformFile track in result.files) {
        newList.add(AudioTrack(
            title: track.name.substring(0, track.name.length - 4),
            path: androidMode ? track.path! : '',
            file: androidMode ? null : track));
      }
      playListAddList(newList);
      playListUpdated();
    }
  }

  Future<List<String>> directoryOpen() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    List<String> list = [];
    if (selectedDirectory != null) {
      list.add(directoryScan(selectedDirectory));
      playListUpdated();
    }

    return list;
  }

  String directoryScan(String path) {
    if (!androidMode) {
      return '+';
    }
    String ss = '';
    List<FileSystemEntity> files = Directory(path).listSync();
    ss = files.length.toString();
    List<AudioTrack> newList = [];
    for (FileSystemEntity fileEntity in files) {
      if (FileSystemEntity.isDirectorySync(fileEntity.path)) {
        ss += directoryScan(fileEntity.path);
      } else {
        File file = File(fileEntity.path);
        List<String> pathSegments = file.uri.pathSegments;
        if (_allowedExtensions.contains(pathSegments.last)) {
          newList.add(AudioTrack(
            title: pathSegments[pathSegments.length - 2],
            path: file.path,
          ));
        }
        ss += pathSegments[pathSegments.length - 2];
      }
    }
    playListAddList(newList);
    return ss;
  }

  void togglePlayMode() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
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
    _loopModeStreamController.add(_loopMode);
  }

  void toggleShuffleMode() {
    if (_playList.isNotEmpty) {
      _shuffleMode = !_shuffleMode;
      if (_shuffleMode) {
        shuffleOn();
      } else {
        shuffleOff();
      }
      _shuffleModeStreamController.add(_shuffleMode);
    }
  }

  void toggleMashupMode() async {
    if (_playList.isNotEmpty) {
      _mashupMode = !_mashupMode;
      if (_mashupMode) {
        setMashupNextTrigger();
      } else {
        await cancelMashupTimer();
        audioPlayer.setVolume(_volumeMasterRate);
        audioPlayerSub.setVolume(0);
      }
      _mashupModeStreamController.add(_mashupMode);
    }
  }

  Future<void> cancelMashupTimer() async {
    if (_mashupVolumeTransitionTimer != null) {
      await _mashupVolumeTransitionTimer!.cancel();
    }
    if (_mashupNextTriggerTimer != null) {
      await _mashupNextTriggerTimer!.cancel();
    }
  }

  StreamBuilder<bool> playingStreamBuilder(builder) => StreamBuilder<bool>(
        stream: audioPlayer.playingStream,
        builder: (context, data) => StreamBuilder<bool>(
          stream: audioPlayerSub.playingStream,
          builder: builder,
        ),
      );

  StreamBuilder<Duration> positionStreamBuilder(builder) =>
      StreamBuilder<Duration>(
        stream: audioPlayer.positionStream,
        builder: builder,
      );

  StreamBuilder<void> trackStreamBuilder(builder) => StreamBuilder<void>(
        stream: _trackStreamController.stream,
        builder: builder,
      );

  StreamBuilder<void> playListStreamBuilder(builder) => StreamBuilder<void>(
        stream: _playListStreamController.stream,
        builder: builder,
      );

  StreamBuilder<LoopMode> loopModeStreamBuilder(builder) =>
      StreamBuilder<LoopMode>(
        stream: _loopModeStreamController.stream,
        builder: builder,
      );

  StreamBuilder<bool> shuffleModeStreamBuilder(builder) => StreamBuilder<bool>(
        stream: _shuffleModeStreamController.stream,
        builder: builder,
      );

  StreamBuilder<bool> mashupModeStreamBuilder(builder) => StreamBuilder<bool>(
        stream: _mashupModeStreamController.stream,
        builder: builder,
      );
}
