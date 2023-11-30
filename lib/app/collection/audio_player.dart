import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_waveform/just_waveform.dart';

import 'dart:math';
import 'dart:async';
import 'dart:io';

import './audio_track.dart';
import './audio_playlist.dart';
import './preference.dart';

import '../log.dart' as glo;

class AudioPlayerKit {
  final _androidMode = true; // true - android, false - web

  late final List<AudioPlayer> _audioPlayerList = [
    AudioPlayer(
      handleInterruptions: false,
      handleAudioSessionActivation: false,
      audioPipeline: AudioPipeline(
        androidAudioEffects: [
          _equalizerList[0],
        ],
      ),
    ),
    AudioPlayer(
      handleInterruptions: false,
      handleAudioSessionActivation: false,
      audioPipeline: AudioPipeline(
        androidAudioEffects: [
          _equalizerList[1],
        ],
      ),
    ),
  ];
  final PlayList _playList = PlayList();
  final List<AndroidEqualizer> _equalizerList = [
    AndroidEqualizer(),
    AndroidEqualizer(),
  ];
  LoopMode _loopMode = LoopMode.all;
  bool _mashupMode = false;
  int _currentIndexAudioPlayerList = 0;
  double _volumeTransitionRate = 1.0;

  final List<String> _allowedExtensions = ['mp3', 'wav', 'ogg'];
  late final PermissionStatus _permissionStatus;

  final _trackStreamController = StreamController<void>.broadcast();
  final _playListStreamController = StreamController<void>.broadcast();
  final _loopModeStreamController = StreamController<void>.broadcast();
  final _playListOrderStateStreamController =
      StreamController<void>.broadcast();
  final _waveformStreamController =
      StreamController<WaveformProgress>.broadcast();
  StreamSubscription<double>? _mashupVolumeTransitionTimer;
  StreamSubscription<void>? _mashupNextTriggerTimer;

  AudioPlayer get audioPlayer => _audioPlayerList[_currentIndexAudioPlayerList];
  AudioPlayer get audioPlayerSub =>
      _audioPlayerList[(_currentIndexAudioPlayerList + 1) % 2];
  LoopMode get loopMode => _loopMode;
  bool get mashupMode => _mashupMode;
  AndroidEqualizer get equalizer => _equalizerList[0];
  AndroidEqualizer get equalizerSub => _equalizerList[1];
  int get playListLength => _playList.playListLength;
  String get currentAudioTitle => _playList.currentAudioTitle;
  bool get isPlaying => audioPlayer.playing;
  Duration get duration => audioPlayer.duration ?? const Duration();
  Duration get position => audioPlayer.position;
  PlayListOrderState get playListOrderState => _playList.playListOrderState;
  bool get isAudioPlayerEmpty => audioPlayer.audioSource == null;
  Stream<PlaybackEvent> get playbackEventStream =>
      audioPlayer.playbackEventStream;

  set masterVolume(double v) {
    Preference.volumeMasterRate = v < 0 ? 0 : (v > 1.0 ? 1.0 : v);
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
    setEnabledEqualizer();

    audioPlayer.play();
    audioPlayerSub.play();
    setAudioPlayerVolumeDefault();

    activePermission();
  }

  void dispose() {
    _playList.dispose();
    audioPlayer.dispose();
    audioPlayerSub.dispose();
  }

  void activePermission() async {
    _permissionStatus = await Permission.manageExternalStorage.request();
  }

  Future<void> visualizerInit(AudioTrack? audio) async {
    if (audio == null) {
      return;
    }
    try {
      JustWaveform.extract(
              audioInFile: File(audio.path),
              waveOutFile: File('${audio.title}.wave'))
          .listen(_waveformStreamController.add,
              onError: _waveformStreamController.addError);
      glo.debugLog = '${audio.title} LOAD!!';
      glo.debugLogStreamController.add(null);
    } catch (e) {
      _waveformStreamController.addError(e);
      glo.debugLog = e.toString();
      glo.debugLogStreamController.add(null);
    }
  }

  AudioSource audioSource(int index) =>
      _playList.audioSource(index, androidMode: _androidMode);

  void playListAddList(List<AudioTrack> newList) {
    _playList.addAll(newList);
    if (Preference.shuffleReload) {
      _playList.currentIndex = Random().nextInt(playListLength);
      _playList.shuffle();
      _playListOrderStateStreamController.add(null);
    }
    _playListStreamController.add(null);
    initPlayListUpdated();
  }

  void initPlayListUpdated() async {
    if (isAudioPlayerEmpty) {
      AudioSource source = audioSource(0);
      await audioPlayer.setAudioSource(source);
      _trackStreamController.add(null);
      if (!Preference.instantlyPlay) {
        pause();
      }
    }
  }

  void setEnabledEqualizer() {
    equalizer.setEnabled(Preference.enableEqualizer);
    equalizerSub.setEnabled(Preference.enableEqualizer);
  }

  Future<void> syncEqualizer() async {
    var parameters = await equalizer.parameters;
    var parametersSub = await equalizerSub.parameters;
    var bands = parameters.bands;
    var bandsSub = parametersSub.bands;
    for (int i = 0; i < bands.length; i++) {
      bandsSub[i].setGain(bands[i].gain);
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
            const Duration(milliseconds: 100),
            (x) => x * 1.0 / ((Preference.mashupTransitionTime * 1000) / 100))
        .take((Preference.mashupTransitionTime * 1000) ~/ 100);
    _mashupVolumeTransitionTimer = mashupVolumeTransition.listen((x) {
      transitionVolume = x;
    }, onDone: setAudioPlayerVolumeDefault);
  }

  void setMashupNextTrigger() {
    int nextDelay = ((Preference.mashupNextTriggerMaxTime -
                    Preference.mashupNextTriggerMinTime) *
                1000 *
                Random().nextDouble() +
            Preference.mashupNextTriggerMinTime * 1000)
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
      visualizerInit(_playList.currentAudioTrack);
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
    audioPlayer.setVolume(_volumeTransitionRate * Preference.volumeMasterRate);
    audioPlayerSub
        .setVolume((1.0 - _volumeTransitionRate) * Preference.volumeMasterRate);
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
              FileStat fileStat = FileStat.statSync(path);
              newList.add(AudioTrack(
                title: name.substring(0, name.length - 4),
                path: file.path,
                modifiedDateTime: fileStat.modified,
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
              path: '',
              modifiedDateTime: DateTime.now(),
              file: track));
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
    _loopModeStreamController.add(null);
  }

  void toggleShuffleMode() {
    _playList.toggleShuffleMode();
    _playListOrderStateStreamController.add(null);
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

  void shiftPlayListItem(int oldIndex, int newIndex) {
    _playList.shift(oldIndex, newIndex);
  }

  void removePlayListItem(int index) {
    bool needReload = (index == _playList.currentIndex);
    _playList.remove(index);
    if (needReload) {
      seekTrack(index < playListLength ? index : index - 1, forceLoad: true);
    }
  }

  void sortPlayList() {
    _playList.sortPlayList();
    _playListStreamController.add(null);
    _playListOrderStateStreamController.add(null);
  }

  void clearPlayList() {
    _playList.clear();
    _playListStreamController.add(null);
    _playListOrderStateStreamController.add(null);
  }

  void exportCustomPlayList(String listName, bool autoAddPlaylist) async {
    _playList.exportList(listName, autoAddPlaylist);
  }

  void importCustomPlayList(String listName) async {
    List<Map>? datas = await _playList.importList(listName);
    List<AudioTrack> newList = [];
    for (Map data in datas) {
      String path = data['path'];
      if (File(path).existsSync()) {
        FileStat fileStat = FileStat.statSync(path);
        newList.add(AudioTrack(
            title: data['title'],
            path: path,
            modifiedDateTime: fileStat.modified,
            file: null));
      }
    }
    playListAddList(newList);
  }

  void updateCustomPlayList(String listName) async {
    _playList.updateList(listName);
  }

  void deleteCustomPlayList(String listName) async {
    _playList.deleteList(listName);
  }

  Future<List<Map>?> selectAllDBTable({bool favoriteFilter = false}) async {
    var list = await _playList.selectAllDBTable(favoriteFilter: favoriteFilter);
    return List<Map>.from(list);
  }

  void toggleDBTableFavorite(String listName) async {
    _playList.toggleDBTableFavorite(listName);
  }

  Future<bool?> selectDBTableFavorite(String listName) async {
    return await _playList.selectDBTableFavorite(listName);
  }

  Future<bool?> checkDBTableExist(String listName) async {
    return await _playList.checkDBTableExist(listName);
  }

  void exportDBFile() async {
    activePermission();
    if (_permissionStatus.isDenied) {
      return;
    }
    _playList.exportDBFile();
  }

  void customTableDatabaseToCsv() async {
    _playList.customTableDatabaseToCsv();
  }

  void customTableCsvToDatabase() async {
    _playList.customTableCsvToDatabase();
  }

  void addItemInDBTable(
      {required String tableName, required String trackTitle}) async {
    _playList.addItemInDBTable(tableName: tableName, trackTitle: trackTitle);
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

  StreamBuilder<void> loopModeStreamBuilder(builder) => StreamBuilder<void>(
        stream: _loopModeStreamController.stream,
        builder: builder,
      );

  StreamBuilder<void> playListOrderStateStreamBuilder(builder) =>
      StreamBuilder<void>(
        stream: _playListOrderStateStreamController.stream,
        builder: builder,
      );

  StreamBuilder<WaveformProgress> waveformStreamBuilder(builder) =>
      StreamBuilder<WaveformProgress>(
        stream: _waveformStreamController.stream,
        builder: builder,
      );

  StreamBuilder<void> playListSheetStreamBuilder(builder) =>
      playListOrderStateStreamBuilder((context, value) => playListStreamBuilder(
          (context, value) => trackStreamBuilder(builder)));
}
