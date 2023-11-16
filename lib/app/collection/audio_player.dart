import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:math';
import 'dart:async';
import 'dart:io';

import './audio_track.dart';
import './audio_playlist.dart';

class AudioPlayerKit {
  final _androidMode = false; // true - android, false - web

  final _audioPlayerList = [
    AudioPlayer(
        handleInterruptions: false, handleAudioSessionActivation: false),
    AudioPlayer(
        handleInterruptions: false, handleAudioSessionActivation: false),
  ];
  final PlayList _playList = PlayList();
  LoopMode _loopMode = LoopMode.all;
  bool _shuffleMode = false;
  bool _mashupMode = false;
  int _currentIndexAudioPlayerList = 0;
  double _volumeMasterRate = 1.0;
  double _volumeTransitionRate = 1.0;
  final int _mashupTransitionTime = 5000;
  final int _mashupNextTriggerMinTime = 20000;
  final int _mashupNextTriggerMaxTime = 40000;
  final List<String> _allowedExtensions = ['mp3', 'wav', 'ogg'];
  late final PermissionStatus _permissionStatus;

  final _trackStreamController = StreamController<void>.broadcast();
  final _playListStreamController = StreamController<void>.broadcast();
  final _loopModeStreamController = StreamController<LoopMode>.broadcast();
  final _shuffleModeStreamController = StreamController<bool>.broadcast();
  final _mashupModeStreamController = StreamController<bool>.broadcast();
  StreamSubscription<double>? _mashupVolumeTransitionTimer;
  StreamSubscription<void>? _mashupNextTriggerTimer;

  AudioPlayer get audioPlayer => _audioPlayerList[_currentIndexAudioPlayerList];
  AudioPlayer get audioPlayerSub =>
      _audioPlayerList[(_currentIndexAudioPlayerList + 1) % 2];
  LoopMode get loopMode => _loopMode;
  bool get shuffleMode => _shuffleMode;
  bool get mashupMode => _mashupMode;
  double get volume => _volumeMasterRate;
  int get playListLength => _playList.playListLength;
  String get currentAudioTitle => _playList.currentAudioTitle;
  bool get isPlaying => audioPlayer.playing;
  Duration get duration => audioPlayer.duration ?? const Duration();
  Duration get position => audioPlayer.position;
  bool get isAudioPlayerEmpty => audioPlayer.audioSource == null;
  Stream<PlaybackEvent> get playbackEventStream =>
      audioPlayer.playbackEventStream;

  set masterVolume(double v) {
    _volumeMasterRate = v < 0 ? 0 : (v > 1.0 ? 1.0 : v);
    updateAudioPlayerVolume();
  }

  set transitionVolume(double v) {
    _volumeTransitionRate = v < 0 ? 0 : (v > 1.0 ? 1.0 : v);
    updateAudioPlayerVolume();
  }

  bool compareIndexWithCurrent(int index) => _playList.currentIndex == index;
  String audioTitle(int index) => _playList.audioTitle(index);

  void init() {
    audioPlayer.processingStateStream
        .where((state) => state == ProcessingState.completed)
        .listen((state) {
      nextEventWhenPlayerCompleted(0);
    });
    audioPlayerSub.processingStateStream
        .where((state) => state == ProcessingState.completed)
        .listen((state) {
      nextEventWhenPlayerCompleted(1);
    });
    _playList.init();

    audioPlayer.play();
    audioPlayerSub.play();
    setAudioPlayerVolumeDefault();

    activePermission();
  }

  void dispose() {
    _playList.dispose();
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

  void activePermission() async {
    _permissionStatus = await Permission.manageExternalStorage.request();
  }

  AudioSource audioSource(int index) =>
      _playList.audioSource(index, androidMode: _androidMode);

  void playListAddList(List<AudioTrack> newList) {
    _playList.addAll(newList);
    _playListStreamController.add(null);
    initPlayListUpdated();
  }

  void initPlayListUpdated() async {
    if (isAudioPlayerEmpty) {
      AudioSource source = audioSource(0);
      await audioPlayer.setAudioSource(source);
      _trackStreamController.add(null);
    }
  }

  void nextEventWhenPlayerCompleted(int audioPlayerCode) async {
    if (audioPlayerCode != _currentIndexAudioPlayerList) {
      return;
    }
    if (_mashupMode) {
      await seekToNext();
    } else {
      if (_loopMode == LoopMode.one) {
        replay();
      } else {
        if (_playList.currentIndex == playListLength - 1 &&
            _loopMode == LoopMode.off) {
          pause();
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
      transitionVolume = x;
    }, onDone: setAudioPlayerVolumeDefault);
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

  void setAudioPlayerVolumeDefault() {
    transitionVolume = 1.0;
  }

  Future<void> seekTrack(int index, {bool forceLoad = false}) async {
    if (_playList.isNotEmpty &&
        (index != _playList.currentIndex || forceLoad)) {
      index %= playListLength;
      if (_mashupMode) {
        play();
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
        _trackStreamController.add(null);
      } else {
        AudioSource source = audioSource(index);
        await audioPlayer.setAudioSource(source);
        _trackStreamController.add(null);
      }
      play();
      _playList.currentIndex = index;
    }
  }

  Future<void> seekPosition(Duration duration) async {
    if (!isAudioPlayerEmpty) {
      await audioPlayer.seek(duration);
    }
  }

  Future<void> seekToPrevious() async {
    await seekTrack(_playList.currentIndex - 1);
  }

  Future<void> seekToNext() async {
    await seekTrack(_playList.currentIndex + 1);
  }

  void play() {
    if (!isAudioPlayerEmpty && !isPlaying) {
      audioPlayer.play();
      audioPlayerSub.play();
      if (_mashupVolumeTransitionTimer != null) {
        _mashupVolumeTransitionTimer!.resume();
      }
      if (_mashupNextTriggerTimer != null) {
        _mashupNextTriggerTimer!.resume();
      }
    }
  }

  Future<void> pause() async {
    if (!isAudioPlayerEmpty && isPlaying) {
      await audioPlayer.pause();
      await audioPlayerSub.pause();
      if (_mashupVolumeTransitionTimer != null) {
        _mashupVolumeTransitionTimer!.pause();
      }
      if (_mashupNextTriggerTimer != null) {
        _mashupNextTriggerTimer!.pause();
      }
    }
  }

  Future<void> replay() async {
    await seekPosition(const Duration());
    await pause();
    play();
  }

  void updateAudioPlayerVolume() {
    audioPlayer.setVolume(_volumeTransitionRate * _volumeMasterRate);
    audioPlayerSub.setVolume((1.0 - _volumeTransitionRate) * _volumeMasterRate);
  }

  void filesOpen() async {
    if (_androidMode) {
      activePermission();
      if (_permissionStatus.isDenied) {
        return;
      }

      String? selectedDirectoryPath =
          await FilePicker.platform.getDirectoryPath();
      if (selectedDirectoryPath != null) {
        List<AudioTrack> newList = [];
        Directory selectedDirectory = Directory(selectedDirectoryPath);
        List<FileSystemEntity> selectedDirectoryFile =
            selectedDirectory.listSync(recursive: true);
        for (FileSystemEntity file in selectedDirectoryFile) {
          String path = file.path;
          if (!FileSystemEntity.isDirectorySync(path)) {
            if (_allowedExtensions.contains(path.split('.').last)) {
              String name = file.uri.pathSegments.last;
              newList.add(AudioTrack(
                title: name.substring(0, name.length - 4),
                path: file.path,
              ));
            }
          }
        }
        playListAddList(newList);
      }
    } else {
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
              path: _androidMode ? track.path! : '',
              file: _androidMode ? null : track));
        }
        playListAddList(newList);
      }
    }
  }

  void togglePlayMode() async {
    if (isPlaying) {
      await pause();
    } else {
      play();
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
        _playList.shuffleOn();
      } else {
        _playList.shuffleOff();
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
        setAudioPlayerVolumeDefault();
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

  void clearPlayList() {
    _playList.clear();
  }

  void shiftPlayListItem(int oldIndex, int newIndex) {
    _playList.shift(oldIndex, newIndex);
  }

  void removePlayListItem(int index) {
    bool needReload = index == _playList.currentIndex;
    _playList.remove(index);
    if (needReload) {
      seekTrack(index < playListLength ? index : index - 1, forceLoad: true);
    }
  }

  void exportPlayList() {
    _playList.createColumn();
  }

  void importPlayList() {
    _playList.loadColumn();
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
