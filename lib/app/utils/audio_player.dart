import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:math';
import 'dart:async';
import 'dart:io';

import '../models/audio_track.dart';
import './playlist.dart';
import './database_manager.dart';
import './preference.dart';
import './stream_controller.dart';
import './permission_handler.dart';
import '../models/play_list_order.dart';

class AudioPlayerKit {
  AudioPlayerKit._();
  static final AudioPlayerKit _instance = AudioPlayerKit._();
  static AudioPlayerKit get instance => _instance;

  final _androidMode = true; // true - android, false - web

  late final _audioPlayerList = [
    createAudioPlayer(0),
    createAudioPlayer(1),
  ];
  final _equalizerList = [
    AndroidEqualizer(),
    AndroidEqualizer(),
  ];
  final _allowedExtensions = ['mp3', 'wav', 'ogg'];

  LoopMode _loopMode = LoopMode.all;
  bool _mashupMode = false;
  int _currentIndexAudioPlayerList = 0;
  double _volumeTransitionRate = 1.0;
  List<int> _currentByteData = [];
  StreamSubscription<double>? _mashupVolumeTransitionTimer;
  StreamSubscription<void>? _mashupNextTriggerTimer;

  AudioPlayer get audioPlayer => _audioPlayerList[_currentIndexAudioPlayerList];
  AudioPlayer get audioPlayerSub =>
      _audioPlayerList[(_currentIndexAudioPlayerList + 1) % 2];
  LoopMode get loopMode => _loopMode;
  bool get mashupMode => _mashupMode;
  AndroidEqualizer get equalizer => _equalizerList[0];
  AndroidEqualizer get equalizerSub => _equalizerList[1];
  int get playListLength => PlayList.instance.playListLength;
  String get currentAudioTitle => PlayList.instance.currentAudioTitle;
  int? get currentAudioColor => PlayList.instance.currentAudioColor;
  bool get isPlaying => audioPlayer.playing;
  Duration get duration =>
      audioPlayer.duration ?? const Duration(milliseconds: 1);
  Duration get position => audioPlayer.position;
  PlayListOrderState get playListOrderState =>
      PlayList.instance.playListOrderState;
  bool get isAudioPlayerEmpty => audioPlayer.audioSource == null;
  Stream<PlaybackEvent> get playbackEventStream =>
      audioPlayer.playbackEventStream;
  List<int> get currentByteData => _currentByteData;

  set masterVolume(double v) {
    Preference.volumeMasterRate = v < 0 ? 0 : (v > 1.0 ? 1.0 : v);
    updateAudioPlayerVolume();
  }

  set transitionVolume(double v) {
    _volumeTransitionRate = v < 0 ? 0 : (v > 1.0 ? 1.0 : v);
    updateAudioPlayerVolume();
  }

  bool compareIndexWithCurrent(int index) =>
      PlayList.instance.currentIndex == index;
  String audioTitle(int index) => PlayList.instance.audioTitle(index);
  AudioTrack? audioTrack(int index) => PlayList.instance.audioTrack(index);
  AudioPlayer createAudioPlayer(int index) => AudioPlayer(
        handleInterruptions: false,
        handleAudioSessionActivation: false,
        audioPipeline: AudioPipeline(
          androidAudioEffects: [
            _equalizerList[index],
          ],
        ),
      );

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
    setEnabledEqualizer();

    audioPlayer.play();
    audioPlayerSub.play();
    setAudioPlayerVolumeDefault();
  }

  void dispose() {
    audioPlayer.dispose();
    audioPlayerSub.dispose();
  }

  AudioSource audioSource(int index) =>
      PlayList.instance.audioSource(index, androidMode: _androidMode);

  void playListAddList(List<AudioTrack> newList) {
    PlayList.instance.addAll(newList);
    if (Preference.shuffleReload) {
      PlayList.instance.currentIndex = Random().nextInt(playListLength);
      PlayList.instance.shuffle();
      AudioStreamController.playListOrderState.add(null);
    }
    AudioStreamController.playList.add(null);
    initPlayListUpdated();
  }

  void initPlayListUpdated() async {
    if (isAudioPlayerEmpty) {
      AudioSource source = audioSource(0);
      await audioPlayer.setAudioSource(source);
      setCurrentByteData();

      AudioStreamController.track.add(null);
      AudioStreamController.visualizerColor.add(null);
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
        if (PlayList.instance.currentIndex == playListLength - 1 &&
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
    if (PlayList.instance.isNotEmpty &&
        (index != PlayList.instance.currentIndex || forceLoad)) {
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
      } else {
        await audioPlayer.setAudioSource(audioSource(index));
      }
      AudioStreamController.track.add(null);
      AudioStreamController.visualizerColor.add(null);

      play();
      PlayList.instance.currentIndex = index;
      setCurrentByteData();
    }
  }

  Future<void> seekPosition(Duration duration) async {
    if (!isAudioPlayerEmpty) {
      await audioPlayer.seek(duration);
    }
  }

  Future<void> seekToPrevious() async {
    await seekTrack(PlayList.instance.currentIndex - 1);
  }

  Future<void> seekToNext() async {
    await seekTrack(PlayList.instance.currentIndex + 1);
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
      if (!PermissionHandler.instance.isPermissionAccepted) {
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
                path: path,
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

  List<int> _readBytesFromFile(String filePath) {
    File file = File(filePath);
    if (file.existsSync()) {
      RandomAccessFile accessFile = file.openSync();
      int length = file.lengthSync();
      List<int> bytes = accessFile.readSync(length);
      accessFile.closeSync();
      return bytes;
    }
    return [];
  }

  void setCurrentByteData() {
    if (!_androidMode) {
      _currentByteData = PlayList.instance.currentbyteData;
      return;
    }
    _currentByteData = _readBytesFromFile(PlayList.instance.currentAudioPath);
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
    AudioStreamController.loopMode.add(null);
  }

  void toggleShuffleMode() {
    PlayList.instance.toggleShuffleMode();
    AudioStreamController.playListOrderState.add(null);
  }

  void toggleMashupMode() async {
    if (PlayList.instance.isNotEmpty) {
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

  void removePlayListItem(int index) {
    bool needReload = (index == PlayList.instance.currentIndex);
    PlayList.instance.remove(index);
    if (needReload) {
      seekTrack(index < playListLength ? index : index - 1, forceLoad: true);
    }
  }

  void importTagList(String listName) async {
    List<Map>? datas = await DatabaseManager.instance.importList(listName);
    List<AudioTrack> newList = [];
    for (Map data in datas) {
      String path = data['path'];
      if (File(path).existsSync()) {
        FileStat fileStat = FileStat.statSync(path);
        newList.add(AudioTrack(
          title: data['title'],
          path: path,
          modifiedDateTime: fileStat.modified,
          color: data['color'],
        ));
      }
    }
    playListAddList(newList);
  }
}
