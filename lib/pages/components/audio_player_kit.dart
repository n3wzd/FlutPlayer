import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:math';
import 'dart:async';
import 'dart:io';

import './audio_track.dart';
import './file_audio_source.dart';

class AudioPlayerKit {
  final _audioPlayer = AudioPlayer();
  final _audioPlayerSub = AudioPlayer();
  final List<AudioTrack> _playList = [];
  final List<AudioTrack> _playListBackup = [];
  int _currentIndex = 0;
  LoopMode _loopMode = LoopMode.one;
  bool _shuffleMode = false;
  bool _mashupMode = false;
  final double _volumeMasterRate = 1.0;
  final int _mashupTransitionTime = 10000;
  final int _mashupNextTriggerMinTime = 20000;
  final int _mashupNextTriggerMaxTime = 40000;
  final List<String> _allowedExtensions = ['mp3', 'wav', 'ogg'];

  final StreamController<Duration> _trackStreamController =
      StreamController<Duration>.broadcast();
  final StreamController<int> _playListStreamController =
      StreamController<int>.broadcast();
  final StreamController<LoopMode> _loopModeStreamController =
      StreamController<LoopMode>.broadcast();
  final StreamController<bool> _shuffleModeStreamController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _mashupModeStreamController =
      StreamController<bool>.broadcast();
  StreamSubscription<double>? _mashupVolumeTransitionStreamSubscription;
  Timer? _mashupNextTriggerTimer;

  bool androidMode = false; // true - android, false - web

  int get currentIndex => _currentIndex;
  LoopMode get loopMode => _loopMode;
  bool get shuffleMode => _shuffleMode;
  bool get mashupMode => _mashupMode;
  int get playListLength => _playList.length;
  String get currentAudioTitle =>
      _playList.isNotEmpty ? _playList[_currentIndex].title : '';
  bool get isPlaying => _audioPlayer.playing;
  Duration get duration => _audioPlayer.duration ?? const Duration();
  bool get isAudioPlayerEmpty => _audioPlayer.audioSource == null;

  void init() async {
    _audioPlayer.processingStateStream
        .where((state) => state == ProcessingState.completed)
        .listen((state) {
      nextEventWhenPlayerCompleted();
    });
  }

  void dispose() {
    _audioPlayer.dispose();
    _audioPlayerSub.dispose();
    _trackStreamController.close();
    _playListStreamController.close();
    _loopModeStreamController.close();
    _shuffleModeStreamController.close();
    _mashupModeStreamController.close();
    if (_mashupVolumeTransitionStreamSubscription != null) {
      _mashupVolumeTransitionStreamSubscription!.cancel();
    }
    if (_mashupNextTriggerTimer != null) {
      _mashupNextTriggerTimer!.cancel();
    }
    FilePicker.platform.clearTemporaryFiles();
  }

  void playListAddList(List<AudioTrack> newList) {
    _playList.addAll(newList);
    _playListBackup.addAll(newList);
    FilePicker.platform.clearTemporaryFiles();
  }

  void playListUpdated() {
    _playListStreamController.add(currentIndex);
    initPlayListUpdated();
  }

  void initPlayListUpdated() async {
    if (isAudioPlayerEmpty) {
      Duration? d = await _audioPlayer.setAudioSource(audioSource(0));
      _trackStreamController.add(d!);
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
          await _audioPlayer.stop();
        } else {
          await seekToNext();
        }
      }
    }
  }

  void setMashupVolumeTransition() async {
    if (_mashupVolumeTransitionStreamSubscription != null) {
      _mashupVolumeTransitionStreamSubscription!.cancel();
    }
    Stream<double> mashupVolumeTransition = Stream.periodic(
            const Duration(milliseconds: 500),
            (x) => x * 1.0 / (_mashupTransitionTime / 500))
        .take(_mashupTransitionTime ~/ 500);
    _mashupVolumeTransitionStreamSubscription =
        mashupVolumeTransition.listen((x) async {
      if (_mashupMode) {
        await _audioPlayer.setVolume(x * _volumeMasterRate);
        await _audioPlayerSub.setVolume((1.0 - x) * _volumeMasterRate);
      }
    }, onDone: () {
      _audioPlayer.setVolume(_volumeMasterRate);
      _audioPlayerSub.pause();
    });
  }

  void setMashupNextTrigger() {
    if (_mashupNextTriggerTimer != null) {
      _mashupNextTriggerTimer!.cancel();
    }
    _mashupNextTriggerTimer = Timer(
        Duration(
            milliseconds:
                ((_mashupNextTriggerMaxTime - _mashupNextTriggerMinTime) *
                            Random().nextDouble() +
                        _mashupNextTriggerMinTime)
                    .toInt()), () {
      if (_mashupMode) {
        seekToNext();
      }
    });
  }

  Future<void> seekTrack(int index, {bool autoPlay = true}) async {
    if (_playList.isNotEmpty && index != _currentIndex) {
      index %= _playList.length;
      if (_mashupMode) {
        _audioPlayer.setVolume(0);
        _audioPlayerSub.setVolume(_volumeMasterRate);

        await _audioPlayerSub.setAudioSource(audioSource(_currentIndex),
            initialPosition: _audioPlayer.position);
        Duration? newDuration =
            await _audioPlayer.setAudioSource(audioSource(index));
        await seekPosition(Duration(
            milliseconds:
                (newDuration!.inMilliseconds * (Random().nextDouble() * 0.8))
                    .toInt()));

        setMashupVolumeTransition();
        setMashupNextTrigger();
        _trackStreamController.add(newDuration);
      } else {
        Duration? newDuration =
            await _audioPlayer.setAudioSource(audioSource(index));
        _trackStreamController.add(newDuration!);
      }
      _currentIndex = index;
      if (autoPlay) {
        await play();
      }
    }
  }

  Future<void> seekPosition(Duration duration) async {
    if (!isAudioPlayerEmpty) {
      await _audioPlayer.seek(duration);
    }
  }

  Future<void> seekToPrevious() async {
    await seekTrack(_currentIndex - 1);
  }

  Future<void> seekToNext() async {
    await seekTrack(_currentIndex + 1);
  }

  Future<void> play() async {
    if (!isAudioPlayerEmpty) {
      await _audioPlayer.play();
      if (_mashupMode) {
        await _audioPlayerSub.play();
      }
    }
  }

  Future<void> pause() async {
    if (!isAudioPlayerEmpty) {
      await _audioPlayer.pause();
      if (_mashupMode) {
        await _audioPlayerSub.pause();
      }
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

  void directoryOpen() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      directoryScan(selectedDirectory);
      playListUpdated();
    }
  }

  void directoryScan(String path) {
    if (!androidMode) {
      return;
    }
    List<FileSystemEntity> files = Directory(path).listSync();
    List<AudioTrack> newList = [];
    for (FileSystemEntity fileEntity in files) {
      if (FileSystemEntity.isDirectorySync(fileEntity.path)) {
        directoryScan(fileEntity.path);
      } else {
        File file = File(fileEntity.path);
        List<String> pathSegments = file.uri.pathSegments;
        if (_allowedExtensions.contains(pathSegments.last)) {
          newList.add(AudioTrack(
            title: pathSegments[pathSegments.length - 2],
            path: file.path,
          ));
        }
      }
    }
    playListAddList(newList);
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
        if (_mashupVolumeTransitionStreamSubscription != null) {
          await _mashupVolumeTransitionStreamSubscription!.cancel();
        }
        if (_mashupNextTriggerTimer != null) {
          _mashupNextTriggerTimer!.cancel();
        }
        _audioPlayer.setVolume(_volumeMasterRate);
        _audioPlayerSub.pause();
      }
      _mashupModeStreamController.add(_mashupMode);
    }
  }

  StreamBuilder<bool> playingStreamBuilder(builder) {
    return StreamBuilder<bool>(
      stream: _audioPlayer.playingStream,
      builder: builder,
    );
  }

  StreamBuilder<Duration> positionStreamBuilder(builder) {
    return StreamBuilder<Duration>(
      stream: _audioPlayer.positionStream,
      builder: builder,
    );
  }

  StreamBuilder<Duration> trackStreamBuilder(builder) {
    return StreamBuilder<Duration>(
      stream: _trackStreamController.stream,
      builder: builder,
    );
  }

  StreamBuilder<int> playListStreamBuilder(builder) {
    return StreamBuilder<int>(
      stream: _playListStreamController.stream,
      builder: builder,
    );
  }

  StreamBuilder<LoopMode> loopModeStreamBuilder(builder) {
    return StreamBuilder<LoopMode>(
      stream: _loopModeStreamController.stream,
      builder: builder,
    );
  }

  StreamBuilder<bool> shuffleModeStreamBuilder(builder) {
    return StreamBuilder<bool>(
      stream: _shuffleModeStreamController.stream,
      builder: builder,
    );
  }

  StreamBuilder<bool> mashupModeStreamBuilder(builder) {
    return StreamBuilder<bool>(
      stream: _mashupModeStreamController.stream,
      builder: builder,
    );
  }
}
